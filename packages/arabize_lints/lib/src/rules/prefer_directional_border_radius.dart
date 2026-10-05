import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../edits/directional_border_edits.dart';

/// Reports `BorderRadius.only` and `BorderRadius.horizontal` with physical
/// sides.
class PreferDirectionalBorderRadius extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_directional_border_radius',
    'Use BorderRadiusDirectional so the corners flip in right-to-left '
        'layouts.',
    correctionMessage:
        'Try BorderRadiusDirectional.only(topStart/topEnd/...) or '
        'BorderRadiusDirectional.horizontal.',
  );

  PreferDirectionalBorderRadius()
    : super(
        name: 'prefer_directional_border_radius',
        description:
            'Prefer BorderRadiusDirectional over BorderRadius with left and '
            'right corners.',
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
    if (element == null || element.name != 'BorderRadius') return;
    if (!element.library!.uri.toString().startsWith('package:flutter/')) return;

    switch (node.constructorName.name?.name) {
      case 'only':
      case 'horizontal':
        if (usesLabels(node, directionalBorderRadiusLabels.keys)) {
          rule.reportAtNode(node);
        }
    }
  }
}
