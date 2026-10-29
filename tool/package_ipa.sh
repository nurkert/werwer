#!/usr/bin/env bash
# Wraps the unsigned iOS app into an .ipa for AltStore Classic, where each
# player's own Apple ID signs it on the device, and writes what AltStore
# checks it against: version, build and the app's permissions, read from the
# built app itself so the source can never promise something else.
# Usage: tool/package_ipa.sh <Runner.app> <out.ipa> <out-altstore.json>
set -euo pipefail

app="$1"
out="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
meta="$3"

plist="$app/Info.plist"
if [[ ! -f "$plist" ]]; then
  echo "error: $app has no Info.plist; build it first with: flutter build ios --release --no-codesign" >&2
  exit 1
fi

root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
mkdir "$root/Payload"
cp -R "$app" "$root/Payload/"
# Fixed dates and no extra attributes: the same build gives the same file.
find "$root/Payload" -exec touch -h -t 202001010000 {} +
rm -f "$out"
(cd "$root" && zip -qrX -y "$out" Payload)

# The entitlements in the binary (none for an unsigned build) and every
# privacy text from Info.plist.
entitlements="$root/entitlements.plist"
codesign -d --entitlements "$entitlements" --xml "$app" 2>/dev/null || true
plutil -convert json -o "$root/info.json" "$plist"
if [[ -s "$entitlements" ]]; then
  plutil -convert json -o "$root/entitlements.json" "$entitlements"
else
  echo '{}' > "$root/entitlements.json"
fi

python3 -I - "$root/info.json" "$root/entitlements.json" "$meta" <<'PY'
import json, sys
info = json.load(open(sys.argv[1]))
entitlements = json.load(open(sys.argv[2]))
# AltStore does not want these two listed (they come from the signer).
skip = {"application-identifier", "com.apple.developer.team-identifier"}
meta = {
    "bundleIdentifier": info["CFBundleIdentifier"],
    "version": info["CFBundleShortVersionString"],
    "buildVersion": info["CFBundleVersion"],
    "minOSVersion": info.get("MinimumOSVersion", "15.0"),
    "appPermissions": {
        "entitlements": sorted(k for k in entitlements if k not in skip),
        "privacy": {
            k: v for k, v in sorted(info.items())
            if k.startswith("NS") and k.endswith("UsageDescription")
        },
    },
}
json.dump(meta, open(sys.argv[3], "w"), indent=2, ensure_ascii=False)
PY
echo "wrote $out and $meta"
