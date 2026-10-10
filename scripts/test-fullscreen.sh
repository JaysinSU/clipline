#!/bin/bash
# Native AppKit smoke test: briefly opens an empty full screen window.
set -euo pipefail
cd "$(dirname "$0")/.."
TEST_WORK="$(mktemp -d)"
trap 'rm -rf "$TEST_WORK"' EXIT
BUNDLE="$TEST_WORK/FullScreenSmoke.app"
mkdir -p "$BUNDLE/Contents/MacOS" .cache/modules
SOURCES=()
for file in Sources/Clipline/*.swift; do
  if [ "$(basename "$file")" != main.swift ]; then SOURCES+=("$file"); fi
done
swiftc -module-cache-path "$PWD/.cache/modules" "${SOURCES[@]}" Tests/FullScreenSmoke/Smoke.swift -o "$BUNDLE/Contents/MacOS/FullScreenSmoke"
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleName</key><string>FullScreenSmoke</string><key>CFBundleIdentifier</key><string>local.clipline.FullScreenSmoke</string><key>CFBundleExecutable</key><string>FullScreenSmoke</string><key>CFBundlePackageType</key><string>APPL</string><key>LSMinimumSystemVersion</key><string>14.0</string></dict></plist>
PLIST
codesign --force --sign - "$BUNDLE"
open -W "$BUNDLE" --args "$TEST_WORK/result.json"
python3 - "$TEST_WORK/result.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    results = json.load(f)
for name, passed in results.items():
    print(('PASS ' if passed else 'FAIL ') + name)
if len(results) != 9 or not all(results.values()):
    raise SystemExit(1)
PY
