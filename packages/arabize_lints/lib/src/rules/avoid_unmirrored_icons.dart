import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

final _directionalIcon = RegExp(
  r'^(chevron|keyboard_arrow|arrow)_(left|right)(_(outlined|rounded|sharp))?$',
);

const _iconClasses = {'Icons', 'CupertinoIcons'};

/// Reports left and right pointing icons that stay the same in right-to-left
/// layouts.
class AvoidUnmirroredIcons extends AnalysisRule {
  static const LintCode code = LintCode(
    'avoid_unmirrored_icons',
    'This icon points the same way in right-to-left layouts.',
    correctionMessage: 'Try passing matchTextDirection: true to the Icon.',
  );

  AvoidUnmirroredIcons()
    : super(
        name: 'avoid_unmirrored_icons',
        description: 'Avoid left and right icons that do not flip in RTL.',
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
    if (!_directionalIcon.hasMatch(node.identifier.name)) return;
    final element = node.prefix.element;
    if (element is! ClassElement || !_iconClasses.contains(element.name)) {
      return;
    }
    final uri = element.library.uri.toString();
    if (!uri.startsWith('package:flutter/')) return;
    if (_isMatchingTextDirection(node)) return;
    rule.reportAtNode(node);
  }

  /// True when the icon is the first argument of an `Icon` that sets
  /// `matchTextDirection: true`.
  bool _isMatchingTextDirection(PrefixedIdentifier node) {
    final list = node.parent;
    if (list is! ArgumentList || list.arguments.first != node) return false;
    final call = list.parent;
    final name = switch (call) {
      InstanceCreationExpression() => call.constructorName.type.name.lexeme,
      MethodInvocation() => call.methodName.name,
      _ => null,
    };
    if (name != 'Icon') return false;
    for (final arg in list.arguments) {
      if (arg is NamedArgument && arg.name.lexeme == 'matchTextDirection') {
        final value = arg.argumentExpression;
        return value is BooleanLiteral && value.value;
      }
    }
    return false;
  }
}
