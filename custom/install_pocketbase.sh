#!/usr/bin/env bash

set -euo pipefail

# check if file ~/.local/bin/pocketbase already exists and exit if it does exiting
if [ -f ~/.local/bin/pocketbase ]; then
  echo "   ✅ pocketbase at ~/.local/bin/pocketbase already installed."
  exit 0
fi

# Download pocketbase binary
echo "   Downloading pocketbase binary..."
curl -sLo /tmp/pocketbase_0.31.0_darwin_arm64.zip https://github.com/pocketbase/pocketbase/releases/download/v0.31.0/pocketbase_0.31.0_darwin_arm64.zip

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Unzip the downloaded file to ~/.local/bin
echo "   Installing to ~/.local/bin/runbook..."
unzip -q -o /tmp/pocketbase_0.31.0_darwin_arm64.zip -d ~/.local/bin pocketbase

# Make it executable
chmod +x ~/.local/bin/pocketbase

echo ""
echo "✅ pocketbase installed successfully to ~/.local/bin/pocketbase"
