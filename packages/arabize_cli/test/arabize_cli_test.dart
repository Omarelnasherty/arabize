import 'package:arabize_cli/arabize_cli.dart';
import 'package:test/test.dart';

void main() {
  test('prints the version', () {
    final lines = <String>[];
    expect(run(['--version'], lines.add), 0);
    expect(lines.single, 'arabize $arabizeCliVersion');
  });

  test('rejects unknown arguments', () {
    expect(run(['nope'], (_) {}), 64);
  });
}
