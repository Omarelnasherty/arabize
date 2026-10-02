import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../edits/directional_positioned_edits.dart';

/// Reports `Positioned` widgets that set `left` or `right`.
class PreferPositionedDirectional extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_positioned_directional',
    'Use PositionedDirectional so the position flips in right-to-left '
        'layouts.',
    correctionMessage: 'Try PositionedDirectional with start and end.',
  );

  PreferPositionedDirectional()
    : super(
        name: 'prefer_positioned_directional',
        description:
            'Prefer PositionedDirectional over Positioned with left and right.',
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
    final element = node.staticType?.element;
    if (element == null || element.name != 'Positioned') return;
    if (!element.library!.uri.toString().startsWith('package:flutter/')) return;
    if (usesPositionedSides(node)) rule.reportAtNode(node);
  }
}
