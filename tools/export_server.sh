#!/usr/bin/env bash
# Builds a standalone Linux Headless Dedicated Server release of DARTSTORM:
#
#   build/server/                                 the server folder (executable, start_server.sh helper, README)
#   build/DARTSTORM-<version>-server-linux-x86_64.tar.gz  the packed release archive
#
# Usage:
#   ./tools/export_server.sh
#
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
TEMPLATE="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$ENGINE_VERSION/linux_release.x86_64"
if [ ! -f "$TEMPLATE" ]; then
	echo "ERROR: export templates for $ENGINE_VERSION are missing ($TEMPLATE)." >&2
	exit 1
fi

GAME_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
OUT="build/server"
ARCHIVE="build/DARTSTORM-$GAME_VERSION-server-linux-x86_64.tar.gz"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Exporting DARTSTORM $GAME_VERSION Dedicated Server with Godot $ENGINE_VERSION"
rm -rf "$OUT"
mkdir -p "$OUT"

"$GODOT" --headless --path . --import >/dev/null 2>&1

if ! "$GODOT" --headless --path . --export-release "Linux Server" "$OUT/dartstorm-server.x86_64" >"$LOG" 2>&1 \
		|| [ ! -s "$OUT/dartstorm-server.x86_64" ]; then
	tail -30 "$LOG"
	echo "FAILED: server export" >&2
	exit 1
fi
chmod +x "$OUT/dartstorm-server.x86_64"

# Generate start_server.sh helper
cat << 'EOF' > "$OUT/start_server.sh"
#!/usr/bin/env bash
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/dartstorm-server.x86_64" --headless -- --server "$@"
EOF
chmod +x "$OUT/start_server.sh"

# Generate README.txt
cat << EOF > "$OUT/README.txt"
DARTSTORM Dedicated Server v$GAME_VERSION
==========================================

Running the Server:
-------------------
Run the helper script or executable directly:
  ./start_server.sh [options]
  # or
  ./dartstorm-server.x86_64 --headless -- --server [options]

Command-Line Options:
---------------------
  --port=<port>             Server listen port (default: 8910)
  --name=<server_name>      Name announced on LAN & lobby (default: "DARTSTORM Dedicated Server")
  --arena=<arena_id>        Starting arena (default: fortress_2)
  --mode=<mode_id>          Starting mode: deathmatch, team_deathmatch, ctf, plant_the_bomb,
                            realistic, floor_is_lava, zombie, zombie_siege, gun_game
  --max-players=<num>       Maximum human players (default: 8)
  --bot-fill=<num>          Total target combatant count (bots fill remaining slots, default: 0)
  --bot-diff=<0..3>         Bot AI difficulty: 0=EASY, 1=NORMAL, 2=HARD, 3=EXPERT (default: 1)
  --map-rotation=<list>     Comma-separated arena[:mode] playlist.
                            Example: fortress_2:ctf,dust_2:plant_the_bomb,backyard:deathmatch
  --auto-start=<sec>        Lobby countdown seconds before match auto-launches (default: 30)
  --intermission=<sec>      Post-match podium/intermission seconds before next map (default: 10)

LAN Discovery:
--------------
The server automatically broadcasts beacons on UDP port 8925 so LAN clients see it in their
LAN Server Browser immediately.
EOF

echo "Smoke test: verifying dedicated server binary boots and initializes"
if ! timeout 4 "$OUT/dartstorm-server.x86_64" --headless -- --server --auto-start=999 >"$LOG" 2>&1; then
	SERVER_STATUS=$?
	# Exit 124 is timeout, which indicates it booted and stayed alive running as a server!
	if [ $SERVER_STATUS -ne 124 ] && [ $SERVER_STATUS -ne 0 ]; then
		tail -30 "$LOG"
		echo "FAILED: dedicated server failed to boot (exit code $SERVER_STATUS)" >&2
		exit 1
	fi
fi

if grep -Eq 'SCRIPT ERROR|Parse Error|Failed loading|Cannot load' "$LOG"; then
	grep -E -A2 'SCRIPT ERROR|Parse Error|Failed loading|Cannot load' "$LOG" | head -30
	echo "FAILED: dedicated server reported script or load errors" >&2
	exit 1
fi

tar -C build -czf "$ARCHIVE" server
echo
echo "Successfully built $OUT/ ($(du -sh "$OUT" | cut -f1)) and $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
