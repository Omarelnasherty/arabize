import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';

/// A text replacement inside a snippet of source code.
typedef Edit = ({int offset, int length, String text});

const _sides = {'left': 'start', 'right': 'end'};

const _radiusLabels = {
  'topLeft': 'topStart',
  'topRight': 'topEnd',
  'bottomLeft': 'bottomStart',
  'bottomRight': 'bottomEnd',
  ..._sides,
};

const _alignments = {
  'topLeft': 'topStart',
  'centerLeft': 'centerStart',
  'bottomLeft': 'bottomStart',
  'topRight': 'topEnd',
  'centerRight': 'centerEnd',
  'bottomRight': 'bottomEnd',
};

/// Rules that [rewriteSnippet] knows how to fix.
const fixableRules = {
  'prefer_directional_edge_insets',
  'prefer_directional_alignment',
  'prefer_positioned_directional',
  'prefer_text_align_start_end',
  'prefer_directional_border_radius',
  'prefer_directional_border',
};

const _prefix = 'final _ = ';

/// Returns the edits that fix [rule] in [snippet], the code the rule flagged.
///
/// The snippet is parsed without type information, so a call such as
/// `EdgeInsets.only(...)` is read as a method call or as a constructor call,
/// depending on the keywords around it. Both are handled.
List<Edit> rewriteSnippet(String rule, String snippet) {
  final unit = parseString(
    content: '$_prefix$snippet;',
    throwIfDiagnostics: false,
  ).unit;
  if (unit.declarations.isEmpty) return const [];
  final declaration = unit.declarations.first;
  if (declaration is! TopLevelVariableDeclaration) return const [];
  final expression = declaration.variables.variables.first.initializer;

  final edits = switch (rule) {
    'prefer_directional_edge_insets' => _call(
      expression,
      'EdgeInsetsDirectional',
      _sides,
      constructors: const {'fromLTRB': 'fromSTEB'},
    ),
    'prefer_positioned_directional' => _call(
      expression,
      'PositionedDirectional',
      _sides,
    ),
    'prefer_directional_border_radius' => _call(
      expression,
      'BorderRadiusDirectional',
      _radiusLabels,
    ),
    'prefer_directional_border' => _call(
      expression,
      'BorderDirectional',
      _sides,
    ),
    'prefer_directional_alignment' => _member(
      expression,
      _alignments,
      type: 'AlignmentDirectional',
    ),
    'prefer_text_align_start_end' => _member(expression, _sides),
    _ => const <Edit>[],
  };
  return [
    for (final e in edits)
      (offset: e.offset - _prefix.length, length: e.length, text: e.text),
  ];
}

Edit _replace(SyntacticEntity entity, String text) =>
    (offset: entity.offset, length: entity.length, text: text);

List<Edit> _member(
  Expression? node,
  Map<String, String> names, {
  String? type,
}) {
  if (node is! PrefixedIdentifier) return const [];
  final member = names[node.identifier.name];
  if (member == null) return const [];
  return [
    if (type != null) _replace(node.prefix, type),
    _replace(node.identifier, member),
  ];
}

List<Edit> _call(
  Expression? node,
  String typeName,
  Map<String, String> labels, {
  Map<String, String> constructors = const {},
}) {
  final Token typeToken;
  final Token? constructorToken;
  final ArgumentList arguments;
  if (node is InstanceCreationExpression) {
    final type = node.constructorName.type;
    final prefix = type.importPrefix;
    final name = node.constructorName.name;
    if (prefix != null && name == null) {
      // Without type information `EdgeInsets.only` reads as a prefixed type.
      typeToken = prefix.name;
      constructorToken = type.name;
    } else {
      typeToken = type.name;
      constructorToken = name?.token;
    }
    arguments = node.argumentList;
  } else if (node is MethodInvocation) {
    final target = node.target;
    if (target is SimpleIdentifier) {
      typeToken = target.token;
      constructorToken = node.methodName.token;
    } else if (target == null) {
      typeToken = node.methodName.token;
      constructorToken = null;
    } else {
      return const [];
    }
    arguments = node.argumentList;
  } else {
    return const [];
  }

  final edits = <Edit>[_replace(typeToken, typeName)];
  final constructor = constructors[constructorToken?.lexeme];
  if (constructor != null) edits.add(_replace(constructorToken!, constructor));
  for (final argument in arguments.arguments) {
    if (argument is! NamedArgument) continue;
    final text = labels[argument.name.lexeme];
    if (text != null) edits.add(_replace(argument.name, text));
  }
  return edits;
}
