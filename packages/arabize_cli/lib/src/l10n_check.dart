import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'extract.dart';
import 'l10n_config.dart';

/// A problem found by `arabize l10n-check`.
class L10nIssue {
  /// One of `missing`, `extra`, `unused` or `placeholders`.
  final String kind;

  /// The ARB file the issue is in.
  final String file;
  final String key;
  final String message;

  const L10nIssue(this.kind, this.file, this.key, this.message);

  Map<String, String> toJson() => {
    'kind': kind,
    'file': file,
    'key': key,
    'message': message,
  };
}

/// Returns the argument names used in the ICU [message], including the ones
/// inside plural and select cases.
Set<String> icuPlaceholders(String message) {
  final names = <String>{};
  _Parser(message, names).parseMessage(topLevel: true);
  return names;
}

class _Parser {
  final String s;
  final Set<String> names;
  var i = 0;

  _Parser(this.s, this.names);

  /// Parses text up to the closing brace of the current case, or the end.
  void parseMessage({bool topLevel = false}) {
    while (i < s.length) {
      final c = s[i];
      if (c == '}') {
        if (topLevel) {
          i++;
          continue;
        }
        return;
      }
      if (c == "'") {
        _skipQuote();
      } else if (c == '{') {
        i++;
        _parseArgument();
      } else {
        i++;
      }
    }
  }

  void _skipQuote() {
    final next = i + 1 < s.length ? s[i + 1] : '';
    if (next == "'") {
      i += 2;
    } else if (next == '{' || next == '}') {
      final end = s.indexOf("'", i + 1);
      i = end == -1 ? s.length : end + 1;
    } else {
      i++;
    }
  }

  void _parseArgument() {
    final start = i;
    while (i < s.length && s[i] != ',' && s[i] != '}') {
      i++;
    }
    final name = s.substring(start, i).trim();
    if (name.isNotEmpty) names.add(name);
    if (i >= s.length) return;
    if (s[i] == '}') {
      i++;
      return;
    }
    i++;
    final typeStart = i;
    while (i < s.length && s[i] != ',' && s[i] != '}') {
      i++;
    }
    final type = s.substring(typeStart, i).trim();
    if (i < s.length && s[i] == ',') i++;
    if (type == 'plural' || type == 'select' || type == 'selectordinal') {
      _parseCases();
    } else {
      _skipBraces();
    }
  }

  void _parseCases() {
    while (i < s.length && s[i] != '}') {
      if (s[i] == '{') {
        i++;
        parseMessage();
        if (i < s.length && s[i] == '}') i++;
      } else {
        i++;
      }
    }
    if (i < s.length) i++;
  }

  void _skipBraces() {
    var depth = 1;
    while (i < s.length && depth > 0) {
      if (s[i] == '{') depth++;
      if (s[i] == '}') depth--;
      i++;
    }
  }
}

/// Compares the ARB files and the code of a project.
///
/// [arbs] maps a file name to its content, [template] names the template
/// file and [sources] holds the Dart sources that use the getters.
List<L10nIssue> checkL10n({
  required Map<String, String> arbs,
  required String template,
  required Iterable<String> sources,
}) {
  final issues = <L10nIssue>[];
  final messages = <String, Map<String, String>>{
    for (final e in arbs.entries) e.key: _messages(e.value),
  };
  final base = messages[template] ?? const <String, String>{};

  final used = <String>{};
  final member = RegExp(r'[.]\s*(\w+)');
  for (final source in sources) {
    used.addAll(member.allMatches(source).map((m) => m.group(1)!));
  }
  for (final key in base.keys) {
    if (!used.contains(key)) {
      issues.add(L10nIssue('unused', template, key, 'not used in code'));
    }
  }

  for (final e in messages.entries) {
    if (e.key == template) continue;
    for (final key in base.keys) {
      final message = e.value[key];
      if (message == null) {
        issues.add(L10nIssue('missing', e.key, key, 'missing translation'));
        continue;
      }
      final expected = icuPlaceholders(base[key]!);
      final actual = icuPlaceholders(message);
      if (expected.length != actual.length || !expected.containsAll(actual)) {
        issues.add(
          L10nIssue(
            'placeholders',
            e.key,
            key,
            'expected {${_sorted(expected)}}, found {${_sorted(actual)}}',
          ),
        );
      }
    }
    for (final key in e.value.keys) {
      if (!base.containsKey(key)) {
        issues.add(L10nIssue('extra', e.key, key, 'not in $template'));
      }
    }
  }
  return issues;
}

String _sorted(Set<String> s) => (s.toList()..sort()).join(', ');

Map<String, String> _messages(String content) {
  final json = jsonDecode(content) as Map;
  return {
    for (final e in json.entries)
      if (!(e.key as String).startsWith('@') && e.value is String)
        e.key as String: e.value as String,
  };
}

/// Implements `arabize l10n-check [path] [--format text|json]`.
///
/// Reports keys missing from or unknown to the other ARB files, template keys
/// that the code never uses, and messages whose placeholders differ from the
/// template. Returns 1 when there are issues and 64 on bad arguments.
Future<int> runL10nCheck(List<String> args, void Function(String) out) async {
  var path = '.';
  var format = 'text';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--format' && i + 1 < args.length) {
      format = args[++i];
    } else if (arg.startsWith('--format=')) {
      format = arg.substring('--format='.length);
    } else if (!arg.startsWith('-')) {
      path = arg;
    } else {
      out('Unknown option: $arg');
      return 64;
    }
  }
  if (format != 'text' && format != 'json') {
    out('Unknown format: $format (use text or json)');
    return 64;
  }

  final config = L10nConfig.read(path);
  final dir = Directory(p.join(path, config.arbDir));
  if (!File(p.join(dir.path, config.template)).existsSync()) {
    out('Template ${p.join(dir.path, config.template)} not found.');
    return 64;
  }
  final arbs = {
    for (final f in dir.listSync().whereType<File>())
      if (f.path.endsWith('.arb')) p.basename(f.path): f.readAsStringSync(),
  };
  final lib = p.join(path, 'lib');
  final output = p.basenameWithoutExtension(config.outputFile);
  final sources = [
    for (final f in dartFiles(Directory(lib).existsSync() ? lib : path))
      if (!p.basename(f.path).startsWith(output)) f.readAsStringSync(),
  ];

  final issues = checkL10n(
    arbs: arbs,
    template: config.template,
    sources: sources,
  );
  if (format == 'json') {
    out(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'issues': issues.map((i) => i.toJson()).toList()}),
    );
  } else {
    for (final i in issues) {
      out('${i.file}  ${i.kind}  ${i.key}  ${i.message}');
    }
    out(
      issues.isEmpty
          ? 'No l10n issues found.'
          : '${issues.length} issue${issues.length == 1 ? '' : 's'} found.',
    );
  }
  return issues.isEmpty ? 0 : 1;
}
