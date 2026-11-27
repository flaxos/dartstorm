#!/usr/bin/env bash
# Builds a standalone double-clickable Windows 64-bit release of DARTSTORM:
#
#   build/windows/DARTSTORM/DARTSTORM.exe             single self-contained executable (embedded PCK)
#   build/DARTSTORM-<version>-windows-x86_64.zip      packed zip archive ready to share & test
#
# Usage:
#   ./tools/export_windows.sh
#
# Needs Godot's Windows export templates for the active Godot version.
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4 || echo "$HOME/bin/godot")}"
if [ ! -x "$GODOT" ]; then
	echo "ERROR: Godot not found. Put it on PATH or set GODOT_BIN." >&2
	exit 127
fi

ENGINE_VERSION="$("$GODOT" --version | grep -oE '^[0-9]+(\.[0-9]+)+\.[a-z]+[0-9]*')"
TEMPLATE="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$ENGINE_VERSION/windows_release_x86_64.exe"
if [ ! -f "$TEMPLATE" ]; then
	echo "ERROR: Windows export templates for $ENGINE_VERSION are missing ($TEMPLATE)." >&2
	echo "Install them from the Godot editor (Editor > Manage Export Templates) and try again." >&2
	exit 1
fi

GAME_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
OUT="build/windows/DARTSTORM"
ARCHIVE="build/DARTSTORM-$GAME_VERSION-windows-x86_64.zip"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Exporting DARTSTORM $GAME_VERSION for Windows x86_64 with Godot $ENGINE_VERSION"
rm -rf "build/windows"
mkdir -p "$OUT"

"$GODOT" --headless --path . --import >/dev/null 2>&1
if ! "$GODOT" --headless --path . --export-release "Windows Desktop" "$OUT/DARTSTORM.exe" >"$LOG" 2>&1 \
		|| [ ! -s "$OUT/DARTSTORM.exe" ]; then
	tail -30 "$LOG"
	echo "FAILED: Windows export" >&2
	exit 1
fi

if grep -Eq 'SCRIPT ERROR|Parse Error|Failed loading|Cannot load' "$LOG"; then
	grep -E -A2 'SCRIPT ERROR|Parse Error|Failed loading|Cannot load' "$LOG" | head -30
	echo "FAILED: Windows export reported errors" >&2
	exit 1
fi

sed "s/@VERSION@/$GAME_VERSION/" tools/windows/README.txt >"$OUT/README.txt"
cp assets/fonts/OFL.txt "$OUT/FONT-LICENSE.txt"
if [ -f assets/branding/dartstorm.ico ]; then
	cp assets/branding/dartstorm.ico "$OUT/dartstorm.ico"
fi

rm -f "$ROOT/$ARCHIVE"
(cd "build/windows" && zip -q -r "$ROOT/$ARCHIVE" DARTSTORM)

echo
echo "Built $OUT/DARTSTORM.exe ($(du -h "$OUT/DARTSTORM.exe" | cut -f1)) and $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
if command -v file >/dev/null 2>&1; then
	file "$OUT/DARTSTORM.exe"
fi
echo "Share $ARCHIVE — Windows users extract and double-click DARTSTORM.exe."
