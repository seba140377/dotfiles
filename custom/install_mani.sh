#!/usr/bin/env bash

set -euo pipefail

check if file ~/.local/bin/mani already exists and exit if it does exiting
if [ -f ~/.local/bin/mani ]; then
  echo "   ✅ mani at ~/.local/bin/mani already installed."
  exit 0
fi

# Download mani binary
echo "   Downloading mani binary..."
curl -sLo /tmp/mani_0.32.1_darwin_amd64.tar.gz https://github.com/alajmo/mani/releases/download/v0.32.1/mani_0.32.1_darwin_amd64.tar.gz

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Unzip the downloaded file to ~/.local/bin
echo "   Installing to ~/.local/bin/mani..."
mkdir -p /tmp/mani
tar -xzf /tmp/mani_0.32.1_darwin_amd64.tar.gz -C /tmp/mani/

mv /tmp/mani/mani ~/.local/bin

# Make it executable
chmod +x ~/.local/bin/mani

echo ""
echo "✅ mani installed successfully to ~/.local/bin/mani"
