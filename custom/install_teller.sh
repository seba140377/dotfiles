#!/usr/bin/env bash

set -euo pipefail

if [ -f ~/.local/bin/teller ]; then
  echo "   ✅ teller at ~/.local/bin/teller already installed."
  exit 0
fi

echo "   Downloading teller binary..."
curl -sLo /tmp/teller-aarch64-macos.tar.xz https://github.com/tellerops/teller/releases/download/v2.0.7/teller-aarch64-macos.tar.xz

mkdir -p ~/.local/bin
mkdir -p /tmp/teller

echo "   Installing to ~/.local/bin/teller..."
tar -xJf /tmp/teller-aarch64-macos.tar.xz -C /tmp/teller/

mv /tmp/teller/teller-aarch64-macos/teller ~/.local/bin/teller

chmod +x ~/.local/bin/teller

echo ""
echo "✅ teller installed successfully to ~/.local/bin/teller"
