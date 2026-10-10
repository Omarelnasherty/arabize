import 'package:arabize_cli/arabize_cli.dart';
import 'package:test/test.dart';

const _output = '''
Analyzing example...
{"version":1,"diagnostics":[
{"code":"prefer_directional_alignment","severity":"INFO","type":"STATIC_WARNING",
 "location":{"file":"/p/lib/b.dart","range":{"start":{"offset":1,"line":7,"column":3},"end":{"offset":9,"line":7,"column":11}}},
 "problemMessage":"Use AlignmentDirectional."},
{"code":"unused_import","severity":"INFO","type":"HINT",
 "location":{"file":"/p/lib/a.dart","range":{"start":{"offset":1,"line":1,"column":1},"end":{"offset":9,"line":1,"column":9}}},
 "problemMessage":"Unused import."},
{"code":"avoid_unmirrored_icons","severity":"INFO","type":"STATIC_WARNING",
 "location":{"file":"/p/lib/a.dart","range":{"start":{"offset":1,"line":4,"column":5},"end":{"offset":9,"line":4,"column":13}}},
 "problemMessage":"Icon does not mirror."}
]}''';

Future<String> _fake(String path) async => _output;
Future<String> _clean(String path) async => '{"version":1,"diagnostics":[]}';

void main() {
  test('prints the version', () async {
    final lines = <String>[];
    expect(await run(['--version'], lines.add), 0);
    expect(lines.single, 'arabize $arabizeCliVersion');
  });

  test('rejects unknown arguments', () async {
    expect(await run(['nope'], (_) {}), 64);
  });

  group('parseAnalyzeOutput', () {
    test('keeps only arabize rules, sorted by file and line', () {
      final findings = parseAnalyzeOutput(_output);
      expect(findings.map((f) => '${f.file}:${f.line}'), [
        '/p/lib/a.dart:4',
        '/p/lib/b.dart:7',
      ]);
    });

    test('throws when there is no JSON', () {
      expect(() => parseAnalyzeOutput('boom'), throwsFormatException);
    });
  });

  group('check', () {
    test('exits 1 and lists findings as text', () async {
      final lines = <String>[];
      final code = await run(['check'], lines.add, analyze: _fake);
      expect(code, 1);
      expect(lines.last, '2 issues found.');
      expect(lines.first, contains('avoid_unmirrored_icons'));
      expect(lines.first, contains(':4:5'));
    });

    test('exits 0 when clean', () async {
      final lines = <String>[];
      final code = await run(['check'], lines.add, analyze: _clean);
      expect(code, 0);
      expect(lines.single, 'No issues found.');
    });

    test('prints JSON', () async {
      final lines = <String>[];
      final code = await run(
        ['check', '--format', 'json'],
        lines.add,
        analyze: _fake,
      );
      expect(code, 1);
      expect(lines.single, contains('"rule": "avoid_unmirrored_icons"'));
      expect(lines.single, contains('"line": 7'));
    });

    test('passes the path to the analyzer', () async {
      String? seen;
      await run(
        ['check', 'lib'],
        (_) {},
        analyze: (path) async {
          seen = path;
          return _clean(path);
        },
      );
      expect(seen, 'lib');
    });

    test('rejects a bad format and unknown options', () async {
      expect(await run(['check', '--format=xml'], (_) {}), 64);
      expect(await run(['check', '--nope'], (_) {}), 64);
    });

    test('exits 2 when analyzer output is unreadable', () async {
      final code = await run(
        ['check'],
        (_) {},
        analyze: (_) async => 'crashed',
      );
      expect(code, 2);
    });
  });
}
