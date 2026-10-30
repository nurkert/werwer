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

echo "→ Web app lock"
tool/check_webapps_lock.sh
tool/test_fetch_webapps.sh

echo "→ Shell scripts"
command -v shellcheck >/dev/null ||
  { echo "error: shellcheck missing (brew install shellcheck / apt install shellcheck)" >&2; exit 1; }
shellcheck server/deploy/update.sh tool/test_update_rollback.sh tool/package_dmg.sh tool/dmg/render_background.sh tool/apple_release.sh \
  tool/package_deb.sh tool/package_rpm.sh tool/package_appimage.sh tool/package_flatpak.sh tool/package_tarball.sh \
  tool/linux/install_share.sh tool/smoke_linux.sh \
  tool/package_windows_setup.sh tool/check_windows_setup.sh tool/windows/render_wizard.sh

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
# The browser's way back to its seat, in a real browser.
echo "▶ app (browser)"
(cd app && flutter test --platform chrome test/browser/)

echo "✓ All checks passed"
