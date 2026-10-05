// ignore_for_file: non_constant_identifier_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/edits/directional_border_edits.dart';
import 'package:arabize_lints/src/rules/prefer_directional_border_radius.dart';
import 'package:test/test.dart' show equals, expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'border_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDirectionalBorderRadiusTest);
  });
}

@reflectiveTest
class PreferDirectionalBorderRadiusTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/painting.dart';\n";

  @override
  void setUp() {
    rule = PreferDirectionalBorderRadius();
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
    final edits = directionalBorderRadiusReplacements(finder.creation!)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final e in edits) {
      fixed = fixed.replaceRange(e.offset, e.offset + e.length, e.text);
    }
    expect(fixed, equals(expected));
  }

  void test_only() async {
    await assertDiagnostics(
      '${_import}var a = BorderRadius.only(topLeft: Radius.circular(4));\n',
      [lint(48, 46)],
    );
  }

  void test_horizontal() async {
    await assertDiagnostics(
      '${_import}var a = BorderRadius.horizontal(right: Radius.circular(4));\n',
      [lint(48, 50)],
    );
  }

  void test_all_and_vertical_are_fine() async {
    await assertNoDiagnostics('''
${_import}var a = BorderRadius.all(Radius.circular(4));
var b = BorderRadius.vertical(top: Radius.circular(4));
''');
  }

  void test_directional_is_fine() async {
    await assertNoDiagnostics('''
${_import}var a = BorderRadiusDirectional.only(topStart: Radius.circular(4));
''');
  }

  void test_fix_only() async {
    await assertFixed(
      '${_import}var a = const BorderRadius.only(topLeft: Radius.circular(4), '
          'bottomRight: Radius.circular(2));\n',
      '${_import}var a = const BorderRadiusDirectional.only(topStart: '
          'Radius.circular(4), bottomEnd: Radius.circular(2));\n',
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
