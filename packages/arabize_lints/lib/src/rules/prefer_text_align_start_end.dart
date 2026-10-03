import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../edits/text_align_edits.dart';

/// Reports `TextAlign.left` and `TextAlign.right`.
class PreferTextAlignStartEnd extends AnalysisRule {
  static const LintCode code = LintCode(
    'prefer_text_align_start_end',
    'Use TextAlign.start or TextAlign.end so the text flips in right-to-left '
        'layouts.',
    correctionMessage: 'Try TextAlign.start or TextAlign.end.',
  );

  PreferTextAlignStartEnd()
    : super(
        name: 'prefer_text_align_start_end',
        description: 'Prefer TextAlign.start and end over left and right.',
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
    if (!directionalTextAlignNames.containsKey(node.identifier.name)) return;
    final element = node.prefix.element;
    if (element is! EnumElement || element.name != 'TextAlign') return;
    final uri = element.library.uri.toString();
    if (!uri.startsWith('dart:ui') && !uri.startsWith('package:flutter/')) {
      return;
    }
    rule.reportAtNode(node);
  }
}
