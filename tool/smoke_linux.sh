#!/usr/bin/env bash
# Starts a packaged Linux build for a few seconds on a virtual display and
# fails if it dies early or a library is missing. Used by the release
# workflow for the .deb, the .rpm's libraries, the AppImage and the Flatpak.
# Usage: tool/smoke_linux.sh <seconds> <command> [args...]
#
# Needs xvfb-run (apt install xvfb) unless DISPLAY is set.
set -euo pipefail

[[ $# -ge 2 ]] || { echo "usage: $0 <seconds> <command> [args...]" >&2; exit 2; }
seconds=$1
shift
log=$(mktemp)
trap 'rm -f "$log"' EXIT

wrap=()
if [[ -z ${DISPLAY:-} ]]; then
  command -v xvfb-run >/dev/null || { echo "error: xvfb-run missing (apt install xvfb)" >&2; exit 1; }
  wrap=(xvfb-run -a -s "-screen 0 1280x800x24")
fi

status=0
timeout -s TERM "$seconds" "${wrap[@]}" "$@" >"$log" 2>&1 || status=$?
echo "--- last lines of $* ---"
tail -n 25 "$log"
echo "---"
if grep -qiE 'error while loading shared libraries|cannot open shared object|segmentation fault|failed to start flutter engine' "$log"; then
  echo "error: $1 failed to start (see above)" >&2
  exit 1
fi
# 124: still running when the time was up, which is what an app should do.
if [[ $status -ne 124 && $status -ne 0 ]]; then
  echo "error: $1 exited with $status within ${seconds}s" >&2
  exit 1
fi
echo "✓ $1 kept running for ${seconds}s"
