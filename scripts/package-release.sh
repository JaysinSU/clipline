#!/bin/bash
# Build the universal app and package the complete public source and app.
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-app.sh

APP="build/Clipline.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
OUT="$PWD/build/releases"
PACKAGE_WORK="$(mktemp -d)"
trap 'rm -rf "$PACKAGE_WORK"' EXIT
mkdir -p "$OUT" "$PACKAGE_WORK/source/Clipline" "$PACKAGE_WORK/Clipline-$VERSION/source"

# Include documentation, license, scripts and tests, excluding local caches.
tar --exclude=.git --exclude=.build --exclude=.cache --exclude=build \
    --exclude=.DS_Store --exclude=.swiftpm -cf - . \
    | tar -xf - -C "$PACKAGE_WORK/source/Clipline"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/Clipline-$VERSION.zip"
ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_WORK/source/Clipline" \
    "$OUT/Clipline-$VERSION-source.zip"

ditto "$APP" "$PACKAGE_WORK/Clipline-$VERSION/Clipline.app"
ditto "$PACKAGE_WORK/source/Clipline" "$PACKAGE_WORK/Clipline-$VERSION/source/Clipline"
cp README.md LICENSE "$PACKAGE_WORK/Clipline-$VERSION/"
ditto -c -k --sequesterRsrc --keepParent "$PACKAGE_WORK/Clipline-$VERSION" \
    "$OUT/Clipline-$VERSION-all.zip"
(
    cd "$OUT"
    shasum -a 256 "Clipline-$VERSION.zip" "Clipline-$VERSION-source.zip" \
        "Clipline-$VERSION-all.zip" > SHA256SUMS.txt
)
codesign --verify --deep --strict "$APP"
echo "Release files: $OUT"
