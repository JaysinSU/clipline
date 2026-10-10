#!/bin/bash
# Real AppKit integration tests on a private named pasteboard. Requires only
# Command Line Tools; does not overwrite the user's general clipboard.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build .cache/modules
swiftc -module-cache-path "$PWD/.cache/modules" \
  Sources/Clipline/ClipboardWatcher.swift Sources/Clipline/Line.swift \
  Sources/Clipline/Markup.swift Sources/Clipline/Localization.swift Sources/Clipline/Inbox.swift \
  Tests/CliplineTests/ClipboardWatcherTests.swift -o .build/clipboard-tests
.build/clipboard-tests
