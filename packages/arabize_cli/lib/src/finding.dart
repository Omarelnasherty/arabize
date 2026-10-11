import 'dart:convert';

/// The lint rules arabize reports.
const Set<String> arabizeRules = {
  'prefer_directional_edge_insets',
  'prefer_directional_alignment',
  'prefer_positioned_directional',
  'prefer_text_align_start_end',
  'avoid_hardcoded_text_direction',
  'prefer_directional_border_radius',
  'prefer_directional_border',
  'avoid_unmirrored_icons',
};

/// One rule violation found in a source file.
class Finding {
  final String rule;
  final String file;
  final int line;
  final int column;

  /// Start of the flagged code, in UTF-16 units from the file start.
  final int offset;

  /// Length of the flagged code.
  final int length;
  final String message;

  const Finding({
    required this.rule,
    required this.file,
    required this.line,
    required this.column,
    this.offset = 0,
    this.length = 0,
    required this.message,
  });

  Map<String, Object> toJson() => {
    'rule': rule,
    'file': file,
    'line': line,
    'column': column,
    'message': message,
  };
}

/// Extracts arabize findings from the output of `dart analyze --format=json`.
///
/// Throws a [FormatException] if [output] has no JSON document.
List<Finding> parseAnalyzeOutput(String output) {
  final start = output.indexOf('{');
  if (start < 0) throw const FormatException('No JSON in analyzer output');
  final decoded = jsonDecode(output.substring(start)) as Map<String, Object?>;
  final diagnostics = (decoded['diagnostics'] as List<Object?>? ?? const []);

  final findings = <Finding>[];
  for (final item in diagnostics.cast<Map<String, Object?>>()) {
    final code = item['code'] as String?;
    if (code == null || !arabizeRules.contains(code)) continue;
    final location = item['location'] as Map<String, Object?>;
    final range = location['range'] as Map<String, Object?>;
    final start = range['start'] as Map<String, Object?>;
    final end = range['end'] as Map<String, Object?>;
    final startOffset = start['offset'] as int;
    findings.add(
      Finding(
        rule: code,
        file: location['file'] as String,
        line: start['line'] as int,
        column: start['column'] as int,
        offset: startOffset,
        length: (end['offset'] as int) - startOffset,
        message: item['problemMessage'] as String,
      ),
    );
  }
  findings.sort((a, b) {
    final byFile = a.file.compareTo(b.file);
    return byFile != 0 ? byFile : a.line.compareTo(b.line);
  });
  return findings;
}
