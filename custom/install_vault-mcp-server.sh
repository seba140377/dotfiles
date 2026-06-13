#!/usr/bin/env bash

set -euo pipefail

if [ -f ~/.local/bin/vault-mcp-server ]; then
  echo "   ✅ vault-mcp-server at ~/.local/bin/vault-mcp-server already installed."
  exit 0
fi

echo "   Downloading vault-mcp-server binary..."
curl -sLo /tmp/vault-mcp-server_0.2.0_darwin_arm64.zip https://releases.hashicorp.com/vault-mcp-server/0.2.0/vault-mcp-server_0.2.0_darwin_arm64.zip

mkdir -p ~/.local/bin

echo "   Installing to ~/.local/bin/vault-mcp-server..."
unzip -q -o /tmp/vault-mcp-server_0.2.0_darwin_arm64.zip -d ~/.local/bin vault-mcp-server

chmod +x ~/.local/bin/vault-mcp-server

echo ""
echo "✅ vault-mcp-server installed successfully to ~/.local/bin/vault-mcp-server"
