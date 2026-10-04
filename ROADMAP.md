# Roadmap

One small step at a time. Checked items are done.

## 0.1 Lints
- [x] Workspace setup: pub workspace, the four packages as empty skeletons, example app, CI (format, analyze, test), README, .gitignore
- [x] Plugin skeleton and `prefer_directional_edge_insets` rule (EdgeInsets.only with left/right, EdgeInsets.fromLTRB)
- [x] Quick fix for `prefer_directional_edge_insets`
- [x] `prefer_directional_alignment` rule and fix (Alignment.centerLeft -> AlignmentDirectional.centerStart, etc.)
- [x] `prefer_positioned_directional` rule and fix
- [x] `prefer_text_align_start_end` rule and fix (TextAlign.left/right)
- [x] `avoid_hardcoded_text_direction` rule
- [ ] `prefer_directional_border_radius` and `prefer_directional_border` rules and fixes
- [ ] `avoid_unmirrored_icons` rule (chevron_left, keyboard_arrow_right, and similar icons that don't flip in RTL)
- [ ] Example app that triggers every rule, usage section in README
- [ ] Prepare 0.1.0

## 0.2 CLI
- [ ] `arabize check`: run all rules on a project, text and JSON output, non-zero exit code for CI
- [ ] `arabize fix`: apply all fixes, `--dry-run` prints a diff
- [ ] Edge cases: const contexts, imports, skip generated files
- [ ] Prepare 0.2.0

## 0.3 Strings
- [ ] `arabize extract`: find hardcoded user-facing strings (Text, hintText, labelText, tooltip, SnackBar content, ...)
- [ ] Generate ARB keys and merge them into the existing app_en.arb
- [ ] Replace strings in code with l10n getters, turn interpolation into placeholders
- [ ] `arabize l10n-check`: missing keys, unused keys, placeholder mismatches
- [ ] Prepare 0.3.0

## 0.4 Translation
- [ ] `arabize translate`: provider interface with OpenAI, Gemini and Anthropic providers, API key from env
- [ ] Keep ICU placeholders, plurals and select intact; validate output and retry on mismatch
- [ ] `arabize.yaml`: glossary, do-not-translate list, tone (MSA or Egyptian)
- [ ] Translate only new or changed keys
- [ ] Prepare 0.4.0

## 0.5 Tests and text utils
- [ ] `arabize_test`: `testWidgetsBothDirections` and `pumpRtl`
- [ ] RTL golden tests with a bundled Arabic font
- [ ] `arabize`: `normalizeArabic` for search (tashkeel, tatweel, alef/ya/ta marbuta)
- [ ] `arabize`: Arabic-Indic and Western digits conversion
- [ ] Final README pass
- [ ] Prepare 1.0.0

## Later
- Hijri dates
- `dart fix` support if plugin fixes become available there
