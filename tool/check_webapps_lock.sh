#!/usr/bin/env bash
# Checks server/webapps.lock: well-formed, and only ever appended to.
set -euo pipefail
cd "$(dirname "$0")/.."
lock=server/webapps.lock

line_no=0
while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))
  [[ -z "$line" || "$line" == \#* ]] && continue
  if ! [[ "$line" =~ ^[0-9]{1,4}\ [0-9a-z][0-9a-z.-]{0,31}\ [0-9a-f]{64}$ \
       || "$line" =~ ^retire\ [0-9]{1,4}\ [0-9a-z][0-9a-z.-]{0,31}$ ]]; then
    echo "error: $lock:$line_no is not '<protocol> <build> <sha256>' or 'retire <protocol> <build>'" >&2
    exit 1
  fi
done < "$lock"

# Compare with the version before these changes, if history is there.
base=""
if git rev-parse -q --verify origin/main >/dev/null 2>&1; then
  base=$(git merge-base HEAD origin/main)
  [[ "$base" == "$(git rev-parse HEAD)" ]] && base=""
fi
if [[ -z "$base" ]] && git rev-parse -q --verify HEAD~1 >/dev/null 2>&1; then
  base=HEAD~1
fi
if [[ -z "$base" ]] || ! git cat-file -e "$base:$lock" 2>/dev/null; then
  echo "  (no earlier $lock to compare with)"
  exit 0
fi
before=$(git show "$base:$lock")
if [[ "$(head -c ${#before} "$lock")" != "$before" ]]; then
  echo "error: $lock changed lines that were already there; only append (use 'retire' to withdraw a build)" >&2
  exit 1
fi
