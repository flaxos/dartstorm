#!/usr/bin/env bash
# Launch DARTSTORM.
#   ./tools/run.sh           # play the game (main menu)
#   ./tools/run.sh editor    # open the project in the Godot editor
#   ./tools/run.sh demo      # watch an automatic demo match for 20 seconds
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4 || true)}"
if [ -z "$GODOT" ]; then
	echo "ERROR: Godot not found. Install Godot 4.4+ and put it on PATH, or set GODOT_BIN." >&2
	exit 127
fi

case "${1:-play}" in
	editor) exec "$GODOT" --path "$ROOT" --editor ;;
	demo) exec "$GODOT" --path "$ROOT" res://scenes/game/match.tscn -- --demo --quit-after=20 ;;
	*) exec "$GODOT" --path "$ROOT" ;;
esac
