import 'package:analyzer/dart/ast/ast.dart';

import 'directional_edge_insets_edits.dart';

/// Argument labels of `BorderRadius.only` and `BorderRadius.horizontal` that
/// have a directional name.
const directionalBorderRadiusLabels = {
  'topLeft': 'topStart',
  'topRight': 'topEnd',
  'bottomLeft': 'bottomStart',
  'bottomRight': 'bottomEnd',
  'left': 'start',
  'right': 'end',
};

/// Argument labels of `Border` that have a directional name.
const directionalBorderLabels = {'left': 'start', 'right': 'end'};

/// Whether [node] passes one of the labels in [labels] as a named argument.
bool usesLabels(InstanceCreationExpression node, Iterable<String> labels) {
  return node.argumentList.arguments.any(
    (a) => a is NamedArgument && labels.contains(a.name.lexeme),
  );
}

/// Returns the replacements that turn a `BorderRadius.only` or
/// `BorderRadius.horizontal` call into `BorderRadiusDirectional`.
List<Replacement> directionalBorderRadiusReplacements(
  InstanceCreationExpression node,
) => _replacements(
  node,
  'BorderRadiusDirectional',
  directionalBorderRadiusLabels,
);

/// Returns the replacements that turn a `Border` call with left or right into
/// `BorderDirectional`.
List<Replacement> directionalBorderReplacements(
  InstanceCreationExpression node,
) => _replacements(node, 'BorderDirectional', directionalBorderLabels);

List<Replacement> _replacements(
  InstanceCreationExpression node,
  String typeName,
  Map<String, String> labels,
) {
  final type = node.constructorName.type.name;
  final replacements = <Replacement>[
    (offset: type.offset, length: type.length, text: typeName),
  ];
  for (final argument in node.argumentList.arguments) {
    if (argument is! NamedArgument) continue;
    final label = argument.name;
    final text = labels[label.lexeme];
    if (text != null) {
      replacements.add((
        offset: label.offset,
        length: label.length,
        text: text,
      ));
    }
  }
  return replacements;
}
