#!/usr/bin/env bash
# Tests pkg-update-run with stubbed brew/mise/caffeinate/notify against a
# throwaway dotfiles git repo (no package is touched).
# Usage: custom/pkg-update/test.sh
# check() evals its single-quoted assertions later, which also read rc and msg.
# shellcheck disable=SC2016,SC2034
set -euo pipefail

cd "$(dirname "$0")"
HERE="$(pwd)"
RUN="$HERE/pkg-update-run"
TMP="${TMPDIR:-/tmp}/pkg-update-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# The real jq/yq, resolved before the mise stub shadows the shims
JQ=$(mise which jq)
YQ=$(mise which yq)

fails=0
pass() { echo "ok   $1"; }
fail() {
  echo "FAIL $1"
  fails=$((fails + 1))
}
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

# new_case <name>: fresh dotfiles repo, stubs and environment in $T
new_case() {
  T="$TMP/$1"
  mkdir -p "$T/bin" "$T/dotfiles/stow/mise/.config/mise"
  ln -s "$JQ" "$T/bin/jq"
  ln -s "$YQ" "$T/bin/yq"
  cat >"$T/bin/caffeinate" <<'EOF'
#!/bin/bash
shift
exec "$@"
EOF
  cat >"$T/bin/notify" <<'EOF'
#!/bin/bash
echo "$1" >>"$STUB_DIR/notify.txt"
echo "$2" >>"$STUB_DIR/notify-target.txt"
EOF
  # brew stub: records its arguments; STUB_BREW_FAIL=<subcommand> fails that one
  cat >"$T/bin/brew" <<'EOF'
#!/bin/bash
echo "brew $*" >>"$STUB_DIR/calls.txt"
[ "${STUB_BREW_FAIL:-}" != "$1" ] || exit 3
case "$1" in
  outdated) printf '%s' "${STUB_BREW_OUTDATED:-}" ;;
  leaves) printf '%s\n' ${STUB_LEAVES:-} ;;
  list) printf '%s\n' ${STUB_CASKS:-} ;;
esac
EOF
  # mise stub: records its arguments; `upgrade` prints STUB_UPGRADE_OUT and,
  # with STUB_LOCK_CHANGE=1, changes the repo's lockfile
  cat >"$T/bin/mise" <<'EOF'
#!/bin/bash
echo "mise $*" >>"$STUB_DIR/calls.txt"
case "$1" in
  upgrade)
    printf '%s\n' "${STUB_UPGRADE_OUT:-}"
    [ "${STUB_LOCK_CHANGE:-0}" != 1 ] || echo "# changed" >>"$STUB_LOCK"
    ;;
  outdated) printf '%s\n' "${STUB_OUTDATED:-{\}}" ;;
esac
EOF
  chmod +x "$T/bin/"*

  local d="$T/dotfiles"
  cat >"$d/config.yml" <<'EOF'
brews:
  - name: git
  - name: some/tap/flux-operator
  - name: wget
  - name: wezterm
    cask: true
EOF
  echo '[tools]' >"$d/stow/mise/.config/mise/config.toml"
  echo 'lockfile_version = 4' >"$d/stow/mise/.config/mise/mise.lock"
  git -C "$d" init -q -b main
  git -C "$d" add -A
  git -C "$d" -c user.name=t -c user.email=t@t commit -q -m init

  export STUB_DIR="$T" STUB_LOCK="$d/stow/mise/.config/mise/mise.lock"
  export PU_DOTFILES="$d" PU_NOTIFY="$T/bin/notify" PU_LOG="$T/run.log"
  export PU_PATH_PREFIX="$T/bin" PU_SELF_UPDATE=1 PU_REPORT="$T/report.md"
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  export STUB_LEAVES="git some/tap/flux-operator wget" STUB_CASKS="wezterm"
  unset STUB_BREW_FAIL STUB_BREW_OUTDATED STUB_UPGRADE_OUT STUB_LOCK_CHANGE STUB_OUTDATED
  rc=0
}

run() { "$RUN" >"$T/out.txt" 2>&1 || rc=$?; }
commits() { git -C "$T/dotfiles" rev-list --count HEAD; }
notified() { cat "$T/notify.txt" 2>/dev/null; }
report() { cat "$PU_REPORT" 2>/dev/null; }

UPGRADED='Upgraded 2 tools:
  python 3.14.8 → 3.14.10
  kubectl 1.36.5 → 1.36.6
mise Newer versions are available but do not match the configured version ranges:
  helm 4.2.4 → 4.3.1 (~/.config/mise/config.toml)'

# 1. lockfile changed on a clean main: one commit with the upgrades as body
new_case commit
STUB_LOCK_CHANGE=1 STUB_UPGRADE_OUT="$UPGRADED" STUB_BREW_OUTDATED=$'wget\ngit\n' run
check "commit: exit 0" '[ "$rc" = 0 ]'
check "commit: one new commit" '[ "$(commits)" = 2 ]'
msg=$(git -C "$T/dotfiles" log -1 --format=%B)
check "commit: subject" 'grep -q "^chore(mise): update global tools to the latest patch versions$" <<<"$msg"'
check "commit: body lists upgrades" 'grep -q "^- python 3.14.8 → 3.14.10$" <<<"$msg" && grep -q "^- kubectl 1.36.5 → 1.36.6$" <<<"$msg"'
check "commit: versions past pins not listed" '! grep -q helm <<<"$msg"'
check "commit: only the lockfile" '[ "$(git -C "$T/dotfiles" show --name-only --format= HEAD)" = stow/mise/.config/mise/mise.lock ]'
check "commit: notification counts" 'notified | grep -q "^Aktualisiert: 2 brew-Pakete, 2 mise-Tools, Commit [0-9a-f]*\. Nichts zu tun\.$"'
check "commit: click opens the report" '[ "$(cat "$T/notify-target.txt")" = "$PU_REPORT" ]'
check "commit: report lists upgrades" 'report | grep -q "^- brew: wget, git$" && report | grep -q "^  - python 3.14.8 → 3.14.10$" && report | grep -q "^- Commit in den dotfiles: "'
check "commit: report nothing to do" 'report | grep -q "^Nichts zu tun\.$"'
check "commit: brew and mise steps ran" 'grep -q "^brew upgrade$" "$T/calls.txt" && grep -q "^mise self-update -y$" "$T/calls.txt" && grep -q "^mise lock --global$" "$T/calls.txt" && grep -q "^mise prune -y$" "$T/calls.txt"'

