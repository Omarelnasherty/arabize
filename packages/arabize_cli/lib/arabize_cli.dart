/// Command line entry point for arabize.
library;

import 'src/check.dart';
import 'src/extract.dart';
import 'src/fix.dart';
import 'src/l10n_check.dart';

export 'src/arb.dart' show ArbEntry, keyFor, mergeArb, toIcu;
export 'src/check.dart' show AnalyzeRunner, runCheck;
export 'src/extract.dart' show ExtractedString, findStrings, runExtract;
export 'src/fix.dart' show runFix;
export 'src/l10n_check.dart'
    show L10nIssue, checkL10n, icuPlaceholders, runL10nCheck;
export 'src/finding.dart' show Finding, arabizeRules, parseAnalyzeOutput;

/// The package version.
const String arabizeCliVersion = '0.3.0';

const _usage = '''
Usage: arabize <command>

Commands:
  check [path] [--format text|json]   Report RTL issues, exit 1 if any.
  fix [path] [--dry-run]              Apply the fixes, or print a diff.
  extract [path] [--format text|json] [--write] [--replace] [--arb file]
                                      List hardcoded strings, --write adds
                                      them to app_en.arb, --replace also
                                      swaps them for l10n getters.
  l10n-check [path] [--format text|json]
                                      Report missing and unused keys and
                                      placeholder mismatches in ARB files.
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
  if (args.isNotEmpty && args.first == 'l10n-check') {
    return runL10nCheck(args.sublist(1), out);
  }
  out(_usage);
  return args.isEmpty ? 0 : 64;
}
