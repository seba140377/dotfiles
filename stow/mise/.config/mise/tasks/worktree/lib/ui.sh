# shellcheck shell=bash
# The look of the worktree tasks: a header box, status lines and messages.
# Sourced by ../add and ../finish, not a task (mise skips files that are not
# executable). A trimmed copy of the ui_* helpers in sflabio's .mise/common.sh.
#
# Styled only when stdout is a terminal, NO_COLOR is unset and gum is there;
# everywhere else (pipes, tests, agents) the same text comes out plain.

UI_BRAND='#f97316'
UI_SUCCESS='#16a34a'

UI_STYLED=false
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && command -v gum >/dev/null 2>&1; then
  UI_STYLED=true
fi

# gum drops the colour inside $(…), where its stdout is a pipe, unless forced.
_ui_gum() { CLICOLOR_FORCE=1 gum "$@"; }

# ui_color <colour> <text…>: the text in that colour.
ui_color() {
  local c=$1
  shift
  if [ "$UI_STYLED" = true ]; then _ui_gum style --foreground "$c" "$*"; else echo "$*"; fi
}

# ui_ok <text…>: a line with a green check mark.
ui_ok() { echo "$(ui_color "$UI_SUCCESS" '✓') $*"; }

# ui_warn, ui_error <text…>: a message on stderr; ui_die also exits 1.
ui_warn() {
  if [ "$UI_STYLED" = true ] && [ -t 2 ]; then _ui_gum log --level warn "$*" >&2; else echo "WARN: $*" >&2; fi
}
ui_error() {
  if [ "$UI_STYLED" = true ] && [ -t 2 ]; then _ui_gum log --level error "$*" >&2; else echo "ERROR: $*" >&2; fi
}
ui_die() {
  ui_error "$@"
  exit 1
}

# ui_header <title> [line…]: the rounded box a task opens with; the title is
# the task name, the lines say what it does.
ui_header() {
  local title=$1
  shift
  if [ "$UI_STYLED" = true ]; then
    _ui_gum style --border rounded --border-foreground "$UI_BRAND" --padding "0 1" \
      "$(_ui_gum style --bold --foreground "$UI_BRAND" "$title")" "$@"
  else
    printf '%s\n' "$title" "$@"
  fi
}
