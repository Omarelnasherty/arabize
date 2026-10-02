// ignore_for_file: non_constant_identifier_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/edits/directional_positioned_edits.dart';
import 'package:arabize_lints/src/rules/prefer_positioned_directional.dart';
import 'package:test/test.dart' show equals, expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'positioned_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferPositionedDirectionalTest);
  });
}

@reflectiveTest
class PreferPositionedDirectionalTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/widgets.dart';\n";

  @override
  void setUp() {
    rule = PreferPositionedDirectional();
    newPackage('flutter').addFile('lib/widgets.dart', positionedStub);
    super.setUp();
  }

  Future<void> assertFixed(String source, String expected) async {
    final path = convertPath('$testPackageLibPath/$testFileName');
    newFile(path, source);
    result = await resolveFile(path);
    final finder = _CreationFinder();
    result.unit.accept(finder);
    var fixed = source;
    final edits = directionalPositionedReplacements(finder.creation!)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final e in edits) {
      fixed = fixed.replaceRange(e.offset, e.offset + e.length, e.text);
    }
    expect(fixed, equals(expected));
  }

  void test_left() async {
    await assertDiagnostics('${_import}var a = Positioned(left: 8);\n', [
      lint(47, 19),
    ]);
  }

  void test_right_and_top_const() async {
    await assertDiagnostics(
      '${_import}var a = const Positioned(top: 4, right: 8);\n',
      [lint(47, 34)],
    );
  }

  void test_top_only_is_fine() async {
    await assertNoDiagnostics(
      '${_import}var a = Positioned(top: 4, bottom: 4);\n',
    );
  }

  void test_fill_is_fine() async {
    await assertNoDiagnostics(
      '${_import}var a = Positioned.fill(left: 4, right: 4);\n',
    );
  }

  void test_directional_is_fine() async {
    await assertNoDiagnostics(
      '${_import}var a = PositionedDirectional(start: 8);\n',
    );
  }

  void test_unrelated_class_is_fine() async {
    await assertNoDiagnostics(r'''
class Positioned {
  const Positioned({double? left});
}
var a = Positioned(left: 8);
''');
  }

  void test_fix_left_and_right() async {
    await assertFixed(
      '${_import}var a = Positioned(left: 1, top: 2, right: 3);\n',
      '${_import}var a = PositionedDirectional(start: 1, top: 2, end: 3);\n',
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
