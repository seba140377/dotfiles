#!/bin/sh
# Claude Code statusLine entrypoint (configured in ~/.claude/settings.json by `setup.sh --claude`).
# Forwards the JSON payload to Orca's statusline hook (if installed) in the background,
# then renders the cc-statusline output from ~/.claude/statusline.sh.

input=$(cat)

ORCA_HOOK="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [ -r "$ORCA_HOOK" ]; then
  printf '%s' "$input" | /bin/sh "$ORCA_HOOK" >/dev/null 2>&1 &
fi

printf '%s' "$input" | "$HOME/.claude/statusline.sh"
