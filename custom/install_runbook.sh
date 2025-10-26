#!/usr/bin/env bash

set -euo pipefail

# check if file ~/.local/bin/runbook already exists and exit if it does exiting
if [ -f ~/.local/bin/runbook ]; then
  echo "   ✅ runbook at ~/.local/bin/runbook already installed."
  exit 0
fi

# Download runbook binary
echo "   Downloading runbook binary..."
curl -sLo /tmp/runbooks_darwin_arm64 https://github.com/gruntwork-io/runbooks/releases/download/v0.0.2/runbooks_darwin_arm64

# Create ~/.local/bin if it doesn't exist
mkdir -p ~/.local/bin

# Move to ~/.local/bin with name runbook
echo "   Installing to ~/.local/bin/runbook..."
mv /tmp/runbooks_darwin_arm64 ~/.local/bin/runbook

# Make it executable
chmod +x ~/.local/bin/runbook

echo ""
echo "✅ runbook installed successfully to ~/.local/bin/runbook"
