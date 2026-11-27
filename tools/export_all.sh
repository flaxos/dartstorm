#!/usr/bin/env bash
# Builds all DARTSTORM release packages for GitHub Releases and computes SHA256SUMS.txt:
#
#   build/release-v<version>/
#     DARTSTORM-<version>-windows-x86_64.zip
#     DARTSTORM-<version>-linux-x86_64.tar.gz
#     DARTSTORM-<version>-android.apk
#     DARTSTORM-<version>-web.zip
#     DARTSTORM-<version>-server-linux-x86_64.tar.gz
#     SHA256SUMS.txt
#
# Usage:
#   ./tools/export_all.sh
#   ./tools/export_all.sh --skip-android   # skip APK if Android SDK is unavailable
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

SKIP_ANDROID=0
for arg in "$@"; do
	case "$arg" in
		--skip-android) SKIP_ANDROID=1 ;;
		*) echo "Unknown option: $arg" >&2; exit 2 ;;
	esac
done

GAME_VERSION="$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)"
STAGE="build/release-v$GAME_VERSION"
rm -rf "$STAGE"
mkdir -p "$STAGE"

echo "=== Building DARTSTORM v$GAME_VERSION multi-platform release ==="

./tools/export_windows.sh
cp "build/DARTSTORM-$GAME_VERSION-windows-x86_64.zip" "$STAGE/"

./tools/export_linux.sh
cp "build/DARTSTORM-$GAME_VERSION-linux-x86_64.tar.gz" "$STAGE/"

./tools/export_web.sh
cp "build/DARTSTORM-$GAME_VERSION-web.zip" "$STAGE/"

./tools/export_server.sh
cp "build/DARTSTORM-$GAME_VERSION-server-linux-x86_64.tar.gz" "$STAGE/"

if [ "$SKIP_ANDROID" -eq 0 ]; then
	./tools/export_apk.sh
	cp "build/android/DARTSTORM.apk" "$STAGE/DARTSTORM-$GAME_VERSION-android.apk"
fi

(
	cd "$STAGE"
	sha256sum DARTSTORM-* > SHA256SUMS.txt
)

echo
echo "=== Release bundle ready in $STAGE ==="
ls -lh "$STAGE"
cat "$STAGE/SHA256SUMS.txt"
