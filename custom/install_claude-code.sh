#!/usr/bin/env bash

set -euo pipefail

if [ -x ~/.local/bin/claude ]; then
  echo "   ✅ Claude Code at ~/.local/bin/claude already installed."
  exit 0
fi

echo "   Installing Claude Code (native installer)..."
curl -fsSL https://claude.ai/install.sh | bash

echo ""
echo "✅ Claude Code installed successfully to ~/.local/bin/claude"
