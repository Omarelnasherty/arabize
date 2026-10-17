import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('icuPlaceholders', () {
    test('finds simple arguments', () {
      expect(icuPlaceholders('Hi {name}, {count} items'), {'name', 'count'});
    });

    test('finds plural and select arguments with nested ones', () {
      expect(
        icuPlaceholders(
          '{count, plural, =0{None} one{{name} has # item} other{# items}}',
        ),
        {'count', 'name'},
      );
      expect(icuPlaceholders('{g, select, male{He} female{She} other{They}}'), {
        'g',
      });
    });

    test('ignores quoted braces', () {
      expect(icuPlaceholders("Use '{'x'}' and don''t {y}"), {'y'});
    });

    test('skips the style of date and number arguments', () {
      expect(icuPlaceholders('On {d, date, yyyy-MM-dd}: {n, number}'), {
        'd',
        'n',
      });
    });
  });

  group('checkL10n', () {
    const en = '''
{
  "@@locale": "en",
  "hello": "Hello {name}",
  "@hello": {"placeholders": {"name": {}}},
  "save": "Save",
  "unusedKey": "Unused"
}''';

    List<String> kinds(String ar, {String code = 'hello save'}) => [
      for (final i in checkL10n(
        arbs: {'app_en.arb': en, 'app_ar.arb': ar},
        template: 'app_en.arb',
        sources: ['final a = l10n.hello(n); final b = l10n.save;', code],
      ))
        '${i.kind}:${i.file}:${i.key}',
    ];

    test('reports unused template keys', () {
      expect(
        kinds('{"hello": "مرحبا {name}", "save": "حفظ", "unusedKey": "x"}'),
        ['unused:app_en.arb:unusedKey'],
      );
    });

    test('reports missing and extra keys', () {
      expect(kinds('{"hello": "مرحبا {name}", "other": "x"}'), [
        'unused:app_en.arb:unusedKey',
        'missing:app_ar.arb:save',
        'missing:app_ar.arb:unusedKey',
        'extra:app_ar.arb:other',
      ]);
    });

    test('reports placeholder mismatches', () {
      final issues = checkL10n(
        arbs: {
          'app_en.arb': en,
          'app_ar.arb': '{"hello": "مرحبا {nom}", "save": "حفظ"}',
        },
        template: 'app_en.arb',
        sources: ['.hello .save .unusedKey'],
      );
      expect(issues.map((i) => i.kind), ['placeholders', 'missing']);
      expect(issues.first.message, 'expected {name}, found {nom}');
    });
  });

  group('runL10nCheck', () {
    late Directory dir;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('l10n_check');
      Directory(p.join(dir.path, 'lib', 'l10n')).createSync(recursive: true);
      File(
        p.join(dir.path, 'lib', 'l10n', 'app_en.arb'),
      ).writeAsStringSync('{"hello": "Hello"}');
      File(
        p.join(dir.path, 'lib', 'l10n', 'app_ar.arb'),
      ).writeAsStringSync('{"hello": "مرحبا"}');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    test('exits 0 when everything matches', () async {
      File(
        p.join(dir.path, 'lib', 'main.dart'),
      ).writeAsStringSync('var a = l10n.hello;');
      final lines = <String>[];
      expect(await runL10nCheck([dir.path], lines.add), 0);
      expect(lines, ['No l10n issues found.']);
    });

    test('exits 1 and prints json', () async {
      File(p.join(dir.path, 'lib', 'main.dart')).writeAsStringSync('var a;');
      final lines = <String>[];
      expect(await runL10nCheck([dir.path, '--format', 'json'], lines.add), 1);
      expect(lines.single, contains('"kind": "unused"'));
    });

    test('exits 64 without a template', () async {
      File(p.join(dir.path, 'lib', 'l10n', 'app_en.arb')).deleteSync();
      expect(await runL10nCheck([dir.path], (_) {}), 64);
    });
  });
}
