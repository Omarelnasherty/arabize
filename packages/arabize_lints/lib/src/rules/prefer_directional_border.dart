import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../edits/directional_border_edits.dart';

/// Reports `Border(left: ..., right: ...)`.
class PreferDirectionalBorder extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_directional_border',
    'Use BorderDirectional so the sides flip in right-to-left layouts.',
    correctionMessage: 'Try BorderDirectional(start: ..., end: ...).',
  );

  PreferDirectionalBorder()
    : super(
        name: 'prefer_directional_border',
        description:
            'Prefer BorderDirectional over Border with left and right.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.name != null) return;
    final element = node.staticType?.element;
    if (element == null || element.name != 'Border') return;
    if (!element.library!.uri.toString().startsWith('package:flutter/')) return;

    if (usesLabels(node, directionalBorderLabels.keys)) {
      rule.reportAtNode(node);
    }
  }
}
