# arabize_cli

Command line tool to check, fix and translate Flutter apps for Arabic and RTL.

```
dart pub global activate arabize_cli

arabize check            # list left/right layout code, exits with 1 for CI
arabize fix --dry-run    # print a diff of the fixes
arabize fix lib          # apply them
```

`check` and `fix` use the rules from [arabize_lints](https://pub.dev/packages/arabize_lints), so enable the plugin in `analysis_options.yaml` first.

## Strings

```
arabize extract              # list hardcoded strings in Text, hintText, tooltip, ...
arabize extract --write      # add them as keys to app_en.arb
arabize extract --replace    # also swap them in code for l10n getters
arabize l10n-check           # missing, unused and mismatched keys
```

Paths and class names come from `l10n.yaml`.

## Translation

```
arabize translate --to ar
arabize translate --to ar --provider openai --model gpt-4.1-mini
```

The API key is read from `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` or `GEMINI_API_KEY`. Only new or changed messages are sent, and placeholders, plurals and select are checked in every answer.

An `arabize.yaml` next to `pubspec.yaml` sets the tone, a glossary and words to keep as they are:

```yaml
tone: egyptian # or msa
glossary:
  cart: عربية التسوق
do-not-translate:
  - arabize
```

`check`, `extract` and `l10n-check` take `--format json`. See the [repository](https://github.com/Omarelnasherty/arabize) for more.
