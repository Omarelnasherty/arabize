/// Command line entry point for arabize.
library;

import 'src/check.dart';

export 'src/check.dart' show AnalyzeRunner, runCheck;
export 'src/finding.dart' show Finding, arabizeRules, parseAnalyzeOutput;

/// The package version.
const String arabizeCliVersion = '0.0.1';

const _usage = '''
Usage: arabize <command>

Commands:
  check [path] [--format text|json]   Report RTL issues, exit 1 if any.
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
  out(_usage);
  return args.isEmpty ? 0 : 64;
}
