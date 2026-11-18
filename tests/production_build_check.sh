#!/usr/bin/env bash
# Checks tools/build.sh --production: the dev code is left out of the export (and is in a normal
# export, so the first check can't pass by accident), the production feature tag is set, usage
# errors fail, and export_presets.cfg is left untouched.
# Uses --export-pack, which needs no export templates and applies the same preset filters.
# Usage: tests/production_build_check.sh      Env: GODOT binary (default godot)
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root" || exit 1
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
fail=0
check() { local name="$1"; shift; if "$@"; then echo "PASS $name"; else echo "FAIL $name"; fail=1; fi; }
before="$(sha256sum export_presets.cfg)"

check "unknown flag fails" bash -c '! bash tools/build.sh --bogus Linux >/dev/null 2>&1'
check "missing preset fails" bash -c '! bash tools/build.sh >/dev/null 2>&1'
check "unknown preset fails" bash -c '! bash tools/build.sh --pack "$0/x.pck" "No Such Preset" >/dev/null 2>&1' "$tmp"

bash tools/build.sh --production --dry-run Linux > "$tmp/prod.cfg" 2>&1
bash tools/build.sh --dry-run Linux > "$tmp/dev.cfg" 2>&1
check "production adds the feature tag to every preset" test "$(grep -c '^custom_features="production"' "$tmp/prod.cfg")" -eq 2
check "production excludes scripts/dev from every preset" test "$(grep -c '^exclude_filter="docs/\*, container/\*, scripts/dev/\*"' "$tmp/prod.cfg")" -eq 2
check "normal build leaves presets as committed" diff -q "$tmp/dev.cfg" export_presets.cfg

bash tools/build.sh --production --pack "$tmp/prod.pck" Linux > "$tmp/prod.log" 2>&1; prod=$?
bash tools/build.sh --pack "$tmp/dev.pck" Linux > "$tmp/dev.log" 2>&1; dev=$?
check "production pack exported" test "$prod" -eq 0 -a -s "$tmp/prod.pck"
check "normal pack exported" test "$dev" -eq 0 -a -s "$tmp/dev.pck"
check "normal pack contains the dev actions" grep -aq "scripts/dev/dev_actions" "$tmp/dev.pck"
check "production pack has no dev actions" bash -c 'test -s "$0" && ! grep -aq "scripts/dev/dev_actions" "$0"' "$tmp/prod.pck"
check "normal pack contains the dev panel" grep -aq "scripts/dev/dev_panel.gd.remap" "$tmp/dev.pck"
check "production pack has no dev panel" bash -c 'test -s "$0" && ! grep -aq "scripts/dev/dev_panel.gd.remap" "$0"' "$tmp/prod.pck"
check "export_presets.cfg left untouched" test "$(sha256sum export_presets.cfg)" = "$before"

[ "$fail" -eq 0 ] && echo "production build check passed" || { echo "production build check FAILED"; sed 's/^/    | /' "$tmp/prod.log" "$tmp/dev.log" | tail -20; }
exit "$fail"
