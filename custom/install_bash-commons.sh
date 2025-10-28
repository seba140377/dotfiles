#!/usr/bin/env bash

set -euo pipefail

mkdir -p ~/git

cd ~/git

# Cloning bash
echo "   Cloning bash-commons..."
git clone https://github.com/gruntwork-io/bash-commons.git > /dev/null 2>&1

echo ""
echo "✅ bash-commons installed successfully to ~/git/bash-commons"
