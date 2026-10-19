import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'l10n_config.dart';

/// Sends an HTTP POST and returns the response body.
typedef HttpPost =
    Future<String> Function(Uri url, Map<String, String> headers, String body);

/// A service that can translate ARB messages.
abstract class TranslationProvider {
  /// The name used with `--provider`.
  String get name;

  /// Translates the values of [messages] to the language [target] and returns
  /// the translated map with the same keys.
  Future<Map<String, String>> translate(
    Map<String, String> messages,
    String target,
  );
}

String _prompt(String target) =>
    'Translate the values of the JSON object the user sends from English to '
    'the language with code "$target". Keep the keys. Keep ICU placeholders '
    'such as {name} and plural or select syntax unchanged. Answer with the '
    'JSON object only.';

Map<String, String> _parseReply(String text) {
  var s = text.trim();
  if (s.startsWith('```')) {
    s = s
        .replaceFirst(RegExp(r'^```\w*\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
  }
  final json = jsonDecode(s) as Map;
  return {for (final e in json.entries) e.key as String: e.value as String};
}

Future<String> _defaultPost(
  Uri url,
  Map<String, String> headers,
  String body,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(url);
    headers.forEach(request.headers.set);
    request.add(utf8.encode(body));
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      throw HttpException('${response.statusCode}: $text', uri: url);
    }
    return text;
  } finally {
    client.close();
  }
}

/// Translates with the Anthropic Messages API.
class AnthropicProvider implements TranslationProvider {
  final String apiKey;
  final String model;
  final HttpPost _post;

  AnthropicProvider(
    this.apiKey, {
    this.model = 'claude-sonnet-5-5',
    HttpPost? post,
  }) : _post = post ?? _defaultPost;

  @override
  String get name => 'anthropic';

  @override
  Future<Map<String, String>> translate(
    Map<String, String> messages,
    String target,
  ) async {
    final reply = await _post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      jsonEncode({
        'model': model,
        'max_tokens': 8192,
        'system': _prompt(target),
        'messages': [
          {'role': 'user', 'content': jsonEncode(messages)},
        ],
      }),
    );
    final content = (jsonDecode(reply) as Map)['content'] as List;
    return _parseReply((content.first as Map)['text'] as String);
  }
}

/// Translates with the OpenAI Chat Completions API.
class OpenAiProvider implements TranslationProvider {
  final String apiKey;
  final String model;
  final HttpPost _post;

  OpenAiProvider(this.apiKey, {this.model = 'gpt-4.1-mini', HttpPost? post})
    : _post = post ?? _defaultPost;

  @override
  String get name => 'openai';

  @override
  Future<Map<String, String>> translate(
    Map<String, String> messages,
    String target,
  ) async {
    final reply = await _post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      {'authorization': 'Bearer $apiKey', 'content-type': 'application/json'},
      jsonEncode({
        'model': model,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _prompt(target)},
          {'role': 'user', 'content': jsonEncode(messages)},
        ],
      }),
    );
    final choices = (jsonDecode(reply) as Map)['choices'] as List;
    final message = (choices.first as Map)['message'] as Map;
    return _parseReply(message['content'] as String);
  }
}

/// Translates with the Gemini generateContent API.
class GeminiProvider implements TranslationProvider {
  final String apiKey;
  final String model;
  final HttpPost _post;

  GeminiProvider(this.apiKey, {this.model = 'gemini-2.0-flash', HttpPost? post})
    : _post = post ?? _defaultPost;

  @override
  String get name => 'gemini';

  @override
  Future<Map<String, String>> translate(
    Map<String, String> messages,
    String target,
  ) async {
    final reply = await _post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent',
      ),
      {'x-goog-api-key': apiKey, 'content-type': 'application/json'},
      jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _prompt(target)},
          ],
        },
        'contents': [
          {
            'parts': [
              {'text': jsonEncode(messages)},
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );
    final candidates = (jsonDecode(reply) as Map)['candidates'] as List;
    final parts =
        ((candidates.first as Map)['content'] as Map)['parts'] as List;
    return _parseReply((parts.first as Map)['text'] as String);
  }
}

/// Environment variable that holds the API key of each provider.
const providerKeys = {
  'anthropic': 'ANTHROPIC_API_KEY',
  'openai': 'OPENAI_API_KEY',
  'gemini': 'GEMINI_API_KEY',
};

