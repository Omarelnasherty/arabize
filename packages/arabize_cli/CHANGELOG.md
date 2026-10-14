# Changelog

## Unreleased

- Add `arabize extract` to list hardcoded user-facing strings. Requires analyzer 14.5 or newer.

## 0.2.0

- Add `arabize check` with text and JSON output and a non-zero exit code.
- Add `arabize fix` with `--dry-run`.
- `check` and `fix` skip generated files. `fix` leaves code assigned to a concrete type such as `EdgeInsets` and updates `show` clauses on Flutter imports.