# 2. lockfile unchanged: no commit
new_case unchanged
run
check "unchanged: no commit" '[ "$(commits)" = 1 ]'
check "unchanged: notification" 'notified | grep -q "^Aktualisiert: 0 brew-Pakete, 0 mise-Tools\. Nichts zu tun\.$"'
check "unchanged: report says nothing" 'report | grep -q "^- brew: nichts$" && report | grep -q "^- mise: nichts$"'

# 3. another branch: updates run, no commit
new_case branch
git -C "$T/dotfiles" checkout -q -b feat/x
STUB_LOCK_CHANGE=1 STUB_UPGRADE_OUT="$UPGRADED" run
check "branch: no commit" '[ "$(git -C "$T/dotfiles" rev-list --count HEAD)" = 1 ]'
check "branch: notification points to report" 'notified | grep -q "Zu tun: siehe Bericht (klicken)\.$"'
check "branch: report explains" 'report | grep -q "nicht committet\*\* (dotfiles auf Branch feat/x, nicht main)" && report | grep -q "git -C $T/dotfiles commit -m"'

# 4. own changes to the mise config: no commit
new_case dirty
echo 'jq = "1.8"' >>"$T/dotfiles/stow/mise/.config/mise/config.toml"
STUB_LOCK_CHANGE=1 STUB_UPGRADE_OUT="$UPGRADED" run
check "dirty: no commit" '[ "$(commits)" = 1 ]'
check "dirty: report explains" 'report | grep -q "nicht committet\*\* (eigene Änderungen an der mise-Config)"'

# 4b. own changes, but the lockfile did not change: nothing about a commit
new_case dirty-nolock
echo 'jq = "1.8"' >>"$T/dotfiles/stow/mise/.config/mise/config.toml"
run
check "dirty-nolock: no commit hint" '! report | grep -q "nicht committet" && notified | grep -q "Nichts zu tun\.$"'

# 5. versions past the pins are reported
new_case bumps
STUB_OUTDATED='{"kubectl":{"requested":"1.36","bump":"1.37"},"fd":{"requested":"10.5","bump":null},"helm":{"requested":"4.2","bump":"4.3"}}' run
check "bumps: commands in report" 'report | grep -qF -- "- kubectl 1.36 → 1.37: \`cd ~ && mise upgrade --bump kubectl && mise lock --global\`" && report | grep -qF -- "- helm 4.2 → 4.3: "'
check "bumps: commit command in report" 'report | grep -qF "commit -m \"chore(mise): raise pins\" -- stow/mise/.config/mise/config.toml stow/mise/.config/mise/mise.lock"'
check "bumps: logged with versions" 'grep -q "kubectl 1.36 → 1.37" "$T/run.log"'
check "bumps: no bump not named" '! report | grep -q "fd "'

# 6. brew drift against config.yml (tap prefix ignored)
new_case drift
STUB_LEAVES="git some/tap/flux-operator midnight-commander" STUB_CASKS="wezterm" run
check "drift: extra in report" 'report | grep -q "Installiert, aber nicht in config.yml:\*\* midnight-commander\." && report | grep -qF "brew uninstall midnight-commander"'
check "drift: missing in report" 'report | grep -q "In config.yml, aber nicht installiert:\*\* wget\." && report | grep -qF "./setup.sh --brew"'
check "drift: tap formula matched" '! report | grep -q "flux-operator"'

# 7. a failing step: the others still run, exit 1, reported
new_case fail
STUB_BREW_FAIL=upgrade run
check "fail: exit 1" '[ "$rc" = 1 ]'
check "fail: mise still ran" 'grep -q "^mise upgrade --global$" "$T/calls.txt"'
check "fail: reported" 'notified | grep -q "^Fehler: brew upgrade\. .*Zu tun: siehe Bericht (klicken)\.$"'
check "fail: report points to log" 'report | grep -q "Fehlgeschlagen: brew upgrade\.\*\*"'

# 8. PU_SELF_UPDATE=0 skips mise self-update
new_case noself
PU_SELF_UPDATE=0 run
check "noself: skipped" '! grep -q "self-update" "$T/calls.txt"'

# 9. the log keeps the last 30 runs
new_case trim
for i in $(seq 1 31); do echo "=== old $i" >>"$PU_LOG"; done
run
check "trim: 30 runs kept" '[ "$(grep -c "^=== " "$PU_LOG")" = 30 ]'
check "trim: oldest dropped" '! grep -q "^=== old 1$" "$PU_LOG" && ! grep -q "^=== old 2$" "$PU_LOG"'

echo
if [ "$fails" -gt 0 ]; then
  echo "$fails test(s) failed"
  exit 1
fi
echo "all tests passed"
