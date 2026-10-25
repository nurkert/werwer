#!/usr/bin/env bash
# Everything CI checks, runnable locally. Green here means green in CI.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "→ Personal signing data"
tool/check_no_personal_ids.sh

echo "→ Toolchain"
flutter --version | head -1

echo "→ Dependencies"
flutter pub get

echo "→ Format"
dart format --output=none --set-exit-if-changed app/lib app/test packages server

echo "→ Analyze"
dart analyze --fatal-infos packages server
(cd app && flutter analyze --fatal-infos)

echo "→ Test"
for package in packages/*/ server/; do
  echo "  $package"
  (cd "$package" && dart test --reporter=compact)
done
(cd app && flutter test)

echo "✓ All checks passed"
