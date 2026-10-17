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
  # STUB_FILE_<mode> with `generated: $STUB_GEN` unless STUB_CLAUDE says otherwise
  cat >"$T/bin/claude" <<'EOF'
#!/bin/bash
echo "$*" >>"$STUB_DIR/calls.txt"
mode=$(echo "$2" | awk '{print $2}')
case "${STUB_CLAUDE:-write}" in
  none) exit 0 ;;
  sleep) sleep 5; exit 0 ;;
  fail) exit 1 ;;
  fail-morgen) [ "$mode" = morgen ] && exit 1 ;;
esac
var="STUB_FILE_$mode"
if [ -n "${!var:-}" ]; then
  printf -- '---\ngenerated: %sT%s\n---\n' "$STUB_GEN" "${STUB_TIME:-20:00}" >"plans/${!var}"
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
  export TP_NOW="2026-10-11 20:00" STUB_GEN=2026-10-11 \
    STUB_FILE_morgen="2026-10-12 Tagesplan.md" STUB_FILE_woche="2026-W42 Wochenplan.md"
  run
  check "exit 0" exit_is 0
  check "two calls" call_count 2
  check "morgen first" call_n_has 1 "/tagesplanung morgen --routine"
  check "woche second" call_n_has 2 "/tagesplanung woche --routine"
  check "notify KW" notified "Wochenplan KW 42 bereit"
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
    STUB_FILE_heute="2026-10-12 Tagesplan.md" STUB_FILE_woche="2026-W42 Wochenplan.md"
  run
  check "exit 0" exit_is 0
  check "two calls" call_count 2
  check "heute first" call_n_has 1 "/tagesplanung heute --routine"
  check "woche second" call_n_has 2 "/tagesplanung woche --routine"
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
  check "woche attempted" call_n_has 2 "/tagesplanung woche --routine"
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
  caffeinate_wraps_claude; do
  t "$c" "$c"
done

cat "$results"
fails=$(grep -c '^FAIL' "$results" || true)
echo ""
if [ "$fails" = 0 ]; then echo "✅ all passed"; else echo "❌ $fails failed"; exit 1; fi
