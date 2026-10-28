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

echo "→ Design tokens"
dart run tool/tokens.dart --check

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
# The rules and the protocol also run in browsers (players join there):
# numbers behave differently in JavaScript, so they are tested there too.
for package in packages/game_core packages/protocol; do
  echo "▶ $package (browser)"
  (cd "$package" && dart test --platform chrome --reporter=compact)
done
# Players without the app connect from a real browser, also through the
# relay; the relay and the host run in the VM next to it.
echo "▶ server (browser)"
(cd server && dart test --platform chrome --reporter=compact test/browser_relay_test.dart)
(cd app && flutter test)

echo "✓ All checks passed"
