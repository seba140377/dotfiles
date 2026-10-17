#!/usr/bin/env bash
# Tests tagesplanung-run with stubbed ekread/claude/notify (no calendar access,
# no Claude run). Usage: custom/tagesplanung/test.sh
set -euo pipefail

cd "$(dirname "$0")"
HERE="$(pwd)"
RUN="$HERE/tagesplanung-run"
TMP="${TMPDIR:-/tmp}/tagesplanung-test.$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

# new_case <name>: fresh vault, stubs and environment in $T
new_case() {
  T="$TMP/$1"
  mkdir -p "$T/vault/plans" "$T/bin"
  cat >"$T/bin/ekread" <<'EOF'
#!/bin/bash
exit "${STUB_EKREAD:-0}"
EOF
  # caffeinate stub: records its arguments, then runs the wrapped command
  cat >"$T/bin/caffeinate" <<'EOF'
#!/bin/bash
echo "$*" >>"$STUB_DIR/caffeinate.txt"
shift
exec "$@"
EOF
  cat >"$T/bin/notify" <<'EOF'
#!/bin/bash
echo "$1" >>"$STUB_DIR/notify.txt"
EOF
  # claude stub: records its arguments; writes the plan file named by
  # STUB_FILE_<mode> with `generated: $STUB_GEN` (plus `status: $STUB_STATUS`
  # and the body $STUB_BODY when set) unless STUB_CLAUDE says otherwise.
  # Mode is `rueckblick` for /wochenrueckblick, else the second prompt word.
  cat >"$T/bin/claude" <<'EOF'
#!/bin/bash
echo "$*" >>"$STUB_DIR/calls.txt"
case "$2" in
  /wochenrueckblick*) mode=rueckblick ;;
  *) mode=$(echo "$2" | awk '{print $2}') ;;
esac
case "${STUB_CLAUDE:-write}" in
  none) exit 0 ;;
  sleep) sleep 5; exit 0 ;;
  fail) exit 1 ;;
  fail-morgen) [ "$mode" = morgen ] && exit 1 ;;
  fail-rueckblick) [ "$mode" = rueckblick ] && exit 1 ;;
esac
var="STUB_FILE_$mode"
if [ -n "${!var:-}" ]; then
  {
    printf -- '---\ngenerated: %sT%s\n' "$STUB_GEN" "${STUB_TIME:-20:00}"
    [ -n "${STUB_STATUS:-}" ] && printf 'status: %s\n' "$STUB_STATUS"
    printf -- '---\n%b' "${STUB_BODY:-}"
  } >"plans/${!var}"
fi
exit 0
EOF
  chmod +x "$T/bin/"*
  export TP_VAULT="$T/vault" TP_CLAUDE="$T/bin/claude" TP_NOTIFY="$T/bin/notify" \
    TP_LOG="$T/log" TP_PATH_PREFIX="$T/bin" TP_TIMEOUT=10 STUB_DIR="$T"
}

run() { GOT=0; "$RUN" "$@" >"$T/out" 2>&1 || GOT=$?; }

# check <name> <condition...>: one ok/FAIL line per assertion
check() {
  local name=$1; shift
  if "$@"; then echo "ok   $CASE: $name"; else echo "FAIL $CASE: $name"; fi
}
exit_is() { [ "$GOT" = "$1" ]; }
notified() { grep -q -- "$1" "$T/notify.txt" 2>/dev/null; }
no_calls() { [ ! -e "$T/calls.txt" ]; }
call_count() { [ "$(wc -l <"$T/calls.txt" | tr -d ' ')" = "$1" ]; }
call_n_has() { sed -n "${1}p" "$T/calls.txt" | grep -q -- "$2"; }
call_n_lacks() { ! sed -n "${1}p" "$T/calls.txt" | grep -q -- "$2"; }

results="$TMP/results"
: >"$results"
t() { CASE=$1; shift; ( new_case "$CASE"; "$@" ) >>"$results" 2>&1 || echo "FAIL $CASE: aborted" >>"$results"; }

