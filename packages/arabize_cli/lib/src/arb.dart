import 'dart:convert';

import 'extract.dart';

/// An ARB message built from an extracted string.
class ArbEntry {
  final String key;

  /// The message in ICU syntax, for example `Hello {name}`.
  final String message;

  /// Placeholder names in order of appearance.
  final List<String> placeholders;

  const ArbEntry(this.key, this.message, this.placeholders);
}

final _interpolation = RegExp(r'\$\{([^}]*)\}|\$(\w+)');

/// Converts [text], as returned by [findStrings], to an ICU message.
///
/// Interpolations become placeholders named after the last identifier in the
/// expression, so `${items.length}` becomes `{length}`. `expressions` holds
/// the source of each placeholder. Two different expressions with the same
/// name get a numeric suffix.
({String message, List<String> placeholders, List<String> expressions}) toIcu(
  String text,
) {
  final names = <String>[];
  final expressions = <String>[];
  final buffer = StringBuffer();
  var last = 0;
  for (final match in _interpolation.allMatches(text)) {
    buffer.write(_escape(text.substring(last, match.start)));
    last = match.end;
    final expression = (match.group(1) ?? match.group(2)!).trim();
    var index = expressions.indexOf(expression);
    if (index == -1) {
      final base = _placeholderName(expression);
      var name = base;
      for (var i = 2; names.contains(name); i++) {
        name = '$base$i';
      }
      names.add(name);
      expressions.add(expression);
      index = names.length - 1;
    }
    buffer.write('{${names[index]}}');
  }
  buffer.write(_escape(text.substring(last)));
  return (
    message: buffer.toString(),
    placeholders: names,
    expressions: expressions,
  );
}

String _escape(String s) =>
    s.replaceAll("'", "''").replaceAll('{', "'{'").replaceAll('}', "'}'");

String _placeholderName(String expression) {
  final identifiers = RegExp(r'[A-Za-z_]\w*').allMatches(expression);
  var name = identifiers.isEmpty ? 'value' : identifiers.last.group(0)!;
  name = name.replaceAll('_', '');
  if (name.isEmpty) name = 'value';
  return name[0].toLowerCase() + name.substring(1);
}

/// Builds a camelCase key from the first words of [text].
///
/// Returns [fallback] when the text has no ASCII letters, as with Arabic.
String keyFor(String text, {String fallback = 'text'}) {
  final words = RegExp(
    r'[A-Za-z][A-Za-z0-9]*',
  ).allMatches(text.replaceAll(_interpolation, ' ')).map((m) => m.group(0)!);
  final first = words.take(4).toList();
  if (first.isEmpty) return fallback;
  return [
    first.first.toLowerCase(),
    for (final w in first.skip(1))
      w[0].toUpperCase() + w.substring(1).toLowerCase(),
  ].join();
}

/// Merges [strings] into the ARB file content [existing] and returns the new
/// content together with the entries that were added.
///
/// `keys` maps every message of [strings] to its key, new or existing.
///
/// A string whose message already exists keeps its key. New keys that clash
/// with an existing one get a numeric suffix. Existing entries are never
/// changed.
({String content, List<ArbEntry> added, Map<String, String> keys}) mergeArb(
  String? existing,
  List<ExtractedString> strings,
) {
  final arb = existing == null || existing.trim().isEmpty
      ? <String, Object?>{'@@locale': 'en'}
      : Map<String, Object?>.from(jsonDecode(existing) as Map);
  final byMessage = <String, String>{
    for (final e in arb.entries)
      if (!e.key.startsWith('@') && e.value is String) e.value as String: e.key,
  };
  final added = <ArbEntry>[];
  for (final s in strings) {
    final icu = toIcu(s.text);
    if (byMessage.containsKey(icu.message)) continue;
    final base = keyFor(s.text, fallback: keyFor(s.context, fallback: 'text'));
    var key = base;
    for (var i = 2; arb.containsKey(key); i++) {
      key = '$base$i';
    }
    arb[key] = icu.message;
    if (icu.placeholders.isNotEmpty) {
      arb['@$key'] = {
        'placeholders': {
          for (final name in icu.placeholders) name: {'type': 'Object'},
        },
      };
    }
    byMessage[icu.message] = key;
    added.add(ArbEntry(key, icu.message, icu.placeholders));
  }
  return (
    content: '${const JsonEncoder.withIndent('  ').convert(arb)}\n',
    added: added,
    keys: {
      for (final s in strings)
        toIcu(s.text).message: byMessage[toIcu(s.text).message]!,
    },
  );
}
