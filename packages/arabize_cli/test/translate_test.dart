import 'dart:convert';
import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('providers', () {
    final messages = {'hello': 'Hello {name}'};
    final translated = jsonEncode({'hello': 'مرحبا {name}'});

    test('anthropic', () async {
      late Uri url;
      late Map<String, String> sent;
      final provider = AnthropicProvider(
        'k',
        post: (u, h, b) async {
          url = u;
          sent = h;
          return jsonEncode({
            'content': [
              {'type': 'text', 'text': translated},
            ],
          });
        },
      );
      expect(await provider.translate(messages, 'ar'), {
        'hello': 'مرحبا {name}',
      });
      expect(url.host, 'api.anthropic.com');
      expect(sent['x-api-key'], 'k');
    });

    test('openai', () async {
      late Map<String, String> sent;
      final provider = OpenAiProvider(
        'k',
        post: (u, h, b) async {
          sent = h;
          return jsonEncode({
            'choices': [
              {
                'message': {'content': translated},
              },
            ],
          });
        },
      );
      expect(await provider.translate(messages, 'ar'), {
        'hello': 'مرحبا {name}',
      });
      expect(sent['authorization'], 'Bearer k');
    });

    test('gemini', () async {
      late Uri url;
      final provider = GeminiProvider(
        'k',
        post: (u, h, b) async {
          url = u;
          return jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '```json\n$translated\n```'},
                  ],
                },
              },
            ],
          });
        },
      );
      expect(await provider.translate(messages, 'ar'), {
        'hello': 'مرحبا {name}',
      });
      expect(url.path, contains('generateContent'));
    });
  });

  group('mergeTranslations', () {
    test('starts a new file with the locale', () {
      final json = jsonDecode(mergeTranslations(null, {'a': 'ب'}, 'ar')) as Map;
      expect(json, {'@@locale': 'ar', 'a': 'ب'});
    });

    test('keeps existing entries', () {
      final json =
          jsonDecode(mergeTranslations('{"a": "x"}', {'b': 'y'}, 'ar')) as Map;
      expect(json, {'a': 'x', 'b': 'y'});
    });
  });

  group('runTranslate', () {
    late Directory dir;
    final lines = <String>[];

    setUp(() {
      lines.clear();
      dir = Directory.systemTemp.createTempSync('arabize_translate');
      Directory(p.join(dir.path, 'lib', 'l10n')).createSync(recursive: true);
      File(p.join(dir.path, 'lib', 'l10n', 'app_en.arb')).writeAsStringSync(
        jsonEncode({
          '@@locale': 'en',
          'save': 'Save',
          'cancel': 'Cancel',
          '@cancel': {'description': 'Button'},
        }),
      );
    });

    tearDown(() => dir.deleteSync(recursive: true));

    String reply(Map<String, String> m) => jsonEncode({
      'choices': [
        {
          'message': {'content': jsonEncode(m)},
        },
      ],
    });

    test('translates only the missing keys', () async {
      final target = File(p.join(dir.path, 'lib', 'l10n', 'app_ar.arb'))
        ..writeAsStringSync('{"@@locale": "ar", "save": "حفظ"}');
      late String body;
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
        post: (u, h, b) async {
          body = b;
          return reply({'cancel': 'إلغاء'});
        },
      );
      expect(code, 0);
      expect(body, contains('Cancel'));
      expect(body, isNot(contains('Save')));
      expect(jsonDecode(target.readAsStringSync()), {
        '@@locale': 'ar',
        'save': 'حفظ',
        'cancel': 'إلغاء',
      });
    });

    test('says so when nothing is missing', () async {
      File(
        p.join(dir.path, 'lib', 'l10n', 'app_ar.arb'),
      ).writeAsStringSync('{"save": "حفظ", "cancel": "إلغاء"}');
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
      );
      expect(code, 0);
      expect(lines.single, contains('Nothing to translate'));
    });

    test('needs an API key', () async {
      final code = await runTranslate(
        ['--to', 'ar', '--provider', 'gemini', dir.path],
        lines.add,
        environment: {},
      );
      expect(code, 64);
      expect(lines.single, contains('GEMINI_API_KEY'));
    });

    test('needs --to', () async {
      expect(await runTranslate([dir.path], lines.add, environment: {}), 64);
    });

    test('reports a failing provider', () async {
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'ANTHROPIC_API_KEY': 'k'},
        post: (u, h, b) async => throw const HttpException('401'),
      );
      expect(code, 1);
      expect(lines.single, startsWith('Translation failed'));
    });
  });
}
