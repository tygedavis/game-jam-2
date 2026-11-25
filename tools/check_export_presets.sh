#!/usr/bin/env bash
# Fails if export_presets.cfg contains secrets or absolute local paths.
# Secrets belong in GitHub Actions secrets, and paths must stay relative.
# Usage: tools/check_export_presets.sh [file]   (default: export_presets.cfg)
set -u
file="${1:-export_presets.cfg}"
[ -f "$file" ] || { echo "check_export_presets: $file not found" >&2; exit 2; }

fail=0
report() { echo "::error file=$file::$1"; echo "  $2"; fail=1; }

# Keys that hold secrets must be empty.
while IFS= read -r line; do
  report "Secret value committed in $file" "$line"
done < <(grep -nE '^(script_encryption_key|keystore/[a-z_]*(password|pass)|keystore/release_user|apk_expansion_salt|codesign/[a-z_]*password|application/[a-z_]*password)[[:space:]]*=[[:space:]]*"[^"]+"' "$file" \
  | sed -E 's/(=[[:space:]]*").*/\1<redacted>"/')

# Absolute local paths.
while IFS= read -r line; do
  report "Absolute local path in $file (keep paths relative)" "$line"
done < <(grep -nE '"(/home/|/Users/|/root/|[A-Za-z]:[\\/])' "$file")

[ "$fail" -eq 0 ] && echo "check_export_presets: OK"
exit "$fail"
