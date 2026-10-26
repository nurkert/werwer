#!/usr/bin/env bash
# Checks that this machine can build and test Whowolf, and says exactly what
# to do about anything missing. Read-only: it never installs or changes things.
set -uo pipefail
cd "$(dirname "$0")/.."

problems=0
ok() { printf '  ✓ %s\n' "$1"; }
warn() { printf '  • %s\n    → %s\n' "$1" "$2"; }
fail() { printf '  ✗ %s\n    → %s\n' "$1" "$2"; problems=$((problems + 1)); }

echo "Whowolf doctor"

echo "Required"
want_flutter=$(sed -n 's/^  flutter: *//p' app/pubspec.yaml | head -1)
if command -v flutter >/dev/null 2>&1; then
  have_flutter=$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9.]*\).*/\1/p' | head -1)
  if [ "$have_flutter" = "$want_flutter" ]; then
    ok "Flutter $have_flutter"
  else
    fail "Flutter $have_flutter, the project pins $want_flutter" \
      "Install Flutter $want_flutter (e.g. with fvm: fvm install $want_flutter)."
  fi
else
  fail "Flutter not found" "Install Flutter $want_flutter: https://docs.flutter.dev/get-started/install"
fi
if command -v git >/dev/null 2>&1; then ok "git"; else fail "git not found" "Install git."; fi

echo "Apple platforms (iPhone, Mac)"
if [ "$(uname)" = "Darwin" ]; then
  if xcodebuild -version >/dev/null 2>&1; then ok "$(xcodebuild -version | head -1)"; else fail "Xcode not found" "Install Xcode from the App Store, then: sudo xcodebuild -runFirstLaunch"; fi
  if command -v pod >/dev/null 2>&1; then ok "CocoaPods $(pod --version)"; else fail "CocoaPods not found" "brew install cocoapods  (needed by the speech and storage plugins)"; fi
  for f in app/ios/Flutter/Signing.xcconfig app/macos/Flutter/Signing.xcconfig; do
    if [ -f "$f" ]; then ok "$f (local, git-ignored)"; else warn "$f missing" "Only needed to run on your own device: put 'DEVELOPMENT_TEAM = <your team id>' into it (see CLAUDE.md)."; fi
  done
else
  warn "Not a Mac" "iPhone and Mac builds need macOS; Android, Linux and Windows work here."
fi

echo "Website"
if command -v node >/dev/null 2>&1; then ok "Node $(node --version)"; else warn "Node not found" "Only for website/: install Node 22 or newer."; fi

echo "Optional"
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then ok "Docker (relay image)"; else warn "No running Docker" "Only for the relay server: start Docker Desktop or 'colima start'."; fi
if command -v gitleaks >/dev/null 2>&1; then ok "gitleaks (secret scan)"; else warn "gitleaks not found" "CI scans anyway; locally: brew install gitleaks"; fi
if command -v osv-scanner >/dev/null 2>&1; then ok "osv-scanner"; else warn "osv-scanner not found" "CI scans anyway; locally: brew install osv-scanner"; fi

echo
if [ "$problems" -eq 0 ]; then
  echo "✓ Ready. Next: tool/check.sh"
else
  echo "✗ $problems problem(s) above. Fix them, then run tool/doctor.sh again."
  exit 1
fi
