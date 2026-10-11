#!/usr/bin/env bash
# Installs the tagesplanung routine: wrapper + launchd agent (daily 20:00) that
# runs the vault skill `tagesplanung` (sources in custom/tagesplanung/).
# Usage: install_tagesplanung.sh [BIN_DIR] [AGENTS_DIR]
#   defaults: ~/.local/bin, ~/Library/LaunchAgents; TP_NO_LAUNCHCTL=1 skips loading

set -euo pipefail

SRC="$(cd "$(dirname "$0")/tagesplanung" && pwd)"
BIN_DIR="${1:-$HOME/.local/bin}"
AGENTS_DIR="${2:-$HOME/Library/LaunchAgents}"
LABEL="de.seba140377.tagesplanung"
PLIST="$AGENTS_DIR/$LABEL.plist"

mkdir -p "$BIN_DIR" "$AGENTS_DIR" "$HOME/Library/Logs"

install -m 755 "$SRC/tagesplanung-run" "$BIN_DIR/tagesplanung-run"
sed -e "s|__BIN__|$BIN_DIR|g" -e "s|__HOME__|$HOME|g" "$SRC/$LABEL.plist" >"$PLIST"

if [ "${TP_NO_LAUNCHCTL:-0}" != 1 ]; then
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
fi

echo ""
echo "✅ tagesplanung installed ($BIN_DIR/tagesplanung-run, $PLIST)"
