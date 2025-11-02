#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/git

cd ~/git

# Cloning mu-repo
echo "   Cloning mu-repo..."
git clone https://github.com/fabioz/mu-repo.git > /dev/null 2>&1

ln -s ~/git/mu-repo/mu ~/.local/bin

echo ""
echo "✅ mu-repo installed successfully to ~/git/mu-repo and linked to ~/.local/bin/mu"
