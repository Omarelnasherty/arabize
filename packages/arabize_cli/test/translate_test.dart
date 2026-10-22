import 'dart:convert';
import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('TranslateConfig', () {
    test('defaults give no instructions', () {
      expect(const TranslateConfig().instructions, isEmpty);
      expect(TranslateConfig.parse('').instructions, isEmpty);
    });

    test('parses tone, glossary and do-not-translate', () {
      final config = TranslateConfig.parse('''
tone: msa
glossary:
  Cart: عربة التسوق
do-not-translate: [Arabize, Pro]
''');
      expect(config.tone, 'msa');
      expect(config.glossary, {'Cart': 'عربة التسوق'});
      expect(config.doNotTranslate, ['Arabize', 'Pro']);
      expect(config.instructions, contains('Modern Standard Arabic'));
    });

    test('rejects wrong shapes', () {
      expect(
        () => TranslateConfig.parse('glossary: [a]'),
        throwsFormatException,
      );
      expect(
        () => TranslateConfig.parse('do-not-translate: a'),
        throwsFormatException,
      );
    });
  });

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

    test('translates a message again when its source text changed', () async {
      final l10n = p.join(dir.path, 'lib', 'l10n');
      File(p.join(l10n, 'app_ar.arb')).writeAsStringSync(
        '{"@@locale": "ar", "save": "حفظ", "cancel": "إلغاء"}',
      );
      File(p.join(l10n, translationLockFile)).writeAsStringSync(
        jsonEncode({
          'ar': {'save': 'Save', 'cancel': 'Dismiss'},
        }),
      );
      late String body;
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
        post: (u, h, b) async {
          body = b;
          return reply({'cancel': 'ألغِ'});
        },
      );
      expect(code, 0);
      expect(body, contains('Cancel'));
      expect(body, isNot(contains('Save')));
      final ar = jsonDecode(
        File(p.join(l10n, 'app_ar.arb')).readAsStringSync(),
      );
      expect(ar['cancel'], 'ألغِ');
      expect(ar['save'], 'حفظ');
      final lock = jsonDecode(
        File(p.join(l10n, translationLockFile)).readAsStringSync(),
      );
      expect(lock['ar'], {'save': 'Save', 'cancel': 'Cancel'});
    });

    test('records sources and then finds nothing to do', () async {
      var calls = 0;
      Future<String> post(Uri u, Map<String, String> h, String b) async {
        calls++;
        return reply({'save': 'حفظ', 'cancel': 'إلغاء'});
      }

      for (var i = 0; i < 2; i++) {
        await runTranslate(
          ['--to', 'ar', dir.path],
          lines.add,
          environment: {'OPENAI_API_KEY': 'k'},
          post: post,
        );
      }
      expect(calls, 1);
      expect(lines.last, 'Nothing to translate for ar.');
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

    test('sends the arabize.yaml instructions to the provider', () async {
      File(p.join(dir.path, 'arabize.yaml')).writeAsStringSync(
        'tone: egyptian\ndo-not-translate:\n  - Arabize\n'
        'glossary:\n  Cart: عربة\n',
      );
      late String body;
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
        post: (u, h, b) async {
          body = b;
          return reply({'save': 'حفظ', 'cancel': 'إلغاء'});
        },
      );
      expect(code, 0);
      expect(body, contains('Egyptian Arabic'));
      expect(body, contains('Never translate these terms: Arabize'));
      expect(body, contains('\\"Cart\\" as \\"عربة\\"'));
    });

    test('rejects an invalid arabize.yaml', () async {
      File(p.join(dir.path, 'arabize.yaml')).writeAsStringSync('tone: slang');
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
      );
      expect(code, 64);
      expect(lines.single, contains('tone must be msa or egyptian'));
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

    test('retries a message that lost a placeholder', () async {
      File(
        p.join(dir.path, 'lib', 'l10n', 'app_en.arb'),
      ).writeAsStringSync(jsonEncode({'hi': 'Hi {name}'}));
      var calls = 0;
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
        post: (u, h, b) async =>
            reply({'hi': ++calls == 1 ? 'مرحبا' : 'مرحبا {name}'}),
      );
      expect(code, 0);
      expect(calls, 2);
    });

    test('skips a message that never passes', () async {
      File(
        p.join(dir.path, 'lib', 'l10n', 'app_en.arb'),
      ).writeAsStringSync(jsonEncode({'hi': 'Hi {name}', 'ok': 'Ok'}));
      final code = await runTranslate(
        ['--to', 'ar', dir.path],
        lines.add,
        environment: {'OPENAI_API_KEY': 'k'},
        post: (u, h, b) async => reply({'hi': 'مرحبا', 'ok': 'حسنا'}),
      );
      expect(code, 1);
      final written = jsonDecode(
        File(p.join(dir.path, 'lib', 'l10n', 'app_ar.arb')).readAsStringSync(),
      );
      expect(written, {'@@locale': 'ar', 'ok': 'حسنا'});
      expect(lines.first, startsWith('Skipped hi'));
    });
  });

  group('pendingMessages', () {
    test('picks missing and changed messages', () {
      final todo = pendingMessages(
        {'@@locale': 'en', 'a': 'A', 'b': 'B2', 'c': 'C', 'd': 'D'},
        {'a', 'b', 'c'},
        {'a': 'A', 'b': 'B'},
      );
      expect(todo, {'b': 'B2', 'd': 'D'});
    });
  });

  group('validateTranslation', () {
    const plural = '{n, plural, one{1 item} other{{n} items}}';

    test('accepts a kept placeholder', () {
      expect(validateTranslation('Hi {name}', 'مرحبا {name}'), isNull);
    });

    test('rejects a changed placeholder name', () {
      expect(validateTranslation('Hi {name}', 'مرحبا {اسم}'), isNotNull);
    });

    test('accepts other plural categories', () {
      const ar =
          '{n, plural, zero{لا شيء} one{واحد} two{اثنان} few{{n} أشياء} '
          'many{{n} شيئا} other{{n} شيء}}';
      expect(validateTranslation(plural, ar), isNull);
    });

    test('rejects a dropped plural', () {
      expect(validateTranslation(plural, '{n} عناصر'), isNotNull);
    });

    test('rejects a plural without other', () {
      expect(
        validateTranslation(plural, '{n, plural, one{واحد} few{{n} عناصر}}'),
        'missing "other" case',
      );
    });

    test('rejects unbalanced braces and empty text', () {
      expect(validateTranslation('Hi {name}', 'مرحبا {name'), isNotNull);
      expect(validateTranslation('Hi', ' '), 'empty');
    });
  });
}
