// ignore_for_file: non_constant_identifier_names
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/rules/avoid_unmirrored_icons.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'icons_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnmirroredIconsTest);
  });
}

@reflectiveTest
class AvoidUnmirroredIconsTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/widgets.dart';\n";

  @override
  void setUp() {
    rule = AvoidUnmirroredIcons();
    newPackage('flutter').addFile('lib/widgets.dart', iconsStub);
    super.setUp();
  }

  void test_chevron_left() async {
    await assertDiagnostics('${_import}var a = Icon(Icons.chevron_left);\n', [
      lint(52, 18),
    ]);
  }

  void test_chevron_right() async {
    await assertDiagnostics('${_import}var a = Icons.chevron_right;\n', [
      lint(47, 19),
    ]);
  }

  void test_variant_suffix() async {
    await assertDiagnostics(
      '${_import}var a = Icons.keyboard_arrow_right_rounded;\n',
      [lint(47, 34)],
    );
  }

  void test_match_text_direction_is_fine() async {
    await assertNoDiagnostics(
      '${_import}var a = Icon(Icons.chevron_left, matchTextDirection: true);\n',
    );
  }

  void test_match_text_direction_false_is_reported() async {
    await assertDiagnostics(
      '${_import}var a = Icon(Icons.chevron_left, matchTextDirection: false);\n',
      [lint(52, 18)],
    );
  }

  void test_other_icons_are_fine() async {
    await assertNoDiagnostics('''
${_import}var a = [Icons.home, Icons.arrow_back];
''');
  }

  void test_unrelated_class_is_fine() async {
    await assertNoDiagnostics(r'''
class Icons {
  static const chevron_left = 1;
}
var a = Icons.chevron_left;
''');
  }
}
