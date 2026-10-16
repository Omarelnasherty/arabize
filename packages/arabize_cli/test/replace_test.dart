import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:arabize_cli/src/l10n_config.dart';
import 'package:arabize_cli/src/replace.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _import = 'package:app/l10n/app_localizations.dart';

ReplaceResult _replace(String source, {L10nConfig? config}) {
  final strings = findStrings(source);
  return replaceStrings(
    source,
    keys: mergeArb(null, strings).keys,
    config: config ?? const L10nConfig(),
    importUri: _import,
  );
}

void main() {
  group('replaceStrings', () {
    test('replaces a string and adds the import', () {
      final result = _replace('''
import 'package:flutter/material.dart';

Widget build(BuildContext context) => Text('Hello');
''');
      expect(result.replaced, 1);
      expect(result.source, contains("import '$_import';"));
      expect(
        result.source,
        contains('Text(AppLocalizations.of(context)!.hello)'),
      );
    });

    test('turns interpolation into arguments', () {
      final result = _replace(r'''
Widget build(BuildContext context) =>
    Text('Hi $name, you have ${items.length} items');
''');
      expect(
        result.source,
        contains('.of(context)!.hiYouHaveItems(name, items.length)'),
      );
    });

    test('uses one argument for a repeated expression', () {
      final result = _replace(r'''
Widget build(BuildContext context) => Text('$a and $a and ${b.a}');
''');
      expect(result.source, contains('.andAnd(a, b.a)'));
    });

    test('drops const on the enclosing widget', () {
      final result = _replace('''
Widget build(BuildContext context) =>
    const Padding(padding: x, child: Text('Hello'));
''');
      expect(result.source, isNot(contains('const')));
      expect(result.source, contains('Padding(padding: x, child: Text('));
    });

    test('skips strings in constant literals', () {
      final result = _replace('''
Widget build(BuildContext context) => Column(
  children: const [Text('Hello')],
);
''');
      expect(result.replaced, 0);
      expect(result.skipped, hasLength(1));
    });

    test('skips strings without a context in scope', () {
      final result = _replace("Widget build() => Text('Hello');");
      expect(result.replaced, 0);
      expect(result.source, "Widget build() => Text('Hello');");
    });

    test('finds the context of an outer method', () {
      final result = _replace('''
Widget build(BuildContext context) {
  return Button(onPressed: () => show(Text('Hello')));
}
''');
      expect(result.replaced, 1);
    });

    test('skips an escaped dollar sign', () {
      final result = _replace(
        r"Widget build(BuildContext context) => Text('Costs \$5');",
      );
      expect(result.replaced, 0);
    });

    test('follows l10n.yaml', () {
      final config = L10nConfig.parse(
        'output-class: S\nnullable-getter: false\n',
      );
      final result = _replace(
        "Widget build(BuildContext context) => Text('Hello');",
        config: config,
      );
      expect(result.source, contains('Text(S.of(context).hello)'));
    });

    test('keeps an existing import', () {
      final result = _replace('''
import 'package:app/l10n/app_localizations.dart';

Widget build(BuildContext context) => Text('Hello');
''');
      expect('import '.allMatches(result.source), hasLength(1));
    });
  });

  group('extract --replace', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('arabize_replace');
      Directory(p.join(dir.path, 'lib')).createSync();
      File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('name: demo\n');
      File(p.join(dir.path, 'lib', 'a.dart')).writeAsStringSync('''
import 'package:flutter/material.dart';

Widget build(BuildContext context) => Text('Hello');
''');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('writes the ARB file and rewrites the code', () async {
      final lines = <String>[];
      expect(await run(['extract', dir.path, '--replace'], lines.add), 0);
      final code = File(p.join(dir.path, 'lib', 'a.dart')).readAsStringSync();
      expect(
        code,
        contains("import 'package:demo/l10n/app_localizations.dart';"),
      );
      expect(code, contains('AppLocalizations.of(context)!.hello'));
      expect(
        File(p.join(dir.path, 'lib', 'l10n', 'app_en.arb')).existsSync(),
        isTrue,
      );
      expect(lines.last, 'Replaced 1 string.');
    });

    test('needs a pubspec', () async {
      File(p.join(dir.path, 'pubspec.yaml')).deleteSync();
      expect(await run(['extract', dir.path, '--replace'], (_) {}), 64);
    });
  });

  group('L10nConfig', () {
    test('has defaults', () {
      const config = L10nConfig();
      expect(config.arbDir, 'lib/l10n');
      expect(config.nullableGetter, isTrue);
    });
  });
}