/// Creates the provider called [name], or null if the name is unknown.
TranslationProvider? createProvider(
  String name,
  String apiKey, {
  String? model,
  HttpPost? post,
}) => switch (name) {
  'anthropic' =>
    model == null
        ? AnthropicProvider(apiKey, post: post)
        : AnthropicProvider(apiKey, model: model, post: post),
  'openai' =>
    model == null
        ? OpenAiProvider(apiKey, post: post)
        : OpenAiProvider(apiKey, model: model, post: post),
  'gemini' =>
    model == null
        ? GeminiProvider(apiKey, post: post)
        : GeminiProvider(apiKey, model: model, post: post),
  _ => null,
};

/// Returns the content of [existing] with the translated [added] messages.
///
/// A missing [existing] file starts a new one with `@@locale` set.
String mergeTranslations(
  String? existing,
  Map<String, String> added,
  String locale,
) {
  final json = existing == null
      ? <String, Object?>{'@@locale': locale}
      : Map<String, Object?>.from(jsonDecode(existing) as Map);
  json.addAll(added);
  return '${const JsonEncoder.withIndent('  ').convert(json)}\n';
}

/// Implements `arabize translate --to locale [path] [--provider name]
/// [--model id]`.
///
/// Translates the template messages that the target ARB file does not have
/// yet and adds them to it. The API key comes from `ANTHROPIC_API_KEY`,
/// `OPENAI_API_KEY` or `GEMINI_API_KEY`. Returns 64 on bad arguments or a
/// missing key and 1 when the provider fails.
Future<int> runTranslate(
  List<String> args,
  void Function(String) out, {
  Map<String, String>? environment,
  HttpPost? post,
}) async {
  final env = environment ?? Platform.environment;
  var path = '.';
  String? to;
  String? model;
  String? providerName;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--to' && i + 1 < args.length) {
      to = args[++i];
    } else if (arg == '--provider' && i + 1 < args.length) {
      providerName = args[++i];
    } else if (arg == '--model' && i + 1 < args.length) {
      model = args[++i];
    } else if (!arg.startsWith('-')) {
      path = arg;
    } else {
      out('Unknown option: $arg');
      return 64;
    }
  }
  if (to == null) {
    out('Missing --to <locale>, for example --to ar.');
    return 64;
  }
  providerName ??= providerKeys.keys.firstWhere(
    (n) => (env[providerKeys[n]] ?? '').isNotEmpty,
    orElse: () => 'anthropic',
  );
  final keyName = providerKeys[providerName];
  if (keyName == null) {
    out(
      'Unknown provider: $providerName (use ${providerKeys.keys.join(', ')})',
    );
    return 64;
  }
  final apiKey = env[keyName] ?? '';
  if (apiKey.isEmpty) {
    out('Set $keyName to use the $providerName provider.');
    return 64;
  }
  final provider = createProvider(
    providerName,
    apiKey,
    model: model,
    post: post,
  )!;

  final config = L10nConfig.read(path);
  final dir = p.join(path, config.arbDir);
  final templateFile = File(p.join(dir, config.template));
  if (!templateFile.existsSync()) {
    out('Template ${templateFile.path} not found.');
    return 64;
  }
  final targetFile = File(
    p.join(
      dir,
      config.template.replaceFirst(RegExp(r'_[^_.]+\.arb$'), '_$to.arb'),
    ),
  );
  final existing = targetFile.existsSync()
      ? targetFile.readAsStringSync()
      : null;
  final have = existing == null
      ? const <String>{}
      : (jsonDecode(existing) as Map).keys.cast<String>().toSet();

  final template = jsonDecode(templateFile.readAsStringSync()) as Map;
  final todo = {
    for (final e in template.entries)
      if (!(e.key as String).startsWith('@') &&
          e.value is String &&
          !have.contains(e.key))
        e.key as String: e.value as String,
  };
  if (todo.isEmpty) {
    out('Nothing to translate for $to.');
    return 0;
  }

  final Map<String, String> translated;
  try {
    translated = await provider.translate(todo, to);
  } on Object catch (e) {
    out('Translation failed: $e');
    return 1;
  }
  final added = {
    for (final k in todo.keys)
      if (translated[k] != null) k: translated[k]!,
  };
  targetFile.writeAsStringSync(mergeTranslations(existing, added, to));
  out(
    'Translated ${added.length} of ${todo.length} messages to ${targetFile.path}.',
  );
  return added.length == todo.length ? 0 : 1;
}
