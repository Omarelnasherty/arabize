import 'dart:io';

import 'package:path/path.dart' as p;

import 'check.dart';
import 'finding.dart';
import 'rewrite.dart';

/// Implements `arabize fix [path] [--dry-run]`.
///
/// Rewrites the code behind every fixable finding. With `--dry-run` the files
/// stay untouched and a diff is printed instead. Returns 0 on success, 2 when
/// the analyzer output could not be read and 64 on bad arguments.
Future<int> runFix(
  List<String> args,
  void Function(String) out, {
  AnalyzeRunner analyze = dartAnalyze,
}) async {
  var path = '.';
  var dryRun = false;
  for (final arg in args) {
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (!arg.startsWith('-')) {
      path = arg;
    } else {
      out('Unknown option: $arg');
      return 64;
    }
  }

  final List<Finding> findings;
  try {
    findings = parseAnalyzeOutput(await analyze(path));
  } on FormatException catch (e) {
    out('Could not read analyzer output: ${e.message}');
    return 2;
  }

  final byFile = <String, List<Finding>>{};
  for (final f in findings) {
    if (fixableRules.contains(f.rule)) {
      byFile.putIfAbsent(f.file, () => []).add(f);
    }
  }

  var fixed = 0;
  var files = 0;
  for (final entry in byFile.entries) {
    final file = File(entry.key);
    final before = file.readAsStringSync();
    final result = applyFixes(before, entry.value);
    if (result.count == 0) continue;
    fixed += result.count;
    files++;
    if (dryRun) {
      out(unifiedDiff(p.relative(entry.key), before, result.text));
    } else {
      file.writeAsStringSync(result.text);
    }
  }

  final skipped =
      findings.length -
      findings.where((f) => fixableRules.contains(f.rule)).length;
  final issues = '$fixed issue${fixed == 1 ? '' : 's'}';
  final inFiles = '$files file${files == 1 ? '' : 's'}';
  out(dryRun ? 'Would fix $issues in $inFiles.' : 'Fixed $issues in $inFiles.');
  if (skipped > 0) out('$skipped need a manual change.');
  return 0;
}

/// Applies the fixes for [findings] to [source].
///
/// Returns the new text and the number of findings that changed something.
({String text, int count}) applyFixes(String source, List<Finding> findings) {
  final edits = <Edit>[];
  var count = 0;
  for (final f in findings) {
    if (f.offset + f.length > source.length) continue;
    final snippet = source.substring(f.offset, f.offset + f.length);
    final local = rewriteSnippet(f.rule, snippet);
    if (local.isEmpty) continue;
    count++;
    for (final e in local) {
      edits.add((offset: e.offset + f.offset, length: e.length, text: e.text));
    }
  }
  // Findings can nest (a Border inside a Border), so drop repeated edits.
  final seen = <int>{};
  edits.removeWhere((e) => !seen.add(e.offset));
  edits.sort((a, b) => b.offset.compareTo(a.offset));
  var text = source;
  for (final e in edits) {
    text = text.replaceRange(e.offset, e.offset + e.length, e.text);
  }
  return (text: text, count: count);
}

/// A small unified diff for edits that never add or remove lines.
String unifiedDiff(String name, String before, String after) {
  final a = before.split('\n');
  final b = after.split('\n');
  final buffer = StringBuffer('--- a/$name\n+++ b/$name');
  for (var i = 0; i < a.length && i < b.length; i++) {
    if (a[i] == b[i]) continue;
    buffer
      ..write('\n@@ -${i + 1} +${i + 1} @@')
      ..write('\n-${a[i]}')
      ..write('\n+${b[i]}');
  }
  return buffer.toString();
}
