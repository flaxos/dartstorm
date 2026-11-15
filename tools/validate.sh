#!/usr/bin/env bash
# DARTSTORM validation:
#   1. import the project
#   2. strict compile: every GDScript, with every warning treated as an error
#   3. boot the main menu and a match headless
#   4. run the automated tests (must pass, and must exit without leaks)
#
#   ./tools/validate.sh            # everything (about 2 minutes)
#   ./tools/validate.sh --quick    # skips the test suite
#
# Set GODOT_BIN if `godot` is not on your PATH.
set -uo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1

GODOT="${GODOT_BIN:-}"
if [ -z "$GODOT" ]; then
	if command -v godot >/dev/null 2>&1; then
		GODOT="$(command -v godot)"
	elif command -v godot4 >/dev/null 2>&1; then
		GODOT="$(command -v godot4)"
	fi
fi
if [ -z "$GODOT" ] || [ ! -x "$GODOT" ]; then
	echo "ERROR: Godot not found. Install Godot 4.4+ and put it on PATH, or set GODOT_BIN." >&2
	exit 127
fi

echo "Godot: $GODOT ($("$GODOT" --version))"
LOG="$(mktemp)"
OVERRIDE="$ROOT/override.cfg"
if [ -e "$OVERRIDE" ]; then
	echo "ERROR: $OVERRIDE already exists. validate.sh uses that file temporarily; move it away first." >&2
	exit 2
fi
# The strict-warnings override must never be left behind, even on Ctrl+C.
trap 'rm -f "$LOG" "$OVERRIDE"' EXIT
FAILED=0

# Errors we treat as failures. Godot's harmless editor network noise is ignored.
ERROR_PATTERN='SCRIPT ERROR|Parse Error|PARSER ERROR|ERROR:|Failed loading|Resource file not found|Cannot load|Invalid/corrupt|Failed to load script|Cannot get class|BROKEN SCRIPT'
IGNORE_PATTERN='_sock == -1|net_socket_unix|tcp_server'

step() {
	local name="$1"; shift
	printf '\n== %s\n' "$name"
	timeout 240 "$@" >"$LOG" 2>&1
	local status=$?
	if grep -Ev "$IGNORE_PATTERN" "$LOG" | grep -Eq "$ERROR_PATTERN"; then
		grep -Ev "$IGNORE_PATTERN" "$LOG" | grep -E -A2 "$ERROR_PATTERN" | head -40
		echo "FAILED: $name reported errors"
		FAILED=1
	elif [ "$status" -ne 0 ]; then
		tail -30 "$LOG"
		echo "FAILED: $name exited with status $status"
		FAILED=1
	else
		echo "ok"
	fi
}

cd "$ROOT"
step "Import project" "$GODOT" --headless --path . --import

printf '\n== Strict compile (warnings are errors)\n'
if timeout 60 "$GODOT" --headless --path . -s res://tools/check_scripts.gd -- --print-strict-override 2>/dev/null \
		| grep -E '^\[debug\]|^gdscript/' >"$OVERRIDE" && [ -s "$OVERRIDE" ]; then
	timeout 120 "$GODOT" --headless --path . -s res://tools/check_scripts.gd >"$LOG" 2>&1
	status=$?
	rm -f "$OVERRIDE"
	grep -E 'SCRIPT ERROR|at: GDScript::reload|BROKEN SCRIPT|^Checked' "$LOG" | head -40
	if [ "$status" -ne 0 ]; then
		echo "FAILED: strict compile"
		FAILED=1
	fi
else
	rm -f "$OVERRIDE"
	echo "FAILED: could not generate the strict-warnings override"
	FAILED=1
fi

step "Boot main menu (120 frames)" "$GODOT" --headless --path . --quit-after 120
step "Boot a match (300 frames)" "$GODOT" --headless --path . res://scenes/game/match.tscn --quit-after 300

if [ "$QUICK" -eq 0 ]; then
	printf '\n== Automated tests\n'
	timeout 300 "$GODOT" --headless --path . res://tests/test_runner.tscn >"$LOG" 2>&1
	status=$?
	grep -E '^\[|FAIL|====' "$LOG"
	if [ "$status" -ne 0 ]; then
		echo "FAILED: tests (exit $status)"
		FAILED=1
	fi
	if grep -q "leaked at exit" "$LOG"; then
		echo "FAILED: objects leaked at exit (run the tests with --verbose to see which)"
		FAILED=1
	fi
fi

echo
if [ "$FAILED" -eq 0 ]; then
	echo "DARTSTORM validation passed."
else
	echo "DARTSTORM validation FAILED."
fi
exit "$FAILED"
