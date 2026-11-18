#!/usr/bin/env bash
# Exercises run_all.sh against fixture tests. Run: bash tests/runner_selftest.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fx="$here/fixtures/runner"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
failed=0

# expect <name> <expected exit> <fixture>...
expect() {
	local name="$1" want="$2"; shift 2
	local d="$tmp/$name"; mkdir -p "$d"
	local f i=0
	for f in "$@"; do i=$((i+1)); cp "$fx/$f.gd.fixture" "$d/${f}_${i}_test.gd"; done
	TEST_TIMEOUT=5 bash "$here/run_all.sh" "$d" > "$d.log" 2>&1
	local got=$?
	if [ "$got" -eq "$want" ]; then echo "ok   $name"; else echo "FAIL $name (exit $got, want $want)"; sed 's/^/     /' "$d.log"; failed=1; fi
}

expect pass 0 pass
expect fail_line 1 fail_line
expect exit_code 1 exit_code
expect parse_error 1 parse_error
expect no_pass 1 no_pass
expect hang 1 hang
expect empty 1
expect mixed 1 pass fail_line
grep -q "fail_line" "$tmp/mixed.log" && grep -q "pass" "$tmp/mixed.log" && echo "ok   mixed reports both" || { echo "FAIL mixed reports both"; failed=1; }
exit $failed