invalid_mode() {
  run gestern
  check "exit 1" exit_is 1
  check "claude not called" no_calls
}
ekread_denied() {
  export STUB_EKREAD=2 TP_NOW="2026-10-14 20:00"
  run
  check "exit 2" exit_is 2
  check "notify Freigabe" notified Freigabe
  check "claude not called" no_calls
}
ekread_error() {
  export STUB_EKREAD=1 TP_NOW="2026-10-14 20:00"
  run
  check "exit 1" exit_is 1
  check "notify Log" notified Log
  check "claude not called" no_calls
}
explicit_heute_ok() {
  export TP_NOW="2026-10-14 20:00" STUB_GEN=2026-10-14 STUB_FILE_heute="2026-10-14 Tagesplan.md"
  run heute
  check "exit 0" exit_is 0
  check "prompt" call_n_has 1 "/tagesplanung heute --routine"
  check "allowedTools" call_n_has 1 "--allowedTools"
  check "notify bereit" notified "Tagesplan für Mittwoch, 14.10. bereit"
}
weekday_evening_morgen() {
  export TP_NOW="2026-10-14 20:00" STUB_GEN=2026-10-14 STUB_FILE_morgen="2026-10-15 Tagesplan.md"
  run
  check "exit 0" exit_is 0
  check "one call" call_count 1
  check "morgen" call_n_has 1 "/tagesplanung morgen --routine"
}
sunday_evening_both() {
  export TP_NOW="2026-10-18 20:00" STUB_GEN=2026-10-18 STUB_STATUS=entwurf \
    STUB_FILE_morgen="2026-10-19 Tagesplan.md" STUB_FILE_woche="2026-W43 Wochenplan.md" \
    STUB_FILE_rueckblick="2026-W42 Wochenrückblick.md"
  run
  check "exit 0" exit_is 0
  check "three calls" call_count 3
  check "morgen first" call_n_has 1 "/tagesplanung morgen --routine"
  check "rueckblick second" call_n_has 2 "/wochenrueckblick --routine"
  check "woche third" call_n_has 3 "/tagesplanung woche --routine"
  check "notify KW" notified "Wochenplan KW 43 bereit"
  check "notify review" notified "Wochenrückblick KW 42 bereit"
}
monday_catchup_order() {
  export TP_NOW="2026-10-19 07:00" STUB_GEN=2026-10-19 STUB_STATUS=entwurf \
    STUB_FILE_heute="2026-10-19 Tagesplan.md" STUB_FILE_woche="2026-W43 Wochenplan.md" \
    STUB_FILE_rueckblick="2026-W42 Wochenrückblick.md"
  run
  check "exit 0" exit_is 0
  check "three calls" call_count 3
  check "heute first" call_n_has 1 "/tagesplanung heute --routine"
  check "rueckblick second" call_n_has 2 "/wochenrueckblick --routine"
  check "woche third" call_n_has 3 "/tagesplanung woche --routine"
  check "notify previous week" notified "Wochenrückblick KW 42 bereit"
}
explicit_rueckblick() {
  export TP_NOW="2026-10-18 20:00" STUB_GEN=2026-10-18 STUB_STATUS=entwurf \
    STUB_FILE_rueckblick="2026-W42 Wochenrückblick.md"
  run rueckblick
  check "exit 0" exit_is 0
  check "one call" call_count 1
  check "prompt" call_n_has 1 "/wochenrueckblick --routine"
}
rueckblick_fails_week_still_runs() {
  export TP_NOW="2026-10-18 20:00" STUB_GEN=2026-10-18 STUB_CLAUDE=fail-rueckblick \
    STUB_FILE_morgen="2026-10-19 Tagesplan.md" STUB_FILE_woche="2026-W43 Wochenplan.md" \
    STUB_FILE_rueckblick="2026-W42 Wochenrückblick.md"
  run
  check "exit 1" exit_is 1
  check "woche attempted" call_n_has 3 "/tagesplanung woche --routine"
  check "notify fehlgeschlagen" notified "(rueckblick) fehlgeschlagen"
}
decided_review_is_success() {
  export TP_NOW="2026-10-18 20:00" STUB_CLAUDE=none
  printf -- '---\nstatus: entschieden\ngenerated: 2026-10-18T09:00\n---\n' \
    >"$T/vault/plans/2026-W42 Wochenrückblick.md"
  run rueckblick
  check "exit 0" exit_is 0
  check "notify bereits entschieden" notified "Wochenrückblick KW 42 bereits entschieden"
  check "file untouched" grep -q "generated: 2026-10-18T09:00" "$T/vault/plans/2026-W42 Wochenrückblick.md"
}
draft_review_stale_fails() {
  export TP_NOW="2026-10-18 20:00" STUB_CLAUDE=none
  printf -- '---\nstatus: entwurf\ngenerated: 2026-10-18T09:00\n---\n' \
    >"$T/vault/plans/2026-W42 Wochenrückblick.md"
  run rueckblick
  check "exit 1" exit_is 1
}
review_count_in_notice() {
  export TP_NOW="2026-10-18 20:00" STUB_GEN=2026-10-18 STUB_STATUS=entwurf \
    STUB_FILE_rueckblick="2026-W42 Wochenrückblick.md" \
    STUB_BODY='## Erledigt\n1. x\n\n## Zu entscheiden\n1. a\n2. b\n\n<!-- Entscheidungen -->\n## Entscheidungen\n1. c\n'
  run rueckblick
  check "exit 0" exit_is 0
  check "count" notified "Wochenrückblick KW 42 bereit (2 zu entscheiden)"
}
review_tools() {
  export TP_NOW="2026-10-18 20:00" STUB_GEN=2026-10-18 STUB_STATUS=entwurf \
    STUB_FILE_morgen="2026-10-19 Tagesplan.md" STUB_FILE_woche="2026-W43 Wochenplan.md" \
    STUB_FILE_rueckblick="2026-W42 Wochenrückblick.md"
  run
  check "review without Gmail" call_n_lacks 2 "mcp__claude_ai_Gmail"
  check "review with git-activity" call_n_has 2 "Bash(.claude/skills/wochenrueckblick/git-activity:"
  check "review dontAsk" call_n_has 2 "--permission-mode dontAsk"
  check "woche keeps Gmail" call_n_has 3 "mcp__claude_ai_Gmail"
  check "woche without git-activity" call_n_lacks 3 "git-activity"
}
catchup_morning_heute() {
  export TP_NOW="2026-10-14 07:00" STUB_GEN=2026-10-14 STUB_FILE_heute="2026-10-14 Tagesplan.md"
  run
  check "exit 0" exit_is 0
  check "one call" call_count 1
  check "heute" call_n_has 1 "/tagesplanung heute --routine"
}
catchup_morning_monday_week() {
  export TP_NOW="2026-10-12 07:00" STUB_GEN=2026-10-12 \
    STUB_FILE_heute="2026-10-12 Tagesplan.md" STUB_FILE_woche="2026-W42 Wochenplan.md" \
    STUB_FILE_rueckblick="2026-W41 Wochenrückblick.md"
  run
  check "exit 0" exit_is 0
  check "three calls" call_count 3
  check "heute first" call_n_has 1 "/tagesplanung heute --routine"
  check "woche last" call_n_has 3 "/tagesplanung woche --routine"
}
missing_file_fails() {
  export TP_NOW="2026-10-14 20:00" STUB_CLAUDE=none
  run heute
  check "exit 1" exit_is 1
  check "notify fehlgeschlagen" notified "fehlgeschlagen"
}
stale_file_fails() {
  export TP_NOW="2026-10-14 20:00" STUB_GEN=2026-10-01 STUB_FILE_heute="2026-10-14 Tagesplan.md"
  run heute
  check "exit 1" exit_is 1
}
morgen_fails_week_still_runs() {
  export TP_NOW="2026-10-11 20:00" STUB_GEN=2026-10-11 STUB_CLAUDE=fail-morgen \
    STUB_FILE_morgen="2026-10-12 Tagesplan.md" STUB_FILE_woche="2026-W42 Wochenplan.md"
  run
  check "exit 1" exit_is 1
  check "woche attempted" call_n_has 3 "/tagesplanung woche --routine"
}
timeout_kills_claude() {
  export TP_NOW="2026-10-14 20:00" TP_TIMEOUT=1 STUB_CLAUDE=sleep
  local start=$SECONDS
  run heute
  local took=$((SECONDS - start))
  check "exit 1" exit_is 1
  check "stopped within 4 s" [ "$took" -lt 4 ]
}
log_keeps_30_runs() {
  export TP_NOW="2026-10-14 20:00" STUB_GEN=2026-10-14 STUB_FILE_heute="2026-10-14 Tagesplan.md"
  local _
  for _ in $(seq 35); do run heute; done
  check "30 runs kept" [ "$(grep -c '^=== ' "$T/log")" = 30 ]
}
install_copies_files() {
  local plist="$T/agents/de.seba140377.tagesplanung.plist" rc=0
  TP_NO_LAUNCHCTL=1 bash "$HERE/../install_tagesplanung.sh" "$T/inst" "$T/agents" >/dev/null 2>&1 || rc=$?
  check "exit 0" [ "$rc" = 0 ]
  check "wrapper executable" [ -x "$T/inst/tagesplanung-run" ]
  check "plist lint" plutil -lint -s "$plist"
  check "program path" [ "$(plutil -extract ProgramArguments.0 raw "$plist" 2>/dev/null)" = "$T/inst/tagesplanung-run" ]
  check "hour 20" [ "$(plutil -extract StartCalendarInterval.Hour raw "$plist" 2>/dev/null)" = 20 ]
  check "minute 0" [ "$(plutil -extract StartCalendarInterval.Minute raw "$plist" 2>/dev/null)" = 0 ]
  check "log path" [ "$(plutil -extract StandardOutPath raw "$plist" 2>/dev/null)" = "$HOME/Library/Logs/tagesplanung.log" ]
  rc=0
  TP_NO_LAUNCHCTL=1 bash "$HERE/../install_tagesplanung.sh" "$T/inst" "$T/agents" >/dev/null 2>&1 || rc=$?
  check "idempotent" [ "$rc" = 0 ]
}
permissions_locked() {
  export TP_NOW="2026-10-14 20:00" STUB_GEN=2026-10-14 STUB_FILE_heute="2026-10-14 Tagesplan.md"
  run heute
  check "dontAsk" call_n_has 1 "--permission-mode dontAsk"
  check "no get_thread" call_n_lacks 1 "get_thread"
  check "no open git push" call_n_lacks 1 "git push:"
  check "push origin main" call_n_has 1 "Bash(git push origin main)"
}
caffeinate_wraps_claude() {
  export TP_NOW="2026-10-14 20:00" STUB_GEN=2026-10-14 STUB_FILE_heute="2026-10-14 Tagesplan.md"
  run heute
  check "exit 0" exit_is 0
  check "caffeinate -i" grep -q -- "^-i " "$T/caffeinate.txt"
  check "wraps claude run" grep -q -- "/tagesplanung heute --routine" "$T/caffeinate.txt"
}
same_day_old_file_fails() {
  export TP_NOW="2026-10-14 20:00" STUB_CLAUDE=none
  printf -- '---\ngenerated: 2026-10-14T15:00\n---\n' >"$T/vault/plans/2026-10-14 Tagesplan.md"
  run heute
  check "exit 1" exit_is 1
  check "notify fehlgeschlagen" notified "fehlgeschlagen"
}

for c in invalid_mode ekread_denied ekread_error explicit_heute_ok weekday_evening_morgen \
  sunday_evening_both catchup_morning_heute catchup_morning_monday_week missing_file_fails \
  stale_file_fails morgen_fails_week_still_runs timeout_kills_claude log_keeps_30_runs \
  install_copies_files permissions_locked same_day_old_file_fails \
  caffeinate_wraps_claude monday_catchup_order explicit_rueckblick rueckblick_fails_week_still_runs \
  decided_review_is_success draft_review_stale_fails review_count_in_notice review_tools; do
  t "$c" "$c"
done

cat "$results"
fails=$(grep -c '^FAIL' "$results" || true)
echo ""
if [ "$fails" = 0 ]; then echo "✅ all passed"; else echo "❌ $fails failed"; exit 1; fi
