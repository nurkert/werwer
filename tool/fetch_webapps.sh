#!/usr/bin/env bash
# Fetches the web app builds for the relay image into server/webapps/:
# every build in server/webapps.lock that is not retired, plus the release
# being built (<version>, optional). Each file must match its checksum
# where the lock has one, and every file must carry this repository's
# GitHub build attestation. Needs `gh` (logged in) and network; runs in the
# release workflow.
#
#   tool/fetch_webapps.sh [<version>]
#
# Tests (tool/test_fetch_webapps.sh) set WEBAPPS_LOCK, WEBAPPS_OUT and
# WEBAPPS_FROM (a folder with the release files instead of GitHub). From a
# folder the checksums are checked the same way, but there is no build
# attestation to check: never use it for an image.
set -euo pipefail
cd "$(dirname "$0")/.."
repo=${GITHUB_REPOSITORY:-nurkert/whowolf}
lock=${WEBAPPS_LOCK:-server/webapps.lock}
out=${WEBAPPS_OUT:-server/webapps}
from=${WEBAPPS_FROM:-}
if [[ -n "$from" ]]; then
  echo "  (files from $from: checksums only, NO attestation check)" >&2
fi
protocol=$(sed -n 's/^const protocolVersion = \([0-9]*\);$/\1/p' \
  packages/protocol/lib/src/messages.dart)
if [[ -z "$protocol" ]]; then
  echo "error: protocolVersion not found in packages/protocol" >&2
  exit 1
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

retired=$(sed -n 's/^retire \([0-9]*\) \(.*\)$/\1 \2/p' "$lock")

fetch() { # <protocol> <build> <sha256 or empty>
  local pv=$1 build=$2 sum=$3 file="whowolf-$2-webapp.tar.gz"
  if grep -qx "$pv $build" <<<"$retired"; then
    echo "  $pv/$build retired, skipped"
    return
  fi
  if [[ -n "$from" ]]; then
    cp "$from/$file" "$work/$file"
  else
    gh release download "v$build" --repo "$repo" --pattern "$file" --dir "$work" --clobber
  fi
  if [[ -n "$sum" ]] && ! echo "$sum  $work/$file" | sha256sum -c --quiet 2>/dev/null; then
    echo "error: $file does not match its checksum in $lock" >&2
    exit 1
  fi
  if [[ -z "$from" ]]; then
    gh attestation verify "$work/$file" --repo "$repo" \
      --signer-workflow "$repo/.github/workflows/prerelease.yml" >/dev/null
  fi
  mkdir -p "$out/$pv/$build"
  tar -xzf "$work/$file" -C "$out/$pv/$build" --no-same-owner --no-same-permissions
  echo "  $pv/$build"
}

while read -r pv build sum; do
  [[ -z "$pv" || "$pv" == \#* || "$pv" == retire ]] && continue
  fetch "$pv" "$build" "$sum"
done < "$lock"
if [[ $# -ge 1 ]]; then
  fetch "$protocol" "${1#v}" ""
fi
