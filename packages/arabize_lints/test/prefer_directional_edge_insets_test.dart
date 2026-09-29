// ignore_for_file: non_constant_identifier_names
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/rules/prefer_directional_edge_insets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDirectionalEdgeInsetsTest);
  });
}

@reflectiveTest
class PreferDirectionalEdgeInsetsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferDirectionalEdgeInsets();
    newPackage('flutter').addFile('lib/painting.dart', r'''
class EdgeInsets {
  const EdgeInsets.all(double value);
  const EdgeInsets.symmetric({double vertical = 0, double horizontal = 0});
  const EdgeInsets.only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  });
  const EdgeInsets.fromLTRB(double left, double top, double right, double bottom);
}

class EdgeInsetsDirectional {
  const EdgeInsetsDirectional.only({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  });
  const EdgeInsetsDirectional.fromSTEB(
    double start,
    double top,
    double end,
    double bottom,
  );
}
''');
    super.setUp();
  }

  void test_only_left() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
var a = EdgeInsets.only(left: 8);
''',
      [lint(48, 24)],
    );
  }

  void test_only_right_and_top() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
var a = EdgeInsets.only(top: 4, right: 8);
''',
      [lint(48, 33)],
    );
  }

  void test_const_from_ltrb() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
var a = const EdgeInsets.fromLTRB(1, 2, 3, 4);
''',
      [lint(48, 37)],
    );
  }

  void test_implicit_new_from_ltrb() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
var a = EdgeInsets.fromLTRB(1, 2, 3, 4);
''',
      [lint(48, 31)],
    );
  }

  void test_only_top_bottom_is_fine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
var a = EdgeInsets.only(top: 4, bottom: 4);
''');
  }

  void test_other_constructors_are_fine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
var a = EdgeInsets.all(8);
var b = EdgeInsets.symmetric(horizontal: 8);
''');
  }

  void test_directional_is_fine() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
var a = EdgeInsetsDirectional.only(start: 8);
var b = EdgeInsetsDirectional.fromSTEB(1, 2, 3, 4);
''');
  }

  void test_unrelated_class_is_fine() async {
    await assertNoDiagnostics(r'''
class EdgeInsets {
  const EdgeInsets.only({int left = 0});
}
var a = EdgeInsets.only(left: 1);
''');
  }
}
