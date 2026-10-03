// ignore_for_file: non_constant_identifier_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/edits/text_align_edits.dart';
import 'package:arabize_lints/src/rules/prefer_text_align_start_end.dart';
import 'package:test/test.dart' show equals, expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'text_align_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferTextAlignStartEndTest);
  });
}

@reflectiveTest
class PreferTextAlignStartEndTest extends AnalysisRuleTest {
  static const _import = "import 'package:flutter/painting.dart';\n";

  @override
  void setUp() {
    rule = PreferTextAlignStartEnd();
    newPackage('flutter').addFile('lib/painting.dart', textAlignStub);
    super.setUp();
  }

  Future<void> assertFixed(String source, String expected) async {
    final path = convertPath('$testPackageLibPath/$testFileName');
    newFile(path, source);
    result = await resolveFile(path);
    final finder = _IdentifierFinder();
    result.unit.accept(finder);
    var fixed = source;
    final edits = directionalTextAlignReplacements(finder.identifier!)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final e in edits) {
      fixed = fixed.replaceRange(e.offset, e.offset + e.length, e.text);
    }
    expect(fixed, equals(expected));
  }

  void test_left() async {
    await assertDiagnostics('${_import}var a = TextAlign.left;\n', [
      lint(48, 14),
    ]);
  }

  void test_right_as_argument() async {
    await assertDiagnostics('${_import}var a = [TextAlign.right];\n', [
      lint(49, 15),
    ]);
  }

  void test_start_end_center_are_fine() async {
    await assertNoDiagnostics('''
${_import}var a = [
  TextAlign.start,
  TextAlign.end,
  TextAlign.center,
  TextAlign.justify,
];
''');
  }

  void test_unrelated_enum_is_fine() async {
    await assertNoDiagnostics(r'''
enum TextAlign { left, right }
var a = TextAlign.left;
''');
  }

  void test_fix_left() async {
    await assertFixed(
      '${_import}var a = TextAlign.left;\n',
      '${_import}var a = TextAlign.start;\n',
    );
  }

  void test_fix_right() async {
    await assertFixed(
      '${_import}var a = TextAlign.right;\n',
      '${_import}var a = TextAlign.end;\n',
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
