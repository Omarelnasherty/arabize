import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'finding.dart';

/// Runs `dart analyze --format=json` on [path] and returns its stdout.
typedef AnalyzeRunner = Future<String> Function(String path);

Future<String> _dartAnalyze(String path) async {
  final result = await Process.run('dart', [
    'analyze',
    '--format=json',
    path,
  ], runInShell: Platform.isWindows);
  return result.stdout as String;
}

/// Implements `arabize check [path] [--format text|json]`.
///
/// Returns 0 when nothing is found, 1 when there are findings, 2 when the
/// analyzer output could not be read and 64 on bad arguments.
Future<int> runCheck(
  List<String> args,
  void Function(String) out, {
  AnalyzeRunner analyze = _dartAnalyze,
}) async {
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

  final List<Finding> findings;
  try {
    findings = parseAnalyzeOutput(await analyze(path));
  } on FormatException catch (e) {
    out('Could not read analyzer output: ${e.message}');
    return 2;
  }

  if (format == 'json') {
    out(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'findings': findings.map((f) => f.toJson()).toList()}),
    );
  } else {
    for (final f in findings) {
      final file = p.relative(f.file);
      out('$file:${f.line}:${f.column}  ${f.rule}  ${f.message}');
    }
    out(
      findings.isEmpty
          ? 'No issues found.'
          : '${findings.length} issue${findings.length == 1 ? '' : 's'} found.',
    );
  }
  return findings.isEmpty ? 0 : 1;
}
