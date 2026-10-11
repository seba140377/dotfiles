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
