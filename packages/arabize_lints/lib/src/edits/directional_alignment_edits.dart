import 'package:analyzer/dart/ast/ast.dart';

import 'directional_edge_insets_edits.dart';

/// The `AlignmentDirectional` member for each left or right `Alignment`.
const directionalAlignmentNames = {
  'topLeft': 'topStart',
  'centerLeft': 'centerStart',
  'bottomLeft': 'bottomStart',
  'topRight': 'topEnd',
  'centerRight': 'centerEnd',
  'bottomRight': 'bottomEnd',
};

/// Returns the replacements that turn `Alignment.centerLeft` and friends into
/// their `AlignmentDirectional` equivalent.
List<Replacement> directionalAlignmentReplacements(PrefixedIdentifier node) {
  final member = directionalAlignmentNames[node.identifier.name];
  if (member == null) return const [];
  return [
    (
      offset: node.prefix.offset,
      length: node.prefix.length,
      text: 'AlignmentDirectional',
    ),
    (
      offset: node.identifier.offset,
      length: node.identifier.length,
      text: member,
    ),
  ];
}
