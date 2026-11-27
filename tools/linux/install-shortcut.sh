#!/usr/bin/env bash
# Adds DARTSTORM to your applications menu (and puts a shortcut on the desktop, if there is one).
#
#   ./install-shortcut.sh            add the shortcuts
#   ./install-shortcut.sh --remove   take them away again
#
# Run it from the DARTSTORM folder. If you move the folder, run it again.
set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APPS="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
ENTRY_NAME="dartstorm.desktop"

if [ "${1:-}" = "--remove" ]; then
	rm -f "$APPS/$ENTRY_NAME" "$DESKTOP_DIR/$ENTRY_NAME"
	echo "DARTSTORM shortcuts removed. (The game folder itself is untouched.)"
	exit 0
fi

if [ ! -x "$HERE/DARTSTORM.x86_64" ]; then
	chmod +x "$HERE/DARTSTORM.x86_64"
fi

ICON_PATH="$HERE/dartstorm.svg"
if [ -f "$HERE/dartstorm.png" ]; then
	ICON_PATH="$HERE/dartstorm.png"
fi

mkdir -p "$APPS"
cat >"$APPS/$ENTRY_NAME" <<EOF
[Desktop Entry]
Type=Application
Name=DARTSTORM
GenericName=Foam-dart arena game
Comment=Colourful backyard foam-dart battles
Exec="$HERE/DARTSTORM.x86_64"
Path=$HERE
Icon=$ICON_PATH
Terminal=false
Categories=Game;ActionGame;
EOF
chmod +x "$APPS/$ENTRY_NAME"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true

if [ -d "$DESKTOP_DIR" ]; then
	cp "$APPS/$ENTRY_NAME" "$DESKTOP_DIR/$ENTRY_NAME"
	chmod +x "$DESKTOP_DIR/$ENTRY_NAME"
	# GNOME only launches desktop shortcuts it has been told to trust.
	command -v gio >/dev/null 2>&1 && gio set "$DESKTOP_DIR/$ENTRY_NAME" metadata::trusted true 2>/dev/null || true
	echo "Added DARTSTORM to the applications menu and the desktop."
else
	echo "Added DARTSTORM to the applications menu."
fi
