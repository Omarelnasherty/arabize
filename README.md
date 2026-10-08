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
