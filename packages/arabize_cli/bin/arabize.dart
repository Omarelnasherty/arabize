import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';

void main(List<String> args) {
  exitCode = run(args, stdout.writeln);
}
