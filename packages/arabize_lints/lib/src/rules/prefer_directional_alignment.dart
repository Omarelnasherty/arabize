import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../edits/directional_alignment_edits.dart';

/// Reports `Alignment` constants that point to the left or right.
class PreferDirectionalAlignment extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_directional_alignment',
    'Use AlignmentDirectional so the alignment flips in right-to-left '
        'layouts.',
    correctionMessage:
        'Try AlignmentDirectional.centerStart or '
        'AlignmentDirectional.centerEnd.',
  );

  PreferDirectionalAlignment()
    : super(
        name: 'prefer_directional_alignment',
        description:
            'Prefer AlignmentDirectional over Alignment with left and right.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addPrefixedIdentifier(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!directionalAlignmentNames.containsKey(node.identifier.name)) return;
    final element = node.prefix.element;
    if (element is! ClassElement || element.name != 'Alignment') return;
    if (!element.library.uri.toString().startsWith('package:flutter/')) return;
    rule.reportAtNode(node);
  }
}
