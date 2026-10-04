import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// Reports `textDirection: TextDirection.ltr` and `.rtl` passed as arguments.
class AvoidHardcodedTextDirection extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_hardcoded_text_direction',
    'A fixed text direction ignores the locale of the app.',
    correctionMessage:
        'Try removing it, or read the direction from Directionality.of.',
  );

  AvoidHardcodedTextDirection()
    : super(
        name: 'avoid_hardcoded_text_direction',
        description: 'Avoid hardcoding TextDirection.ltr or TextDirection.rtl.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addNamedArgument(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitNamedArgument(NamedArgument node) {
    if (node.name.lexeme != 'textDirection') return;
    final value = node.argumentExpression;
    if (value is! PrefixedIdentifier) return;
    final name = value.identifier.name;
    if (name != 'ltr' && name != 'rtl') return;
    final element = value.prefix.element;
    if (element is! EnumElement || element.name != 'TextDirection') return;
    final uri = element.library.uri.toString();
    if (!uri.startsWith('dart:ui') && !uri.startsWith('package:flutter/')) {
      return;
    }
    rule.reportAtNode(value);
  }
}
