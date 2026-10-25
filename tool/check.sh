#!/usr/bin/env bash
# Everything CI checks, runnable locally. Green here means green in CI.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ Personal signing data"
tool/check_no_personal_ids.sh

echo "→ Dependencies"
flutter pub get >/dev/null

echo "→ Format"
dart format --output=none --set-exit-if-changed app/lib app/test

echo "→ Analyze"
(cd app && flutter analyze --fatal-infos)

echo "→ Test"
(cd app && flutter test)

echo "✓ All checks passed"
