import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The settings of `arabize.yaml` that guide translation.
class TranslateConfig {
  /// `msa` or `egyptian`. Null leaves the choice to the provider.
  final String? tone;

  /// Fixed translations, keyed by the English term.
  final Map<String, String> glossary;

  /// Terms that must stay as written, such as brand names.
  final List<String> doNotTranslate;

  const TranslateConfig({
    this.tone,
    this.glossary = const {},
    this.doNotTranslate = const [],
  });

  /// Reads `arabize.yaml` in [path]. A missing file gives the defaults.
  factory TranslateConfig.read(String path) {
    final file = File(p.join(path, 'arabize.yaml'));
    if (!file.existsSync()) return const TranslateConfig();
    return TranslateConfig.parse(file.readAsStringSync());
  }

  /// Parses the text of an `arabize.yaml` file.
  ///
  /// Throws a [FormatException] if the tone is unknown or a section has the
  /// wrong shape.
  factory TranslateConfig.parse(String text) {
    final doc = loadYaml(text);
    if (doc == null) return const TranslateConfig();
    if (doc is! Map) throw const FormatException('arabize.yaml must be a map');

    final tone = doc['tone'];
    if (tone != null && tone != 'msa' && tone != 'egyptian') {
      throw FormatException('tone must be msa or egyptian, not $tone');
    }
    final glossary = doc['glossary'];
    if (glossary != null && glossary is! Map) {
      throw const FormatException('glossary must be a map');
    }
    final skip = doc['do-not-translate'];
    if (skip != null && skip is! List) {
      throw const FormatException('do-not-translate must be a list');
    }
    return TranslateConfig(
      tone: tone as String?,
      glossary: {
        if (glossary != null)
          for (final e in (glossary as Map).entries) '${e.key}': '${e.value}',
      },
      doNotTranslate: [
        if (skip != null)
          for (final s in skip as List) '$s',
      ],
    );
  }

  /// The extra instructions to add to the translation prompt.
  String get instructions {
    final lines = <String>[
      if (tone == 'msa')
        'Use Modern Standard Arabic.'
      else if (tone == 'egyptian')
        'Use Egyptian Arabic, the way people talk in Egypt.',
      if (doNotTranslate.isNotEmpty)
        'Never translate these terms: ${doNotTranslate.join(', ')}.',
      if (glossary.isNotEmpty)
        'Always translate these terms as given: '
            '${glossary.entries.map((e) => '"${e.key}" as "${e.value}"').join(', ')}.',
    ];
    return lines.join(' ');
  }
}
