#!/usr/bin/env bash
# Fails if personal signing data slipped into tracked files (team IDs, profiles, keys).
# Local values belong in git-ignored files such as app/ios/Flutter/Signing.xcconfig.
set -euo pipefail
cd "$(dirname "$0")/.."

found=0
if git grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' -- ':!*.md' >/dev/null; then
  echo "error: a DEVELOPMENT_TEAM value is committed:" >&2
  git grep -nE 'DEVELOPMENT_TEAM *= *[A-Z0-9]{10}' -- ':!*.md' >&2
  found=1
fi
if git ls-files | grep -E '\.(mobileprovision|p12|jks|keystore)$|key\.properties$|Signing\.xcconfig$' >&2; then
  echo "error: signing files are tracked (see above)" >&2
  found=1
fi
if [[ $found == 1 ]]; then
  echo "Move them into git-ignored local files (CLAUDE.md, 'Running on real devices')." >&2
  exit 1
fi
echo "ok: no personal signing data in tracked files"
