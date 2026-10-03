import 'package:analyzer/dart/ast/ast.dart';

import 'directional_edge_insets_edits.dart';

/// The `TextAlign` member that replaces `left` and `right`.
const directionalTextAlignNames = {'left': 'start', 'right': 'end'};

/// Returns the replacement that turns `TextAlign.left` into `TextAlign.start`
/// and `TextAlign.right` into `TextAlign.end`.
List<Replacement> directionalTextAlignReplacements(PrefixedIdentifier node) {
  final member = directionalTextAlignNames[node.identifier.name];
  if (member == null) return const [];
  return [
    (
      offset: node.identifier.offset,
      length: node.identifier.length,
      text: member,
    ),
  ];
}
