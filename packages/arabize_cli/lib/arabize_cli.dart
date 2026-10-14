/// Command line entry point for arabize.
library;

import 'src/check.dart';
import 'src/extract.dart';
import 'src/fix.dart';

export 'src/check.dart' show AnalyzeRunner, runCheck;
export 'src/extract.dart' show ExtractedString, findStrings, runExtract;
export 'src/fix.dart' show runFix;
export 'src/finding.dart' show Finding, arabizeRules, parseAnalyzeOutput;

/// The package version.
const String arabizeCliVersion = '0.2.0';

const _usage = '''
Usage: arabize <command>

Commands:
  check [path] [--format text|json]   Report RTL issues, exit 1 if any.
  fix [path] [--dry-run]              Apply the fixes, or print a diff.
  extract [path] [--format text|json] List hardcoded user-facing strings.
  --version                           Print the version.''';

/// Runs the CLI with [args] and returns the exit code.
Future<int> run(
  List<String> args,
  void Function(String) out, {
  AnalyzeRunner? analyze,
}) async {
  if (args.contains('--version')) {
    out('arabize $arabizeCliVersion');
    return 0;
  }
  if (args.isNotEmpty && args.first == 'check') {
    return analyze == null
        ? runCheck(args.sublist(1), out)
        : runCheck(args.sublist(1), out, analyze: analyze);
  }
  if (args.isNotEmpty && args.first == 'fix') {
    return analyze == null
        ? runFix(args.sublist(1), out)
        : runFix(args.sublist(1), out, analyze: analyze);
  }
  if (args.isNotEmpty && args.first == 'extract') {
    return runExtract(args.sublist(1), out);
  }
  out(_usage);
  return args.isEmpty ? 0 : 64;
}
