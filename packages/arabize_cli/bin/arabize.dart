import 'dart:io';

import 'package:arabize_cli/arabize_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await run(args, stdout.writeln);
}
