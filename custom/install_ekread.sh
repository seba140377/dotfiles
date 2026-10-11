#!/usr/bin/env bash
# Builds ekread (read-only EventKit CLI, sources in custom/ekread/).
# Usage: install_ekread.sh [TARGET]   (default: ~/.local/bin/ekread)

set -euo pipefail

SRC="$(cd "$(dirname "$0")/ekread" && pwd)"
TARGET="${1:-$HOME/.local/bin/ekread}"

mkdir -p "$(dirname "$TARGET")"

echo "   Building ekread..."
# The embedded Info.plist carries the usage descriptions macOS needs before it
# asks for calendar and reminders access.
swiftc -O -swift-version 5 "$SRC/Core.swift" "$SRC/main.swift" \
  -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker "$SRC/Info.plist" \
  -o "$TARGET"

echo ""
echo "✅ ekread installed to $TARGET"
