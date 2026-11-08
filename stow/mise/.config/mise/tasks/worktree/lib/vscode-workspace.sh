# shellcheck shell=bash
# Shows a repository's worktrees folder (<repo>.worktrees) as a root folder in
# the user's VS Code workspace file and takes it out again.
# Sourced by ../add and ../finish, not a task (mise skips files that are not
# executable). Needs jq.
#
# The workspace files live outside the repositories, in VSCODE_WORKSPACES
# (default ~/.config/vscode, e.g. sflabio.code-workspace), so git never sees
# the change. The one used is the first that has the repository's main
# checkout, or a folder above it, as a root folder; for a sub-repository under
# src/ that is the umbrella's workspace. VS Code picks up the changed folder
# list in an open window without reloading it. The file is rewritten with
# `jq --tab` and without a final newline, as VS Code writes it, so taking the
# folder out again leaves the file as it was.

# vscode_ws_file <main_root>: prints the path of the workspace file, or nothing.
vscode_ws_file() {
  local file folder
  for file in "${VSCODE_WORKSPACES:-$HOME/.config/vscode}"/*.code-workspace; do
    [[ -f $file ]] || continue
    while read -r folder; do
      # Relative folder paths count from the workspace file's folder.
      [[ $folder == /* ]] || folder=$(cd "$(dirname "$file")/$folder" 2>/dev/null && pwd -P) || continue
      if [[ $1 == "$folder" || $1 == "$folder"/* ]]; then
        echo "$file"
        return 0
      fi
    done < <(jq -r '.folders[].path' "$file" 2>/dev/null)
  done
}

# _vscode_ws_write <ws_file> <jq args…>: applies a jq filter to the file in place.
_vscode_ws_write() {
  local file=$1 out
  shift
  if ! out=$(jq --tab "$@" "$file" 2>/dev/null); then
    ui_warn "Could not parse $file as JSON (comments?); left it unchanged."
    return 0
  fi
  printf '%s' "$out" >"$file"
}

# vscode_ws_add <main_root>: adds <main_root>.worktrees as a root folder,
# named after the folder, unless it is in the workspace already.
vscode_ws_add() {
  local file dir
  file=$(vscode_ws_file "$1")
  [[ -n $file ]] || return 0
  dir="$1.worktrees"
  jq -e --arg p "$dir" 'any(.folders[]; .path == $p)' "$file" >/dev/null 2>&1 && return 0
  _vscode_ws_write "$file" --arg p "$dir" --arg n "$(basename "$dir")" \
    '.folders += [{name: $n, path: $p}]'
  ui_ok "Added $(basename "$dir") to $file"
}

# vscode_ws_remove <main_root> <path>: removes <main_root>.worktrees from the
# workspace if no linked worktree other than <path> is left in it.
vscode_ws_remove() {
  local file dir wt
  file=$(vscode_ws_file "$1")
  [[ -n $file ]] || return 0
  dir="$1.worktrees"
  while read -r wt; do
    if [[ $wt == "$dir"/* && $wt != "$2" ]]; then return 0; fi
  done < <(git -C "$1" worktree list --porcelain | sed -n 's/^worktree //p')
  jq -e --arg p "$dir" 'any(.folders[]; .path == $p)' "$file" >/dev/null 2>&1 || return 0
  _vscode_ws_write "$file" --arg p "$dir" '.folders |= map(select(.path != $p))'
  ui_ok "Removed $(basename "$dir") from $file"
}
