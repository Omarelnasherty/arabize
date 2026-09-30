// ignore_for_file: non_constant_identifier_names
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:arabize_lints/src/edits/directional_edge_insets_edits.dart';
import 'package:arabize_lints/src/rules/prefer_directional_edge_insets.dart';
import 'package:test/test.dart' show equals, expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'edge_insets_stub.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DirectionalEdgeInsetsEditsTest);
  });
}

@reflectiveTest
class DirectionalEdgeInsetsEditsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferDirectionalEdgeInsets();
    newPackage('flutter').addFile('lib/painting.dart', edgeInsetsStub);
    super.setUp();
  }

  Future<void> assertFixed(String source, String expected) async {
    final path = convertPath('$testPackageLibPath/$testFileName');
    newFile(path, source);
    result = await resolveFile(path);
    final finder = _CreationFinder();
    result.unit.accept(finder);
    var fixed = source;
    final edits = directionalEdgeInsetsReplacements(finder.creation!)
      ..sort((a, b) => b.offset.compareTo(a.offset));
    for (final e in edits) {
      fixed = fixed.replaceRange(e.offset, e.offset + e.length, e.text);
    }
    expect(fixed, equals(expected));
  }

  static const _import = "import 'package:flutter/painting.dart';\n";

  void test_only_left_and_right() async {
    await assertFixed(
      '${_import}var a = EdgeInsets.only(left: 8, top: 4, right: 2);\n',
      '${_import}var a = EdgeInsetsDirectional.only(start: 8, top: 4, end: 2);\n',
    );
  }

  void test_from_ltrb() async {
    await assertFixed(
      '${_import}var a = EdgeInsets.fromLTRB(1, 2, 3, 4);\n',
      '${_import}var a = EdgeInsetsDirectional.fromSTEB(1, 2, 3, 4);\n',
    );
  }

  void test_const_keyword_is_kept() async {
    await assertFixed(
      '${_import}var a = const EdgeInsets.only(right: 8);\n',
      '${_import}var a = const EdgeInsetsDirectional.only(end: 8);\n',
    );
  }

  void test_import_prefix() async {
    await assertFixed(
      "import 'package:flutter/painting.dart' as p;\n"
          'var a = p.EdgeInsets.only(left: 8);\n',
      "import 'package:flutter/painting.dart' as p;\n"
          'var a = p.EdgeInsetsDirectional.only(start: 8);\n',
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
