# arabize

Tools that make Flutter apps ready for Arabic and right-to-left layouts.

Planned:

- Lint rules with quick fixes for left/right layout code, for example `EdgeInsets.only(left: 8)` becomes `EdgeInsetsDirectional.only(start: 8)`.
- A CLI to check and fix a project, extract hardcoded strings to ARB files and translate them.
- Test helpers that run widget tests in both text directions.
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

```
dart run arabize_cli:arabize l10n-check
```

## Development

```
flutter pub get
dart format .
flutter analyze
dart test packages/arabize packages/arabize_lints packages/arabize_cli
flutter test packages/arabize_test/test example/test
```

See [ROADMAP.md](ROADMAP.md) for what is next.

## License

MIT
