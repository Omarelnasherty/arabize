import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Reports `EdgeInsets.only(left/right)` and `EdgeInsets.fromLTRB`.
class PreferDirectionalEdgeInsets extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_directional_edge_insets',
    'Use EdgeInsetsDirectional so the padding flips in right-to-left layouts.',
    correctionMessage:
        'Try EdgeInsetsDirectional.only(start/end) or '
        'EdgeInsetsDirectional.fromSTEB.',
  );

  PreferDirectionalEdgeInsets()
    : super(
        name: 'prefer_directional_edge_insets',
        description:
            'Prefer EdgeInsetsDirectional over EdgeInsets with left and right.',
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
    final constructor = node.constructorName;
    final element = node.staticType?.element;
    if (element == null || element.name != 'EdgeInsets') return;
    if (!element.library!.uri.toString().startsWith('package:flutter/')) return;

    switch (constructor.name?.name) {
      case 'fromLTRB':
        rule.reportAtNode(node);
      case 'only':
        final usesSides = node.argumentList.arguments.any(
          (a) =>
              a is NamedArgument &&
              (a.name.lexeme == 'left' || a.name.lexeme == 'right'),
        );
        if (usesSides) rule.reportAtNode(node);
    }
  }
}
