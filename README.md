# arabize

Tools that make Flutter apps ready for Arabic and right-to-left layouts.

```dart
// Before
Padding(padding: EdgeInsets.only(left: 16), child: Text('Hello'))

// After `arabize fix`
Padding(padding: EdgeInsetsDirectional.only(start: 16), child: Text('Hello'))
```

What is in the repo:

- Lint rules with quick fixes for left/right layout code.
- A CLI to check and fix a project, extract hardcoded strings to ARB files, check them and translate them.
- Test helpers that run widget tests and golden tests in both text directions.
- Small text utilities for Arabic search and digits.

## Packages

| Package | Purpose |
| --- | --- |
| `packages/arabize` | Runtime text utilities (pure Dart) |
| `packages/arabize_lints` | Analyzer plugin with the lint rules |
| `packages/arabize_cli` | The `arabize` command |
| `packages/arabize_test` | Flutter test helpers |
| `example` | Example Flutter app |

## Usage

Add the plugin to the `analysis_options.yaml` at the root of your project (or pub workspace):

```yaml
plugins:
  arabize_lints:
    path: packages/arabize_lints
    diagnostics:
      prefer_directional_edge_insets: true
      prefer_directional_alignment: true
      prefer_positioned_directional: true
      prefer_text_align_start_end: true
      avoid_hardcoded_text_direction: true
      prefer_directional_border_radius: true
      prefer_directional_border: true
      avoid_unmirrored_icons: true
```

Then code like this is flagged:

```dart
Padding(
  padding: EdgeInsets.only(left: 16),   // prefer_directional_edge_insets
  child: Text('arabize', textAlign: TextAlign.left), // prefer_text_align_start_end
)
```

Most rules come with a quick fix in the editor. `example/lib/rtl_issues.dart` triggers every rule. Run `flutter analyze` in the repo to see them.

### Command line

`arabize check` runs `dart analyze` and prints only the arabize rules. It exits with 1 when something is found, so it works in CI. The plugin must be enabled as shown above.

```
dart run arabize_cli:arabize check
dart run arabize_cli:arabize check lib --format json
```

`arabize fix` rewrites everything that has a fix. `--dry-run` prints a diff and leaves the files alone. Findings without a fix, like icons that should mirror, are counted but not changed.

```
dart run arabize_cli:arabize fix --dry-run
dart run arabize_cli:arabize fix lib
```

`arabize extract` lists hardcoded strings in `Text`, `hintText`, `labelText`, `tooltip` and similar arguments under `lib`. By default it only reads files. With `--write` the strings are added as keys to `lib/l10n/app_en.arb` (or the template file named in `l10n.yaml`), and existing keys are left alone.

`--replace` also rewrites the code, so `Text('Hello $name')` becomes `Text(AppLocalizations.of(context)!.hello(name))` and the import is added. The class name, the output file and `nullable-getter` come from `l10n.yaml`. Strings are left alone when there is no `context` in scope or they sit in a constant that cannot lose `const`; those are listed in the output.

```
dart run arabize_cli:arabize extract
dart run arabize_cli:arabize extract --format json
dart run arabize_cli:arabize extract --write
dart run arabize_cli:arabize extract --replace
```

`arabize l10n-check` compares the ARB files in the folder from `l10n.yaml`. It reports keys missing from a translation, keys a translation has but the template does not, template keys the code never uses, and messages whose placeholders differ from the template. It exits with 1 when it finds something, so it can run in CI. Use `--format json` for machine output.

`arabize translate` fills the target ARB file with the messages it lacks, using the template file as the source. The key is read from `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` or `GEMINI_API_KEY`; `--provider` picks one when several are set and `--model` overrides the default model. Messages whose English text changed since the last run are translated again; the last translated text is kept in `.arabize_translations.json` next to the ARB files.

```
dart run arabize_cli:arabize l10n-check
dart run arabize_cli:arabize translate --to ar
dart run arabize_cli:arabize translate --to ar --provider openai --model gpt-4.1-mini
```

Put an `arabize.yaml` next to `pubspec.yaml` to set the tone, a glossary and words that must stay untranslated:

```yaml
tone: egyptian # or msa
glossary:
  cart: عربية التسوق
do-not-translate:
  - arabize
```

### Tests

`arabize_test` runs the same widget test in both directions:

```dart
testWidgetsBothDirections('shows the back button', () => const MyPage(),
    (tester, direction) async {
  expect(find.byIcon(Icons.arrow_back), findsOneWidget);
});

testGoldensBothDirections('card', () => const MyCard(), name: 'card');
```

Goldens are written to `goldens/card.ltr.png` and `goldens/card.rtl.png`, rendered with a bundled Arabic font. `pumpRtl(tester, widget)` pumps a single widget in RTL.

### Text utilities

```dart
import 'package:arabize/arabize.dart';

normalizeArabic('إِسْلَامِيَّة'); // اسلاميه
toArabicDigits('2026');          // ٢٠٢٦
toWesternDigits('٢٠٢٦');         // 2026
```

Use `normalizeArabic` on both the query and the searched text.

## Development

```
flutter pub get
dart format .
flutter analyze
dart test packages/arabize packages/arabize_lints packages/arabize_cli
(cd packages/arabize_test && flutter test)
(cd example && flutter test)
```

See [ROADMAP.md](ROADMAP.md) for what is next.

## License

MIT
