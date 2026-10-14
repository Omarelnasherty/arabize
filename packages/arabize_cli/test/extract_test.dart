import 'dart:convert';
import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('findStrings', () {
    List<String> texts(String source) => [
      for (final s in findStrings(source)) '${s.context}: ${s.text}',
    ];

    test('finds Text and const Text', () {
      expect(
        texts('''
void f() {
  Text('Hello');
  const Text("World");
  SelectableText('Copy me');
}'''),
        ['Text: Hello', 'Text: World', 'SelectableText: Copy me'],
      );
    });

    test('finds named arguments', () {
      expect(
        texts('''
void f() {
  TextField(
    decoration: InputDecoration(hintText: 'Search', labelText: 'Name'),
  );
  IconButton(tooltip: 'Back', onPressed: null);
  Tooltip(message: 'More', child: x);
  Other(message: 'Skipped');
}'''),
        [
          'hintText: Search',
          'labelText: Name',
          'tooltip: Back',
          'message: More',
        ],
      );
    });

    test('finds a string inside a SnackBar', () {
      expect(texts("void f() => SnackBar(content: Text('Saved'));"), [
        'Text: Saved',
      ]);
    });

    test('keeps interpolation as written', () {
      expect(
        texts(r"void f() => Text('Hi $name, you have ${items.length}');"),
        [r'Text: Hi $name, you have ${items.length}'],
      );
    });

    test('joins adjacent strings', () {
      expect(texts("void f() => Text('One ' 'two');"), ['Text: One two']);
    });

    test('ignores non-literals and strings without letters', () {
      expect(
        texts('''
void f() {
  Text(title);
  Text('12:30');
  Text('/');
  Text(l10n.title);
}'''),
        isEmpty,
      );
    });

    test('finds Arabic text and reports the position', () {
      final found = findStrings("void f() {\n  Text('مرحبا');\n}");
      expect(found.single.text, 'مرحبا');
      expect(found.single.line, 2);
      expect(found.single.column, 8);
    });
  });

  group('extract', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('arabize_extract');
      Directory(p.join(dir.path, 'lib')).createSync();
      Directory(p.join(dir.path, 'test')).createSync();
      File(
        p.join(dir.path, 'lib', 'a.dart'),
      ).writeAsStringSync("void f() => Text('Hello');");
      File(
        p.join(dir.path, 'lib', 'a.g.dart'),
      ).writeAsStringSync("void f() => Text('Generated');");
      File(
        p.join(dir.path, 'test', 'a_test.dart'),
      ).writeAsStringSync("void f() => Text('In test');");
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('lists strings under lib as text', () async {
      final lines = <String>[];
      expect(await run(['extract', dir.path], lines.add), 0);
      expect(lines, hasLength(2));
      expect(lines.first, contains('Text  "Hello"'));
      expect(lines.last, '1 string found.');
    });

    test('prints JSON', () async {
      final lines = <String>[];
      await run(['extract', dir.path, '--format', 'json'], lines.add);
      final decoded = jsonDecode(lines.single) as Map<String, Object?>;
      final strings = decoded['strings'] as List<Object?>;
      expect((strings.single as Map)['text'], 'Hello');
    });

    test('reports when nothing is found', () async {
      final empty = Directory.systemTemp.createTempSync('arabize_empty');
      addTearDown(() => empty.deleteSync(recursive: true));
      final lines = <String>[];
      expect(await run(['extract', empty.path], lines.add), 0);
      expect(lines.single, 'No hardcoded strings found.');
    });

    test('rejects bad options', () async {
      expect(await run(['extract', '--nope'], (_) {}), 64);
      expect(await run(['extract', '--format', 'xml'], (_) {}), 64);
    });
  });
}
