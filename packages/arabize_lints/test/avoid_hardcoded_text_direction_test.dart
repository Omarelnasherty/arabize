// ignore_for_file: non_constant_identifier_names
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/rules/avoid_hardcoded_text_direction.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'text_direction_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHardcodedTextDirectionTest);
  });
}

@reflectiveTest
class AvoidHardcodedTextDirectionTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/painting.dart';\n";

  @override
  void setUp() {
    rule = AvoidHardcodedTextDirection();
    newPackage('flutter').addFile('lib/painting.dart', textDirectionStub);
    super.setUp();
  }

  void test_ltr() async {
    await assertDiagnostics(
      '${_import}var a = Directionality(textDirection: TextDirection.ltr);\n',
      [lint(78, 17)],
    );
  }

  void test_rtl() async {
    await assertDiagnostics(
      '${_import}var a = Directionality(textDirection: TextDirection.rtl);\n',
      [lint(78, 17)],
    );
  }

  void test_value_from_variable_is_fine() async {
    await assertNoDiagnostics('''
${_import}void f(TextDirection d) {
  Directionality(textDirection: d);
}
''');
  }

  void test_other_argument_name_is_fine() async {
    await assertNoDiagnostics(
      '${_import}var a = Other(direction: TextDirection.ltr);\n',
    );
  }

  void test_unrelated_enum_is_fine() async {
    await assertNoDiagnostics(r'''
enum TextDirection { rtl, ltr }
void f({TextDirection? textDirection}) {}
void g() => f(textDirection: TextDirection.ltr);
''');
  }
}
