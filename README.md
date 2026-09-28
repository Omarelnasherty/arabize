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
