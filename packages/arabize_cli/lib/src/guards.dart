import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'finding.dart';

const _generatedSuffixes = [
  '.g.dart',
  '.freezed.dart',
  '.gr.dart',
  '.gen.dart',
  '.mocks.dart',
  '.config.dart',
];

/// Whether [path] is a generated file that should not be checked or edited.
///
/// Looks at the file name first, then at the first lines for a generated
/// code marker.
bool isGeneratedFile(String path) {
  if (_generatedSuffixes.any(path.endsWith)) return true;
  final file = File(path);
  if (!file.existsSync()) return false;
  final head = file.readAsLinesSync().take(5).join('\n').toLowerCase();
  return head.contains('generated code') || head.contains('@generated');
}

/// Drops the findings that sit in generated files.
List<Finding> withoutGenerated(List<Finding> findings) {
  final cache = <String, bool>{};
  return [
    for (final f in findings)
      if (!cache.putIfAbsent(f.file, () => isGeneratedFile(f.file))) f,
  ];
}

/// The concrete class each fixable rule replaces, and its directional twin.
const _replacements = {
  'prefer_directional_edge_insets': ('EdgeInsets', 'EdgeInsetsDirectional'),
  'prefer_directional_alignment': ('Alignment', 'AlignmentDirectional'),
  'prefer_positioned_directional': ('Positioned', 'PositionedDirectional'),
  'prefer_directional_border_radius': (
    'BorderRadius',
    'BorderRadiusDirectional',
  ),
  'prefer_directional_border': ('Border', 'BorderDirectional'),
};

/// The directional class a fix for [rule] introduces, if any.
String? directionalTypeFor(String rule) => _replacements[rule]?.$2;

/// The class a fix for [rule] replaces, if any.
String? originalTypeFor(String rule) => _replacements[rule]?.$1;

/// Whether the code behind [finding] is assigned to something declared with
/// the concrete type, for example `final EdgeInsets padding = ...`.
///
/// The directional class is not a subtype of the concrete one, so rewriting
/// such code would not compile.
bool isTypedContext(CompilationUnit unit, Finding finding) {
  final original = originalTypeFor(finding.rule);
  if (original == null) return false;
  final finder = _ExpressionFinder(finding.offset, finding.length);
  unit.accept(finder);
  final node = finder.found;
  if (node == null) return false;

  bool declares(TypeAnnotation? type) {
    if (type == null) return false;
    return type.toSource().replaceAll('?', '') == original;
  }

  final parent = node.parent;
  if (parent is VariableDeclaration) {
    final list = parent.parent;
    return list is VariableDeclarationList && declares(list.type);
  }
  if (parent is ExpressionFunctionBody) {
    final function = parent.parent;
    final owner = function is FunctionExpression ? function.parent : function;
    if (owner is MethodDeclaration) return declares(owner.returnType);
    if (owner is FunctionDeclaration) return declares(owner.returnType);
  }
  if (parent is FormalParameterDefaultClause) {
    final parameter = parent.parent;
    return parameter is FormalParameter && declares(parameter.type);
  }
  return false;
}

class _ExpressionFinder extends GeneralizingAstVisitor<void> {
  final int offset;
  final int length;
  Expression? found;

  _ExpressionFinder(this.offset, this.length);

  @override
  void visitExpression(Expression node) {
    if (node.offset == offset && node.length == length) found = node;
    super.visitExpression(node);
  }
}

/// Adds the directional classes in [added] to imports that `show` the
/// concrete ones, so the rewritten code still resolves.
///
/// Returns insertions as `(offset, text)` pairs against [source].
List<({int offset, String text})> importEdits(
  String source,
  Set<String> added,
) {
  if (added.isEmpty) return const [];
  final unit = parseString(content: source, throwIfDiagnostics: false).unit;
  final edits = <({int offset, String text})>[];
  for (final directive in unit.directives.whereType<ImportDirective>()) {
    final uri = directive.uri.stringValue ?? '';
    if (!uri.startsWith('package:flutter/')) continue;
    for (final combinator
        in directive.combinators.whereType<ShowCombinator>()) {
      final shown = {for (final n in combinator.shownNames) n.name};
      final missing = [
        for (final type in added)
          if (!shown.contains(type) && shown.contains(_originalOf(type))) type,
      ]..sort();
      if (missing.isEmpty) continue;
      edits.add((
        offset: combinator.shownNames.last.end,
        text: missing.map((n) => ', $n').join(),
      ));
    }
  }
  return edits;
}

String? _originalOf(String directional) {
  for (final pair in _replacements.values) {
    if (pair.$2 == directional) return pair.$1;
  }
  return null;
}
