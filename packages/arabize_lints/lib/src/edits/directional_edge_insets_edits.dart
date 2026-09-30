import 'package:analyzer/dart/ast/ast.dart';

/// A single text replacement in a source file.
typedef Replacement = ({int offset, int length, String text});

/// Returns the replacements that turn an `EdgeInsets.only` or
/// `EdgeInsets.fromLTRB` call into its `EdgeInsetsDirectional` equivalent.
List<Replacement> directionalEdgeInsetsReplacements(
  InstanceCreationExpression node,
) {
  final constructor = node.constructorName;
  final type = constructor.type.name;
  final replacements = <Replacement>[
    (offset: type.offset, length: type.length, text: 'EdgeInsetsDirectional'),
  ];

  final name = constructor.name;
  if (name != null && name.name == 'fromLTRB') {
    replacements.add((
      offset: name.offset,
      length: name.length,
      text: 'fromSTEB',
    ));
  }

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
