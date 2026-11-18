#!/usr/bin/env bash
# Exports the game with Godot.
# Usage: tools/build.sh [--production] [--pack FILE] [--dry-run] <preset name>
#   --production  leave the developer-mode code out of the export: exports from a temporary copy of
#                 export_presets.cfg that adds the "production" feature tag and excludes
#                 scripts/dev/ in every preset. The committed file is never changed.
#   --pack FILE   export just a .pck to FILE (needs no export templates), instead of the full build
#   --dry-run     print the presets that would be used and exit without exporting
# Env: GODOT is the Godot binary (default: godot).
set -euo pipefail

usage() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }

production=0; pack=""; dry=0
while [ $# -gt 0 ]; do
	case "$1" in
		--production) production=1; shift ;;
		--pack) [ $# -ge 2 ] || usage; pack="$2"; shift 2 ;;
		--dry-run) dry=1; shift ;;
		-h|--help) usage ;;
		-*) echo "unknown option: $1" >&2; usage ;;
		*) break ;;
	esac
done
[ $# -eq 1 ] || usage
preset="$1"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
godot="${GODOT:-godot}"

# The presets file to use, rewritten for a production build.
rewrite() {
	if [ "$production" -eq 0 ]; then cat export_presets.cfg; return; fi
	awk '
		function inner(line, key) { sub("^" key "=\"", "", line); sub("\"$", "", line); return line }
		/^custom_features="/ { v = inner($0, "custom_features"); print "custom_features=\"" (v == "" ? "production" : v ",production") "\""; next }
		/^exclude_filter="/ { v = inner($0, "exclude_filter"); print "exclude_filter=\"" (v == "" ? "scripts/dev/*" : v ", scripts/dev/*") "\""; next }
		{ print }' export_presets.cfg
}

if [ "$dry" -eq 1 ]; then rewrite; exit 0; fi

if ! grep -q "^name=\"$preset\"\$" export_presets.cfg; then
	echo "no export preset named \"$preset\"" >&2; exit 2
fi

if [ "$production" -eq 1 ]; then
	backup="$(mktemp)"
	cp export_presets.cfg "$backup"
	trap 'cp "$backup" export_presets.cfg; rm -f "$backup"' EXIT
	rewrite > "$backup.new"; cp "$backup.new" export_presets.cfg; rm -f "$backup.new"
fi

if [ -n "$pack" ]; then
	mkdir -p "$(dirname "$pack")"
	"$godot" --headless --path . --export-pack "$preset" "$pack"
else
	# Make sure the preset's output folder exists.
	out="$(awk -v p="$preset" '/^name="/ { on = ($0 == "name=\"" p "\"") } on && /^export_path="/ { sub(/^export_path="/, ""); sub(/"$/, ""); print; exit }' export_presets.cfg)"
	[ -z "$out" ] || mkdir -p "$(dirname "$out")"
	"$godot" --headless --path . --export-release "$preset"
fi
