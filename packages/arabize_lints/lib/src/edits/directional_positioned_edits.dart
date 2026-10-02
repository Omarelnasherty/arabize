import 'package:analyzer/dart/ast/ast.dart';

import 'directional_edge_insets_edits.dart';

/// Whether [node] is a `Positioned(...)` call that sets `left` or `right`.
bool usesPositionedSides(InstanceCreationExpression node) {
  if (node.constructorName.name != null) return false;
  return node.argumentList.arguments.any(
    (a) =>
        a is NamedArgument &&
        (a.name.lexeme == 'left' || a.name.lexeme == 'right'),
  );
}

/// Returns the replacements that turn a `Positioned` call into
/// `PositionedDirectional`.
List<Replacement> directionalPositionedReplacements(
  InstanceCreationExpression node,
) {
  final type = node.constructorName.type.name;
  final replacements = <Replacement>[
    (offset: type.offset, length: type.length, text: 'PositionedDirectional'),
  ];
  for (final argument in node.argumentList.arguments) {
    if (argument is! NamedArgument) continue;
    final label = argument.name;
    final text = switch (label.lexeme) {
      'left' => 'start',
      'right' => 'end',
      _ => null,
    };
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
