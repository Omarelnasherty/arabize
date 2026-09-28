/// Command line entry point for arabize.
library;

/// The package version.
const String arabizeCliVersion = '0.0.1';

/// Runs the CLI with [args] and returns the exit code.
int run(List<String> args, void Function(String) out) {
  if (args.contains('--version')) {
    out('arabize $arabizeCliVersion');
    return 0;
  }
  out('Usage: arabize --version');
  return args.isEmpty ? 0 : 64;
}
