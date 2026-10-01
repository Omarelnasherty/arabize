// ignore_for_file: non_constant_identifier_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/edits/directional_alignment_edits.dart';
import 'package:arabize_lints/src/rules/prefer_directional_alignment.dart';
import 'package:test/test.dart' show equals, expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'alignment_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferDirectionalAlignmentTest);
  });
}

@reflectiveTest
class PreferDirectionalAlignmentTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/painting.dart';\n";

  @override
  void setUp() {
    rule = PreferDirectionalAlignment();
    newPackage('flutter').addFile('lib/painting.dart', alignmentStub);
    super.setUp();
  }

  Future<void> assertFixed(String source, String expected) async {
    final path = convertPath('$testPackageLibPath/$testFileName');
    newFile(path, source);
    result = await resolveFile(path);
    final finder = _IdentifierFinder();
    result.unit.accept(finder);
    var fixed = source;
    final edits = directionalAlignmentReplacements(finder.identifier!)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final e in edits) {
      fixed = fixed.replaceRange(e.offset, e.offset + e.length, e.text);
    }
    expect(fixed, equals(expected));
  }

  void test_center_left() async {
    await assertDiagnostics('${_import}var a = Alignment.centerLeft;\n', [
      lint(48, 20),
    ]);
  }

  void test_top_right_as_argument() async {
    await assertDiagnostics('${_import}var a = [Alignment.topRight];\n', [
      lint(49, 18),
    ]);
  }

  void test_bottom_left() async {
    await assertDiagnostics('${_import}var a = Alignment.bottomLeft;\n', [
      lint(48, 20),
    ]);
  }

  void test_center_variants_are_fine() async {
    await assertNoDiagnostics('''
${_import}var a = [
  Alignment.center,
  Alignment.topCenter,
  Alignment.bottomCenter,
];
''');
  }

  void test_directional_is_fine() async {
    await assertNoDiagnostics(
      '${_import}var a = AlignmentDirectional.centerStart;\n',
    );
  }

  void test_unrelated_class_is_fine() async {
    await assertNoDiagnostics(r'''
class Alignment {
  static const centerLeft = 1;
}
var a = Alignment.centerLeft;
''');
  }

  void test_fix_left() async {
    await assertFixed(
      '${_import}var a = Alignment.centerLeft;\n',
      '${_import}var a = AlignmentDirectional.centerStart;\n',
    );
  }

  void test_fix_bottom_right() async {
    await assertFixed(
      '${_import}var a = Alignment.bottomRight;\n',
      '${_import}var a = AlignmentDirectional.bottomEnd;\n',
    );
  }
}

class _IdentifierFinder extends RecursiveAstVisitor<void> {
  PrefixedIdentifier? identifier;

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    identifier ??= node;
    super.visitPrefixedIdentifier(node);
  }
}
