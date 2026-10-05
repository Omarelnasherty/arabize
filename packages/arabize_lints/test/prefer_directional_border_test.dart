// ignore_for_file: non_constant_identifier_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/edits/directional_border_edits.dart';
import 'package:arabize_lints/src/rules/prefer_directional_border.dart';
import 'package:test/test.dart' show equals, expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'border_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDirectionalBorderTest);
  });
}

@reflectiveTest
class PreferDirectionalBorderTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/painting.dart';\n";

  @override
  void setUp() {
    rule = PreferDirectionalBorder();
    newPackage('flutter').addFile('lib/painting.dart', borderStub);
    super.setUp();
  }

  Future<void> assertFixed(String source, String expected) async {
    final path = convertPath('$testPackageLibPath/$testFileName');
    newFile(path, source);
    result = await resolveFile(path);
    final finder = _CreationFinder();
    result.unit.accept(finder);
    var fixed = source;
    final edits = directionalBorderReplacements(finder.creation!)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final e in edits) {
      fixed = fixed.replaceRange(e.offset, e.offset + e.length, e.text);
    }
    expect(fixed, equals(expected));
  }

  void test_left() async {
    await assertDiagnostics('${_import}var a = Border(left: BorderSide());\n', [
      lint(48, 26),
    ]);
  }

  void test_right_and_top() async {
    await assertDiagnostics(
      '${_import}var a = const Border(top: BorderSide(), right: BorderSide());\n',
      [lint(48, 52)],
    );
  }

  void test_top_bottom_is_fine() async {
    await assertNoDiagnostics('''
${_import}var a = Border(top: BorderSide(), bottom: BorderSide());
var b = Border.symmetric(vertical: BorderSide());
''');
  }

  void test_directional_is_fine() async {
    await assertNoDiagnostics('''
${_import}var a = BorderDirectional(start: BorderSide());
''');
  }

  void test_fix() async {
    await assertFixed(
      '${_import}var a = const Border(left: BorderSide(), top: BorderSide());\n',
      '${_import}var a = const BorderDirectional(start: BorderSide(), '
          'top: BorderSide());\n',
    );
  }
}

class _CreationFinder extends RecursiveAstVisitor<void> {
  InstanceCreationExpression? creation;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    creation ??= node;
    super.visitInstanceCreationExpression(node);
  }
}
