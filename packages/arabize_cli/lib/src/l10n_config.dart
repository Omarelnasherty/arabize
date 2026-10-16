import 'dart:io';

import 'package:path/path.dart' as p;

/// The settings of `l10n.yaml` that arabize needs.
class L10nConfig {
  final String arbDir;
  final String template;
  final String outputFile;
  final String outputClass;

  /// Whether `AppLocalizations.of(context)` returns a nullable value.
  final bool nullableGetter;

  const L10nConfig({
    this.arbDir = 'lib/l10n',
    this.template = 'app_en.arb',
    this.outputFile = 'app_localizations.dart',
    this.outputClass = 'AppLocalizations',
    this.nullableGetter = true,
  });

  /// Reads `l10n.yaml` in [path], using the defaults for missing keys.
  factory L10nConfig.read(String path) {
    final file = File(p.join(path, 'l10n.yaml'));
    if (!file.existsSync()) return const L10nConfig();
    return L10nConfig.parse(file.readAsStringSync());
  }

  /// Parses the text of an `l10n.yaml` file.
  factory L10nConfig.parse(String yaml) {
    const defaults = L10nConfig();
    return L10nConfig(
      arbDir: _value(yaml, 'arb-dir') ?? defaults.arbDir,
      template: _value(yaml, 'template-arb-file') ?? defaults.template,
      outputFile:
          _value(yaml, 'output-localization-file') ?? defaults.outputFile,
      outputClass: _value(yaml, 'output-class') ?? defaults.outputClass,
      nullableGetter: _value(yaml, 'nullable-getter') != 'false',
    );
  }
}

String? _value(String yaml, String key) {
  final match = RegExp(
    '^$key:'
    r'\s*(.+?)\s*$',
    multiLine: true,
  ).firstMatch(yaml);
  return match?.group(1)?.replaceAll(RegExp(r'''^['"]|['"]$'''), '');
}
