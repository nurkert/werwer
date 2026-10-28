#!/usr/bin/env bash
# Loads a packed web app (tool/package_webapp.sh) from a local relay, with
# exactly the headers players get, in headless Chrome: the page must start
# Flutter, and the browser must not refuse anything but the <base> element
# (blocked on purpose by base-uri 'none'). Runs in the release workflow.
#
#   tool/verify_webapp.sh <webapp.tar.gz>
set -euo pipefail
cd "$(dirname "$0")/.."
chrome=${CHROME_EXECUTABLE:-$(command -v google-chrome || command -v chromium || true)}
if [[ -z "$chrome" ]]; then
  echo "error: no Chrome found; set CHROME_EXECUTABLE" >&2
  exit 1
fi
archive=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
protocol=$(sed -n 's/^const protocolVersion = \([0-9]*\);$/\1/p' \
  packages/protocol/lib/src/messages.dart)
work=$(mktemp -d)
port=18471
server=""
cleanup() {
  if [[ -n "$server" ]]; then kill "$server" 2>/dev/null || true; fi
  rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$work/apps/$protocol/check"
tar -xzf "$archive" -C "$work/apps/$protocol/check"
PORT=$port WEB_APP_DIR="$work/apps" dart run server/bin/server.dart \
  >"$work/server.log" 2>&1 &
server=$!
for _ in $(seq 1 60); do
  curl -sf -o /dev/null "http://127.0.0.1:$port/health" && break
  sleep 0.5
done

key='k=AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE=&s=AgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgI='
timeout 90 "$chrome" --headless=new --no-sandbox --disable-gpu \
  --user-data-dir="$work/profile" --enable-logging=stderr --v=0 \
  --virtual-time-budget=20000 --dump-dom \
  "http://127.0.0.1:$port/v/$protocol/check/join?room=1234&relay=abcd2345#$key" \
  >"$work/dom.html" 2>"$work/chrome.log" || true

if ! grep -q 'flutter-view\|flt-glass-pane' "$work/dom.html"; then
  echo "error: the web app did not start under the relay's headers" >&2
  grep -i 'console' "$work/chrome.log" | head -20 >&2 || true
  exit 1
fi
refused=$(grep -iE 'Content Security Policy|Refused to' "$work/chrome.log" \
  | grep -v "base URI" || true)
if [[ -n "$refused" ]]; then
  echo "error: the browser refused parts of the web app:" >&2
  echo "$refused" | head -20 >&2
  exit 1
fi
echo "✓ Web app starts under the relay's headers"
