#!/usr/bin/env bash
# Regenerate the localization codegen artifacts after editing
# `assets/translations/*.json`. Run from the repo root.
#
# Produces two files under `lib/generated/`:
#
#   1. `locale_keys.g.dart`     — type-safe key constants:
#                                 `LocaleKeys.settings_locale_title.tr()`
#   2. `codegen_loader.g.dart`  — `CodegenLoader` that embeds the JSON
#                                 catalogs into the Dart bundle, removing
#                                 a runtime `rootBundle` read at first
#                                 frame. Wired into `EasyLocalization` in
#                                 `lib/main.dart` via `assetLoader:`.
#
# Both files are committed (not gitignored) so devs can edit Dart code
# referencing new keys without running this script first. Re-run after:
#   • adding / removing keys
#   • adding a new supported locale (and registering it in main.dart)

set -euo pipefail

SRC="assets/translations"
OUT="lib/generated"

mkdir -p "$OUT"

dart run easy_localization:generate \
  --source-dir "$SRC" \
  --output-dir "$OUT" \
  --output-file codegen_loader.g.dart

dart run easy_localization:generate \
  --source-dir "$SRC" \
  --output-dir "$OUT" \
  --output-file locale_keys.g.dart \
  --format keys

echo "✓ Regenerated $OUT/locale_keys.g.dart + $OUT/codegen_loader.g.dart"
