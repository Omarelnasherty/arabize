import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'guards.dart';

/// Widgets whose first positional argument is shown to the user.
const _textWidgets = {'Text', 'SelectableText'};

/// Named arguments that hold user-facing text.
const _textArguments = {
  'hintText',
  'labelText',
  'helperText',
  'errorText',
  'counterText',
  'prefixText',
  'suffixText',
  'tooltip',
  'semanticLabel',
  'semanticsLabel',
};

/// A hardcoded user-facing string found in a source file.
class ExtractedString {
  final String file;
  final int line;
  final int column;

  /// The widget or argument the string is passed to, such as `Text`.
  final String context;

  /// The string value. Interpolations are kept as written, for example
  /// `Hello $name`.
  final String text;

  const ExtractedString({
    required this.file,
    required this.line,
    required this.column,
    required this.context,
    required this.text,
  });

  Map<String, Object> toJson() => {
    'file': file,
    'line': line,
    'column': column,
    'context': context,
    'text': text,
  };
}

/// Finds the hardcoded user-facing strings in [source].
///
/// Strings without a letter, such as `'/'` or `'12'`, are ignored.
List<ExtractedString> findStrings(String source, {String file = ''}) {
  final result = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _StringVisitor(file, result.lineInfo);
  result.unit.accept(visitor);
  return visitor.found;
}

class _StringVisitor extends RecursiveAstVisitor<void> {
  final String file;
  final LineInfo lineInfo;
  final found = <ExtractedString>[];

  _StringVisitor(this.file, this.lineInfo);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _visitCall(node.constructorName.type.name.lexeme, node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  // Without type resolution, `Text('a')` parses as a method call.
  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) {
      _visitCall(node.methodName.name, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  void _visitCall(String name, ArgumentList arguments) {
    var positional = true;
    for (final argument in arguments.arguments) {
      final label = _labelOf(argument);
      final value = _valueOf(argument, label != null);
      if (value == null) continue;
      if (label == null) {
        if (positional && _textWidgets.contains(name)) _add(name, value);
        positional = false;
      } else if (_textArguments.contains(label) ||
          (label == 'message' && name == 'Tooltip')) {
        _add(label, value);
      }
    }
  }

  void _add(String context, Expression expression) {
    if (expression is! StringLiteral) return;
    final text = _textOf(expression);
    if (!_hasLetter(text)) return;
    final location = lineInfo.getLocation(expression.offset);
    found.add(
      ExtractedString(
        file: file,
        line: location.lineNumber,
        column: location.columnNumber,
        context: context,
        text: text,
      ),
    );
  }
}

String _textOf(StringLiteral literal) {
  if (literal is SimpleStringLiteral) return literal.value;
  if (literal is AdjacentStrings) return literal.strings.map(_textOf).join();
  if (literal is StringInterpolation) {
    final buffer = StringBuffer();
    for (final element in literal.elements) {
      if (element is InterpolationString) {
        buffer.write(element.value);
      } else if (element is InterpolationExpression) {
        final inner = element.expression;
        buffer.write(
          inner is SimpleIdentifier
              ? '\$${inner.name}'
              : '\${${inner.toSource()}}',
        );
      }
    }
    return buffer.toString();
  }
  return '';
}

final _letter = RegExp(r'\p{L}', unicode: true);

bool _hasLetter(String text) => _letter.hasMatch(text);

/// Lists the Dart files under [path], skipping hidden folders, build output
/// and generated files.
List<File> dartFiles(String path) {
  if (FileSystemEntity.isFileSync(path)) return [File(path)];
  final files = <File>[];
  for (final entity in Directory(path).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final parts = p.split(p.relative(entity.path, from: path));
    if (parts.any((s) => s.startsWith('.') || s == 'build')) continue;
    if (isGeneratedFile(entity.path)) continue;
    files.add(entity);
  }
  return files..sort((a, b) => a.path.compareTo(b.path));
}

/// Implements `arabize extract [path] [--format text|json]`.
///
/// Prints the hardcoded strings under `lib` in [path] (or [path] itself when
/// it is a file). Returns 0, or 64 on bad arguments.
Future<int> runExtract(List<String> args, void Function(String) out) async {
  var path = '.';
  var format = 'text';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--format' && i + 1 < args.length) {
      format = args[++i];
    } else if (arg.startsWith('--format=')) {
      format = arg.substring('--format='.length);
    } else if (!arg.startsWith('-')) {
      path = arg;
    } else {
      out('Unknown option: $arg');
      return 64;
    }
  }
  if (format != 'text' && format != 'json') {
    out('Unknown format: $format (use text or json)');
    return 64;
  }

  final lib = p.join(path, 'lib');
  final root = Directory(lib).existsSync() ? lib : path;
  final strings = <ExtractedString>[];
  for (final file in dartFiles(root)) {
    strings.addAll(findStrings(file.readAsStringSync(), file: file.path));
  }

  if (format == 'json') {
    out(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'strings': strings.map((s) => s.toJson()).toList()}),
    );
  } else {
    for (final s in strings) {
      out(
        '${p.relative(s.file)}:${s.line}:${s.column}  ${s.context}  '
        '${jsonEncode(s.text)}',
      );
    }
    out(
      strings.isEmpty
          ? 'No hardcoded strings found.'
          : '${strings.length} string${strings.length == 1 ? '' : 's'} found.',
    );
  }
  return 0;
}

// Argument node types differ between analyzer 13 and 14, so these helpers
// only rely on the source text and the child expressions.
final _namedArgument = RegExp(r'^(\w+)\s*:');

String? _labelOf(AstNode argument) =>
    _namedArgument.firstMatch(argument.toSource())?.group(1);

Expression? _valueOf(AstNode argument, bool named) =>
    !named && argument is Expression
    ? argument
    : argument.childEntities.whereType<Expression>().lastOrNull;
