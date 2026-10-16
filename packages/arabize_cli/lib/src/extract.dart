import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

import 'arb.dart';
import 'guards.dart';
import 'l10n_config.dart';
import 'replace.dart';

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

  /// Offset of the string literal in the source.
  final int offset;

  /// Length of the string literal in the source.
  final int length;

  const ExtractedString({
    required this.file,
    required this.line,
    required this.column,
    required this.context,
    required this.text,
    this.offset = 0,
    this.length = 0,
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
List<ExtractedString> findStrings(String source, {String file = ''}) => [
  for (final f in parseLiterals(source, file: file).literals) f.string,
];

/// A string found in a source file together with its syntax node.
typedef FoundLiteral = ({ExtractedString string, StringLiteral node});

/// Parses [source] and returns the unit with the user-facing string literals.
({CompilationUnit unit, List<FoundLiteral> literals}) parseLiterals(
  String source, {
  String file = '',
}) {
  final result = parseString(content: source, throwIfDiagnostics: false);
  final visitor = _StringVisitor(file, result.lineInfo);
  result.unit.accept(visitor);
  return (unit: result.unit, literals: visitor.found);
}

class _StringVisitor extends RecursiveAstVisitor<void> {
  final String file;
  final LineInfo lineInfo;
  final found = <FoundLiteral>[];

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
    found.add((
      string: ExtractedString(
        file: file,
        line: location.lineNumber,
        column: location.columnNumber,
        context: context,
        text: text,
        offset: expression.offset,
        length: expression.length,
      ),
      node: expression,
    ));
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

/// Finds the template ARB file of the project at [path].
///
/// Reads `arb-dir` and `template-arb-file` from `l10n.yaml` when present and
/// falls back to `lib/l10n/app_en.arb`.
String arbPathFor(String path) {
  final config = L10nConfig.read(path);
  return p.join(path, config.arbDir, config.template);
}

/// Implements `arabize extract [path] [--format text|json] [--write] [--replace]`.
///
/// Prints the hardcoded strings under `lib` in [path] (or [path] itself when
/// it is a file). With `--write` the strings are also merged into the
/// template ARB file, and with `--replace` the strings in the code are
/// replaced with the generated getters. Returns 0, or 64 on bad arguments.
Future<int> runExtract(List<String> args, void Function(String) out) async {
  var path = '.';
  var format = 'text';
  var write = false;
  var replace = false;
  String? arbOption;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--write') {
      write = true;
    } else if (arg == '--replace') {
      replace = true;
      write = true;
    } else if (arg == '--arb' && i + 1 < args.length) {
      arbOption = args[++i];
    } else if (arg.startsWith('--arb=')) {
      arbOption = arg.substring('--arb='.length);
    } else if (arg == '--format' && i + 1 < args.length) {
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
  final config = L10nConfig.read(path);
  String? importUri;
  if (replace) {
    importUri = _importUri(path, config);
    if (importUri == null) {
      out(
        '--replace needs a Flutter project with a pubspec.yaml and the '
        'generated localizations under lib.',
      );
      return 64;
    }
  }
  final strings = <ExtractedString>[];
  final files = dartFiles(root);
  for (final file in files) {
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

  if (write && strings.isNotEmpty) {
    final arbFile = File(arbOption ?? arbPathFor(path));
    final merged = mergeArb(
      arbFile.existsSync() ? arbFile.readAsStringSync() : null,
      strings,
    );
    arbFile.parent.createSync(recursive: true);
    arbFile.writeAsStringSync(merged.content);
    out(
      'Added ${merged.added.length} '
      'key${merged.added.length == 1 ? '' : 's'} to ${p.relative(arbFile.path)}.',
    );
    if (replace) {
      var replaced = 0;
      for (final file in files) {
        if (p
            .basename(file.path)
            .startsWith(p.basenameWithoutExtension(config.outputFile))) {
          continue;
        }
        final result = replaceStrings(
          file.readAsStringSync(),
          keys: merged.keys,
          config: config,
          importUri: importUri!,
          file: file.path,
        );
        if (result.replaced > 0) file.writeAsStringSync(result.source);
        replaced += result.replaced;
        for (final s in result.skipped) {
          out(
            '${p.relative(s.file)}:${s.line}:${s.column}  skipped '
            '(no context in scope, const, or complex interpolation)',
          );
        }
      }
      out('Replaced $replaced string${replaced == 1 ? '' : 's'}.');
    }
  }
  return 0;
}

/// The import for the generated localizations class, or null when it cannot
/// be written as a package import.
String? _importUri(String path, L10nConfig config) {
  final pubspec = File(p.join(path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return null;
  final name = RegExp(
    r'^name:\s*(\w+)',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync())?.group(1);
  final dir = p.posix.normalize(config.arbDir);
  if (name == null || !p.posix.isWithin('lib', dir)) return null;
  return 'package:$name/${p.posix.relative(dir, from: 'lib')}/'
      '${config.outputFile}';
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
