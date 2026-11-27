#!/usr/bin/env bash
# Builds a double-clickable Linux release of DARTSTORM:
#
#   build/linux/DARTSTORM/                       the game folder (one executable, icon, shortcut helper, README)
#   build/DARTSTORM-<version>-linux-x86_64.tar.gz  the same folder, packed for sharing
#
#   ./tools/export_linux.sh
#
# Needs Godot's export templates for the same Godot version
# (Editor > Manage Export Templates, or unpack them into
# ~/.local/share/godot/export_templates/<version>/). Set GODOT_BIN if `godot` is not on your PATH.
# After building, the script starts the exported game headless for a few seconds to prove it boots.
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4 || echo "$HOME/bin/godot")}"
if [ ! -x "$GODOT" ]; then
	echo "ERROR: Godot not found. Put it on PATH or set GODOT_BIN." >&2
	exit 127
fi
# "4.4.1.stable.official.49a5bc7b6" -> "4.4.1.stable" (the templates folder name)
ENGINE_VERSION="$("$GODOT" --version | grep -oE '^[0-9]+(\.[0-9]+)+\.[a-z]+[0-9]*')"
TEMPLATE="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$ENGINE_VERSION/linux_release.x86_64"
if [ ! -f "$TEMPLATE" ]; then
	echo "ERROR: export templates for $ENGINE_VERSION are missing ($TEMPLATE)." >&2
	echo "Install them from the Godot editor (Editor > Manage Export Templates) and try again." >&2
	exit 1
fi

GAME_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
OUT="build/linux/DARTSTORM"
ARCHIVE="build/DARTSTORM-$GAME_VERSION-linux-x86_64.tar.gz"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Exporting DARTSTORM $GAME_VERSION with Godot $ENGINE_VERSION"
rm -rf "build/linux"
mkdir -p "$OUT"
"$GODOT" --headless --path . --import >/dev/null 2>&1
if ! "$GODOT" --headless --path . --export-release "Linux" "$OUT/DARTSTORM.x86_64" >"$LOG" 2>&1 \
		|| [ ! -s "$OUT/DARTSTORM.x86_64" ]; then
	tail -30 "$LOG"
	echo "FAILED: export" >&2
	exit 1
fi
chmod +x "$OUT/DARTSTORM.x86_64"
cp icon.svg "$OUT/dartstorm.svg"
if [ -f assets/branding/icon_512.png ]; then
	cp assets/branding/icon_512.png "$OUT/dartstorm.png"
fi
cp tools/linux/install-shortcut.sh "$OUT/"
chmod +x "$OUT/install-shortcut.sh"
sed "s/@VERSION@/$GAME_VERSION/" tools/linux/README.txt >"$OUT/README.txt"
cp assets/fonts/OFL.txt "$OUT/FONT-LICENSE.txt"

echo "Smoke test: booting the exported game headless"
if ! timeout 60 "$OUT/DARTSTORM.x86_64" --headless -- --demo --quit-after=4 >"$LOG" 2>&1; then
	tail -30 "$LOG"
	echo "FAILED: the exported game did not boot and quit cleanly" >&2
	exit 1
fi
if grep -Eq 'SCRIPT ERROR|Parse Error|ERROR:|Failed loading|Cannot load|leaked at exit' "$LOG"; then
	grep -E -A2 'SCRIPT ERROR|Parse Error|ERROR:|Failed loading|Cannot load|leaked at exit' "$LOG" | head -30
	echo "FAILED: the exported game reported errors" >&2
	exit 1
fi

tar -C build/linux -czf "$ARCHIVE" DARTSTORM
echo
echo "Built $OUT/ ($(du -sh "$OUT" | cut -f1)) and $ARCHIVE ($(du -h "$ARCHIVE" | cut -f1))"
echo "Play: double-click DARTSTORM.x86_64, or run ./install-shortcut.sh once to add DARTSTORM to the applications menu."
