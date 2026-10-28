#!/usr/bin/env bash
# Tests tool/fetch_webapps.sh offline: a build whose file does not match its
# checksum in the lock stops everything and nothing is unpacked; a matching
# one is unpacked; a retired one is skipped.
set -euo pipefail
cd "$(dirname "$0")/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/files" "$work/build"
echo '<!DOCTYPE html>page' > "$work/build/index.html"
tar -C "$work/build" -czf "$work/files/whowolf-1.0.0-webapp.tar.gz" .
cp "$work/files/whowolf-1.0.0-webapp.tar.gz" "$work/files/whowolf-0.9.0-webapp.tar.gz"
good=$(sha256sum "$work/files/whowolf-1.0.0-webapp.tar.gz" | cut -d' ' -f1)
bad=$(printf '%064d' 0)

run() { # <lock content> -> exit code
  printf '%s\n' "$1" > "$work/lock"
  rm -rf "$work/out"
  WEBAPPS_LOCK="$work/lock" WEBAPPS_OUT="$work/out" WEBAPPS_FROM="$work/files" \
    tool/fetch_webapps.sh >/dev/null 2>&1
}

fail() { echo "error: fetch_webapps.sh: $1" >&2; exit 1; }

if run "8 1.0.0 $bad"; then fail "a wrong checksum was accepted"; fi
[[ -e "$work/out/8/1.0.0/index.html" ]] && fail "a build with a wrong checksum was unpacked"

run "8 1.0.0 $good" || fail "a matching build was refused"
[[ -f "$work/out/8/1.0.0/index.html" ]] || fail "a matching build was not unpacked"

run "$(printf '8 0.9.0 %s\nretire 8 0.9.0' "$good")" || fail "a retired build broke the run"
[[ -e "$work/out/8/0.9.0" ]] && fail "a retired build was unpacked"
echo "  fetch_webapps.sh: checksums and retirement hold"
