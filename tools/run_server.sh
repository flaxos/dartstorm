#!/usr/bin/env bash
# Launch DARTSTORM in Headless Dedicated Server mode.
#
# Usage:
#   ./tools/run_server.sh [options]
#
# Examples:
#   ./tools/run_server.sh
#   ./tools/run_server.sh --port=8920 --name="Public CTF Server"
#   ./tools/run_server.sh --arena=two_forts --mode=ctf --bot-fill=6
#   ./tools/run_server.sh --map-rotation="two_forts,dust2,backyard"
#
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4 || echo "$HOME/bin/godot")}"
if [ ! -x "$GODOT" ]; then
	echo "ERROR: Godot not found. Install Godot 4.4+ and put it on PATH, or set GODOT_BIN." >&2
	exit 127
fi

exec "$GODOT" --headless --path "$ROOT" -- --server "$@"
