#!/usr/bin/env bash
# Builds the app and installs/launches it on a connected or Wi-Fi-paired iPhone,
# without attaching a debugger (`flutter run` can leave the app paused in lldb).
#
# Usage: tool/deploy_ios.sh [--release|--profile] [device-udid]
#   Default: --profile. Signing comes from app/ios/Flutter/Signing.xcconfig (git-ignored):
#     DEVELOPMENT_TEAM = <your team id>
#     CODE_SIGN_STYLE = Automatic
set -euo pipefail
cd "$(dirname "$0")/../app"

mode="--profile"
device=""
for arg in "$@"; do
  case "$arg" in
    --*) mode="$arg" ;;
    *) device="$arg" ;;
  esac
done

if [[ ! -f ios/Flutter/Signing.xcconfig ]]; then
  echo "Missing app/ios/Flutter/Signing.xcconfig with your DEVELOPMENT_TEAM (see the header of this script)." >&2
  exit 1
fi

if [[ -z "$device" ]]; then
  list="$(mktemp)"
  xcrun devicectl list devices --json-output "$list" >/dev/null 2>&1 || true
  device="$(python3 - "$list" <<'PY'
import json, sys
try:
    devices = json.load(open(sys.argv[1]))["result"]["devices"]
except Exception:
    devices = []
for d in devices:
    hw, conn = d["hardwareProperties"], d["connectionProperties"]
    if hw.get("platform") == "iOS" and hw.get("reality") == "physical" and conn.get("pairingState") == "paired":
        print(hw["udid"])
        break
PY
)"
  rm -f "$list"
fi
if [[ -z "$device" ]]; then
  echo "No paired iPhone found. Connect it (or enable Wi-Fi pairing in Xcode) and unlock it." >&2
  exit 1
fi

bundle_id="de.whowolf.app"
version="$(git describe --tags --always --dirty 2>/dev/null || echo dev)"

echo "→ Building ($mode, version $version)"
# Icon tree shaking (font-subset) sometimes hangs on this machine; it
# saves only a few kilobytes, so it is off for device builds.
flutter build ios "$mode" --no-tree-shake-icons --dart-define=APP_VERSION="$version"

echo "→ Installing on $device"
xcrun devicectl device install app --device "$device" build/ios/iphoneos/Runner.app

echo "→ Launching $bundle_id"
xcrun devicectl device process launch --terminate-existing --device "$device" "$bundle_id"
