#!/usr/bin/env bash
# Builds and runs the ekread tests. Usage: custom/ekread/test.sh
set -euo pipefail

cd "$(dirname "$0")"
OUT="${TMPDIR:-/tmp}/ekread-test.$$"
mkdir -p "$OUT"
trap 'rm -rf "$OUT"' EXIT

echo "🔸 Unit tests"
swiftc -swift-version 5 -parse-as-library Core.swift Tests.swift -o "$OUT/tests"
"$OUT/tests"

echo "🔸 CLI checks (no calendar access needed)"
bash ../install_ekread.sh "$OUT/ekread" >/dev/null
fails=0
expect() { # expect <name> <exit> <stdout-pattern|-> <stderr-nonempty yes|no> -- cmd...
  local name=$1 want=$2 pat=$3 errwant=$4; shift 5
  local got=0
  "$@" >"$OUT/stdout" 2>"$OUT/stderr" || got=$?
  local ok=1
  [ "$got" = "$want" ] || ok=0
  if [ "$pat" != "-" ]; then grep -q -- "$pat" "$OUT/stdout" || ok=0; fi
  if [ "$errwant" = yes ]; then [ -s "$OUT/stderr" ] && [ ! -s "$OUT/stdout" ] || ok=0; fi
  if [ $ok = 1 ]; then echo "ok   $name"; else echo "FAIL $name (exit $got)"; fails=$((fails + 1)); fi
}
expect "--help exits 0" 0 events no -- "$OUT/ekread" --help
expect "invalid date exits 1" 1 - yes -- "$OUT/ekread" events --from 2026-02-30
expect "unknown command exits 1" 1 - yes -- "$OUT/ekread" foo

# EventKit write API: save/remove (also saveCalendar, removeReminder, ...), commit, reset.
WRITE_CALLS='\.(save|remove)(Calendar|Event|Reminder|Source)?[[:space:]]*\(|\.(commit|reset)[[:space:]]*\('
for sample in 'store.save(e, span: .thisEvent)' 'store.remove(e, span: .thisEvent)' 'store.saveCalendar(c, commit: true)' \
  'store.removeReminder(r, commit: true)' 'store.save (e, span: .thisEvent)' 'store.reset()'; do
  if echo "$sample" | grep -qE "$WRITE_CALLS"; then
    echo "ok   read-only guard catches: $sample"
  else
    echo "FAIL read-only guard misses: $sample"; fails=$((fails + 1))
  fi
done
if echo 'rest.removeFirst()' | grep -qE "$WRITE_CALLS"; then
  echo "FAIL read-only guard flags Array.removeFirst"; fails=$((fails + 1))
else
  echo "ok   read-only guard ignores Array.removeFirst"
fi
if grep -nE "$WRITE_CALLS" main.swift Core.swift; then
  echo "FAIL read-only: write call found"; fails=$((fails + 1))
else
  echo "ok   read-only: no EventKit write calls"
fi
# Child runs (after re-spawn) must report their own exit code and stderr.
expect "child error propagates" 1 - yes -- "$OUT/ekread" reminders --due-before 2026-02-30
if nm -u "$OUT/ekread" | grep -q '_responsibility_spawnattrs_setdisclaim'; then
  echo "ok   re-spawns itself with disclaimed responsibility"
else
  echo "FAIL responsibility disclaim not used"; fails=$((fails + 1))
fi
if [ -n "$(otool -s __TEXT __info_plist "$OUT/ekread" | sed 1d)" ]; then
  echo "ok   Info.plist embedded"
else
  echo "FAIL Info.plist not embedded"; fails=$((fails + 1))
fi

[ "$fails" = 0 ] || { echo "$fails CLI check(s) failed"; exit 1; }
echo "CLI checks passed"
