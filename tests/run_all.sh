#!/usr/bin/env bash
# Runs every tests/**/*_test.gd headlessly and fails if any test fails.
# Usage: tests/run_all.sh [tests_dir]   (default: the directory this script lives in)
# Env:   TEST_TIMEOUT seconds per test (default 120), GODOT binary (default godot)
#
# Test contract: a *_test.gd that extends SceneTree, prints PASS/FAIL lines, and calls
# quit(1) on failure. A test fails on a non-zero exit, a timeout, any line starting with
# FAIL, or no PASS line at all (which catches scripts that silently fail to parse).
set -u

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dir="${1:-$root/tests}"
godot="${GODOT:-godot}"
limit="${TEST_TIMEOUT:-120}"
log="$(mktemp)"; trap 'rm -f "$log"' EXIT

mapfile -t files < <(find "$dir" -name '*_test.gd' | sort)
if [ "${#files[@]}" -eq 0 ]; then
	echo "FAIL no *_test.gd files found in $dir"
	exit 1
fi

passed=0; failed=0
for f in "${files[@]}"; do
	timeout "$limit" "$godot" --headless --path "$root" --script "$f" > "$log" 2>&1
	code=$?
	reason=""
	if [ "$code" -eq 124 ]; then reason="timed out after ${limit}s"
	elif [ "$code" -ne 0 ]; then reason="exit code $code"
	elif grep -q '^FAIL' "$log"; then reason="FAIL line"
	elif ! grep -q '^PASS' "$log"; then reason="no PASS lines"
	fi
	if [ -z "$reason" ]; then
		echo "PASS $f"; passed=$((passed+1))
	else
		echo "FAIL $f ($reason)"; sed 's/^/    | /' "$log"; failed=$((failed+1))
	fi
done

echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
