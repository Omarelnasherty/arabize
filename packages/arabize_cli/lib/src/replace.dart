import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'arb.dart';
import 'extract.dart';
import 'l10n_config.dart';

/// The outcome of [replaceStrings] for one file.
class ReplaceResult {
  final String source;
  final int replaced;

  /// Strings that were left as they are.
  final List<ExtractedString> skipped;

  const ReplaceResult(this.source, this.replaced, this.skipped);
}

typedef _Edit = ({int offset, int end, String text});

/// Replaces the strings in [source] with getters of the generated
/// localizations class.
///
/// [keys] maps ICU messages to ARB keys, as returned by [mergeArb]. A string
/// is skipped when no `context` variable is in scope, when it sits in a
/// constant that cannot be made non-const, or when its interpolations cannot
/// be mapped to placeholders. Enclosing `const` keywords are removed.
/// [importUri] is added as an import when something was replaced.
ReplaceResult replaceStrings(
  String source, {
  required Map<String, String> keys,
  required L10nConfig config,
  required String importUri,
  String file = '',
}) {
  final parsed = parseLiterals(source, file: file);
  final edits = <_Edit>[];
  final constOffsets = <int>{};
  final skipped = <ExtractedString>[];
  var replaced = 0;

  for (final (:string, :node) in parsed.literals) {
    final icu = toIcu(string.text);
    final key = keys[icu.message];
    final constKeywords = _constKeywords(node);
    final sameExpressions = _sameList(
      _expressionsOf(node).toSet().toList(),
      icu.expressions,
    );
    if (key == null ||
        constKeywords == null ||
        !sameExpressions ||
        !_hasContext(node)) {
      skipped.add(string);
      continue;
    }
    for (final keyword in constKeywords) {
      if (constOffsets.add(keyword.offset)) {
        edits.add((
          offset: keyword.offset,
          end: keyword.next!.offset,
          text: '',
        ));
      }
    }
    final bang = config.nullableGetter ? '!' : '';
    final args = icu.placeholders.isEmpty
        ? ''
        : '(${icu.expressions.join(', ')})';
    edits.add((
      offset: node.offset,
      end: node.end,
      text: '${config.outputClass}.of(context)$bang.$key$args',
    ));
    replaced++;
  }
  if (replaced == 0) return ReplaceResult(source, 0, skipped);

  final hasImport = parsed.unit.directives.whereType<ImportDirective>().any(
    (d) => (d.uri.stringValue ?? '').endsWith(config.outputFile),
  );
  if (!hasImport) {
    final last = parsed.unit.directives.lastOrNull;
    edits.add(
      last == null
          ? (offset: 0, end: 0, text: "import '$importUri';\n\n")
          : (offset: last.end, end: last.end, text: "\nimport '$importUri';"),
    );
  }

  edits.sort((a, b) => b.offset.compareTo(a.offset));
  var result = source;
  for (final e in edits) {
    result = result.replaceRange(e.offset, e.end, e.text);
  }
  return ReplaceResult(result, replaced, skipped);
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The source of each interpolated expression, in order.
List<String> _expressionsOf(StringLiteral literal) {
  if (literal is AdjacentStrings) {
    return [for (final s in literal.strings) ..._expressionsOf(s)];
  }
  if (literal is StringInterpolation) {
    return [
      for (final e in literal.elements)
        if (e is InterpolationExpression) e.expression.toSource(),
    ];
  }
  return const [];
}

bool _hasContext(AstNode node) {
  for (AstNode? n = node.parent; n != null; n = n.parent) {
    final parameters = switch (n) {
      FunctionExpression() => n.parameters,
      MethodDeclaration() => n.parameters,
      _ => null,
    };
    if (parameters == null) continue;
    for (final parameter in parameters.parameters) {
      if (parameter.name?.lexeme == 'context') return true;
    }
  }
  return false;
}

/// The `const` keywords around [node] that have to go, or null when the
/// string sits in a constant that cannot be changed.
List<Token>? _constKeywords(AstNode node) {
  final keywords = <Token>[];
  for (
    AstNode? n = node.parent;
    n != null && n is! FunctionBody;
    n = n.parent
  ) {
    if (n is InstanceCreationExpression) {
      final keyword = n.keyword;
      if (keyword != null && keyword.type == Keyword.CONST) {
        keywords.add(keyword);
      }
    } else if (n is TypedLiteral && n.constKeyword != null) {
      return null;
    } else if (n is VariableDeclarationList && n.isConst) {
      return null;
    }
  }
  return keywords;
}
