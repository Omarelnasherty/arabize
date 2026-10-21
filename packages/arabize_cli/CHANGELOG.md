# Changelog

## Unreleased

- `translate` reads `arabize.yaml` for a tone (`msa` or `egyptian`), a glossary and a do-not-translate list.
- Add `arabize translate` with Anthropic, OpenAI and Gemini providers. It adds the messages a target ARB file lacks. The API key comes from `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` or `GEMINI_API_KEY`.
- `translate` checks that each message keeps its placeholders and plural or select structure, sends failing messages again up to three times and skips the ones that still fail.

## 0.3.0

- Add `arabize extract` to list hardcoded user-facing strings.
- Add `extract --write` to merge the strings into `app_en.arb` with generated keys.
- Add `extract --replace` to swap the strings in code for `AppLocalizations` getters. Interpolations become placeholders of type `Object`.
- Add `arabize l10n-check` to report missing and unused keys and placeholder mismatches in ARB files.

## 0.2.0

- Add `arabize check` with text and JSON output and a non-zero exit code.
- Add `arabize fix` with `--dry-run`.
- `check` and `fix` skip generated files. `fix` leaves code assigned to a concrete type such as `EdgeInsets` and updates `show` clauses on Flutter imports.
