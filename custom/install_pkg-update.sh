#!/usr/bin/env bash
# Installs the pkg-update routine: wrapper + launchd agent (Sundays 18:00) that
# keeps brew and the global mise tools current (sources in custom/pkg-update/).
# Usage: install_pkg-update.sh [BIN_DIR] [AGENTS_DIR]
#   defaults: ~/.local/bin, ~/Library/LaunchAgents; PU_NO_LAUNCHCTL=1 skips loading

set -euo pipefail

SRC="$(cd "$(dirname "$0")/pkg-update" && pwd)"
BIN_DIR="${1:-$HOME/.local/bin}"
AGENTS_DIR="${2:-$HOME/Library/LaunchAgents}"
LABEL="de.seba140377.pkg-update"
PLIST="$AGENTS_DIR/$LABEL.plist"

mkdir -p "$BIN_DIR" "$AGENTS_DIR" "$HOME/Library/Logs"

install -m 755 "$SRC/pkg-update-run" "$BIN_DIR/pkg-update-run"
sed -e "s|__BIN__|$BIN_DIR|g" -e "s|__HOME__|$HOME|g" "$SRC/$LABEL.plist" >"$PLIST"

if [ "${PU_NO_LAUNCHCTL:-0}" != 1 ]; then
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"

  # terminal-notifier (ad-hoc signed) only registers with the Notification
  # Center when started as an app; run from its bin symlink it exits 3
  tn_app="$(brew --prefix terminal-notifier 2>/dev/null)/terminal-notifier.app"
  if [ -d "$tn_app" ]; then
    open "$tn_app" --args -title Paketpflege -message "Mitteilungen der Paketpflege sind eingerichtet"
  fi
fi

echo ""
echo "✅ pkg-update installed ($BIN_DIR/pkg-update-run, $PLIST)"
