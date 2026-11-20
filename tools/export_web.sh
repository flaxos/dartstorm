#!/usr/bin/env bash
# Builds a playable Web build of DARTSTORM:
#
#   build/web/index.html   (and associated .js, .pck, .wasm)
#   build/DARTSTORM-<version>-web.zip
#
# Usage:
#   ./tools/export_web.sh
#
# Runs on any standard HTTP web server without special Cross-Origin Isolation headers.
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
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$ENGINE_VERSION"
if [ ! -f "$TEMPLATE_DIR/web_nothreads_release.zip" ] && [ ! -f "$TEMPLATE_DIR/web_release.zip" ]; then
	echo "ERROR: web export templates for $ENGINE_VERSION are missing in $TEMPLATE_DIR." >&2
	exit 1
fi

GAME_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
OUT="build/web"
ARCHIVE="build/DARTSTORM-$GAME_VERSION-web.zip"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Exporting DARTSTORM $GAME_VERSION for Web (HTML5/WASM) with Godot $ENGINE_VERSION"
rm -rf "$OUT"
mkdir -p "$OUT"

"$GODOT" --headless --path . --import >/dev/null 2>&1
if ! "$GODOT" --headless --path . --export-release "Web" "$OUT/index.html" >"$LOG" 2>&1 \
		|| [ ! -s "$OUT/index.html" ] || [ ! -s "$OUT/index.wasm" ]; then
	tail -30 "$LOG"
	echo "FAILED: web export" >&2
	exit 1
fi

(cd "$OUT" && zip -q -r "$ROOT/$ARCHIVE" ./*)

echo
echo "Built $OUT/ ($(du -sh "$OUT" | cut -f1)) and $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
echo "Play locally: python3 tools/serve_web.py"
