import 'dart:convert';
import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';
import 'package:arabize_cli/src/fix.dart';
import 'package:arabize_cli/src/rewrite.dart';
import 'package:test/test.dart';

String _apply(String rule, String code) {
  final edits = rewriteSnippet(rule, code)
    ..sort((a, b) => b.offset.compareTo(a.offset));
  var text = code;
  for (final e in edits) {
    text = text.replaceRange(e.offset, e.offset + e.length, e.text);
  }
  return text;
}

void main() {
  group('rewriteSnippet', () {
    test('edge insets', () {
      expect(
        _apply(
          'prefer_directional_edge_insets',
          'EdgeInsets.only(left: 8, top: 4, right: 2)',
        ),
        'EdgeInsetsDirectional.only(start: 8, top: 4, end: 2)',
      );
      expect(
        _apply(
          'prefer_directional_edge_insets',
          'EdgeInsets.fromLTRB(1, 2, 3, 4)',
        ),
        'EdgeInsetsDirectional.fromSTEB(1, 2, 3, 4)',
      );
    });

    test('keeps the const keyword', () {
      expect(
        _apply(
          'prefer_directional_edge_insets',
          'const EdgeInsets.only(left: 8)',
        ),
        'const EdgeInsetsDirectional.only(start: 8)',
      );
    });

    test('leaves nested arguments alone', () {
      expect(
        _apply(
          'prefer_directional_border',
          'Border(left: BorderSide(), right: Other(left: 1))',
        ),
        'BorderDirectional(start: BorderSide(), end: Other(left: 1))',
      );
    });

    test('positioned, border radius, alignment and text align', () {
      expect(
        _apply(
          'prefer_positioned_directional',
          'Positioned(left: 1, top: 2, child: c)',
        ),
        'PositionedDirectional(start: 1, top: 2, child: c)',
      );
      expect(
        _apply(
          'prefer_directional_border_radius',
          'BorderRadius.only(topLeft: r, bottomRight: r)',
        ),
        'BorderRadiusDirectional.only(topStart: r, bottomEnd: r)',
      );
      expect(
        _apply('prefer_directional_alignment', 'Alignment.centerLeft'),
        'AlignmentDirectional.centerStart',
      );
      expect(
        _apply('prefer_text_align_start_end', 'TextAlign.right'),
        'TextAlign.end',
      );
    });

    test('ignores code it does not understand', () {
      expect(
        rewriteSnippet('prefer_directional_alignment', 'Alignment.center'),
        isEmpty,
      );
      expect(
        rewriteSnippet('avoid_unmirrored_icons', 'Icons.chevron_left'),
        isEmpty,
      );
    });
  });

  group('fix', () {
    late Directory dir;
    late File file;
    const source =
        'a() => Text(\n'
        '  align: TextAlign.left,\n'
        '  pad: EdgeInsets.only(left: 4),\n'
        '  icon: Icons.chevron_left,\n'
        ');\n';

    setUp(() {
      dir = Directory.systemTemp.createTempSync('arabize_fix');
      file = File('${dir.path}/a.dart')..writeAsStringSync(source);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    Map<String, Object?> diagnostic(String rule, String code) {
      final offset = source.indexOf(code);
      return {
        'code': rule,
        'problemMessage': 'm',
        'location': {
          'file': file.path,
          'range': {
            'start': {'offset': offset, 'line': 1, 'column': 1},
            'end': {'offset': offset + code.length, 'line': 1, 'column': 1},
          },
        },
      };
    }

    Future<String> analyze(String path) async => jsonEncode({
      'diagnostics': [
        diagnostic('prefer_text_align_start_end', 'TextAlign.left'),
        diagnostic(
          'prefer_directional_edge_insets',
          'EdgeInsets.only(left: 4)',
        ),
        diagnostic('avoid_unmirrored_icons', 'Icons.chevron_left'),
      ],
    });

    test('rewrites the file', () async {
      final lines = <String>[];
      expect(await run(['fix'], lines.add, analyze: analyze), 0);
      expect(
        file.readAsStringSync(),
        source
            .replaceFirst('TextAlign.left', 'TextAlign.start')
            .replaceFirst(
              'EdgeInsets.only(left',
              'EdgeInsetsDirectional.only(start',
            ),
      );
      expect(lines, ['Fixed 2 issues in 1 file.', '1 need a manual change.']);
    });

    test('--dry-run prints a diff and keeps the file', () async {
      final lines = <String>[];
      expect(await run(['fix', '--dry-run'], lines.add, analyze: analyze), 0);
      expect(file.readAsStringSync(), source);
      expect(lines.first, contains('+++ b/'));
      expect(lines.first, contains('-  align: TextAlign.left,'));
      expect(lines.first, contains('+  align: TextAlign.start,'));
      expect(lines[1], 'Would fix 2 issues in 1 file.');
    });

    test('rejects unknown options and unreadable output', () async {
      expect(await run(['fix', '--nope'], (_) {}), 64);
      expect(await run(['fix'], (_) {}, analyze: (_) async => 'boom'), 2);
    });
  });

  test('applyFixes skips findings outside the file', () {
    const f = Finding(
      rule: 'prefer_text_align_start_end',
      file: 'a',
      line: 1,
      column: 1,
      offset: 100,
      length: 5,
      message: 'm',
    );
    expect(applyFixes('x', [f]).count, 0);
  });
}
