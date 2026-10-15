import 'dart:convert';
import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('toIcu', () {
    test('turns interpolation into placeholders', () {
      final icu = toIcu(r'Hi $name, you have ${items.length} items');
      expect(icu.message, 'Hi {name}, you have {length} items');
      expect(icu.placeholders, ['name', 'length']);
    });

    test('escapes braces and apostrophes', () {
      expect(toIcu("Don't {use}").message, "Don''t '{'use'}'");
    });
  });

  group('keyFor', () {
    test('uses the first words in camelCase', () {
      expect(keyFor('Save your changes now please'), 'saveYourChangesNow');
    });

    test('falls back for non-latin text', () {
      expect(keyFor('حفظ', fallback: 'label'), 'label');
    });
  });

  group('mergeArb', () {
    List<ExtractedString> strings(List<String> texts) => [
      for (final t in texts)
        ExtractedString(
          file: 'a.dart',
          line: 1,
          column: 1,
          context: 'Text',
          text: t,
        ),
    ];

    test('creates a file with a locale', () {
      final merged = mergeArb(null, strings(['Hello']));
      expect(jsonDecode(merged.content), {'@@locale': 'en', 'hello': 'Hello'});
    });

    test('keeps existing entries and reuses keys', () {
      final merged = mergeArb(
        '{"@@locale": "en", "greeting": "Hello"}',
        strings(['Hello', 'Save', 'Save']),
      );
      expect(merged.added.map((e) => e.key), ['save']);
      expect(jsonDecode(merged.content), {
        '@@locale': 'en',
        'greeting': 'Hello',
        'save': 'Save',
      });
    });

    test('adds a suffix when keys clash', () {
      final merged = mergeArb(
        '{"save": "Save file"}',
        strings(['Save', r'Save $x']),
      );
      expect(merged.added.map((e) => e.key), ['save2', 'save3']);
    });

    test('adds placeholder metadata', () {
      final merged = mergeArb(null, strings([r'Hi $name']));
      expect(jsonDecode(merged.content)['@hi'], {
        'placeholders': {
          'name': {'type': 'String'},
        },
      });
    });
  });

  group('extract --write', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('arabize_arb');
      Directory(p.join(dir.path, 'lib')).createSync();
      File(
        p.join(dir.path, 'lib', 'a.dart'),
      ).writeAsStringSync("void f() => Text('Hello');");
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('writes lib/l10n/app_en.arb by default', () async {
      final lines = <String>[];
      expect(await run(['extract', dir.path, '--write'], lines.add), 0);
      final arb = File(p.join(dir.path, 'lib', 'l10n', 'app_en.arb'));
      expect(jsonDecode(arb.readAsStringSync())['hello'], 'Hello');
      expect(lines.last, contains('Added 1 key'));
    });

    test('reads the path from l10n.yaml', () async {
      File(
        p.join(dir.path, 'l10n.yaml'),
      ).writeAsStringSync('arb-dir: assets/l10n\ntemplate-arb-file: en.arb\n');
      await run(['extract', dir.path, '--write'], (_) {});
      expect(
        File(p.join(dir.path, 'assets', 'l10n', 'en.arb')).existsSync(),
        isTrue,
      );
    });

    test('--arb overrides the path', () async {
      final file = p.join(dir.path, 'x.arb');
      await run(['extract', dir.path, '--write', '--arb', file], (_) {});
      expect(File(file).existsSync(), isTrue);
    });
  });
}
