#!/usr/bin/env bash
# Builds a signed Android APK of DARTSTORM:
#
#   build/android/DARTSTORM.apk
#
# Usage:
#   ./tools/export_apk.sh [--debug|--release]
#
# Requires:
#   - Android SDK (build-tools, platform-tools, platforms/android-34)
#   - Java SDK (JDK 17+)
#   - Godot export templates for the active Godot version
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

export ANDROID_HOME="${ANDROID_HOME:-/home/flax/Android/Sdk}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

GODOT="${GODOT_BIN:-$(command -v godot || command -v godot4 || echo "$HOME/bin/godot")}"
if [ ! -x "$GODOT" ]; then
	echo "ERROR: Godot not found. Put it on PATH or set GODOT_BIN." >&2
	exit 127
fi

ENGINE_VERSION="$("$GODOT" --version | grep -oE '^[0-9]+(\.[0-9]+)+\.[a-z]+[0-9]*')"
TEMPLATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$ENGINE_VERSION"
if [ ! -f "$TEMPLATE_DIR/android_debug.apk" ] && [ ! -f "$TEMPLATE_DIR/android_release.apk" ]; then
	echo "ERROR: Android export templates for $ENGINE_VERSION are missing in $TEMPLATE_DIR." >&2
	exit 1
fi

MODE="--export-debug"
if [ "${1:-}" = "--release" ]; then
	MODE="--export-release"
fi

GAME_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
OUT="build/android"
APK="$OUT/DARTSTORM.apk"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

echo "Exporting DARTSTORM $GAME_VERSION for Android ($MODE) with Godot $ENGINE_VERSION"
mkdir -p "$OUT"

"$GODOT" --headless --path . --import >/dev/null 2>&1
if ! "$GODOT" --headless --path . $MODE "Android" "$APK" >"$LOG" 2>&1 \
		|| [ ! -s "$APK" ]; then
	tail -30 "$LOG"
	echo "FAILED: Android APK export" >&2
	exit 1
fi

echo
echo "Built $APK ($(du -h "$APK" | cut -f1))"

# Verify APK package info if aapt is available
AAPT="$(find "$ANDROID_HOME/build-tools" -name aapt | sort -V | tail -n 1 || true)"
if [ -x "$AAPT" ]; then
	echo "Package Info:"
	"$AAPT" dump badging "$APK" | grep -E "package: name=|targetSdkVersion:|application-label:" | head -n 5
fi

# Verify signature if apksigner is available
APKSIGNER="$(find "$ANDROID_HOME/build-tools" -name apksigner | sort -V | tail -n 1 || true)"
if [ -x "$APKSIGNER" ]; then
	echo "Verifying APK Signature:"
	"$APKSIGNER" verify "$APK" && echo "APK signature verified successfully."
fi

echo "To install on a connected device: adb install -r $APK"
