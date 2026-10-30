#!/usr/bin/env bash
# Packs Whowolf.app into the designed disk image: the app and a link to
# Applications on the night-stage background, ready to drag across.
#
#   tool/package_dmg.sh VERSION path/to/Whowolf.app dist/whowolf-VERSION-macos.dmg
#
# A notarized app (ticket stapled, tool/apple_release.sh) gets background.tiff;
# any other build gets background-unsigned.tiff, which says how to open it the
# first time. The image itself stays unsigned: Gatekeeper checks the app in it.
#
# Needs dmgbuild, pinned in tool/dmg/requirements.txt:
#   python3 -m venv .venv-dmg && .venv-dmg/bin/pip install --require-hashes --no-deps -r tool/dmg/requirements.txt
# then DMGBUILD=.venv-dmg/bin/dmgbuild (default: dmgbuild on the PATH).
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: $0 VERSION path/to/Whowolf.app out.dmg" >&2; exit 2; }
version=$1
app=$2
out=$3
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  { echo "error: version must look like 0.1.0, got: $version" >&2; exit 2; }
[[ -d $app && $(basename "$app") == Whowolf.app ]] ||
  { echo "error: $app is not a Whowolf.app bundle (flutter build macos first)" >&2; exit 1; }
dmgbuild=${DMGBUILD:-dmgbuild}
command -v "$dmgbuild" >/dev/null ||
  { echo "error: dmgbuild missing; install it from tool/dmg/requirements.txt (see the header of $0)" >&2; exit 1; }

here=$(cd "$(dirname "$0")/dmg" && pwd)
icon="$app/Contents/Resources/AppIcon.icns"
[[ -f $icon ]] || { echo "error: $icon missing" >&2; exit 1; }
codesign --verify --deep --strict "$app" ||
  { echo "error: the signature of $app is broken; rebuild it" >&2; exit 1; }

if xcrun stapler validate -q "$app" 2>/dev/null; then
  background="$here/background.tiff"
  echo "Notarized app: plain background."
else
  background="$here/background-unsigned.tiff"
  echo "Not notarized: background with the first-launch hint."
fi

mkdir -p "$(dirname "$out")"
rm -f "$out"
"$dmgbuild" -s "$here/settings.py" \
  -D app="$app" -D background="$background" -D icon="$icon" \
  "Whowolf $version" "$out"
hdiutil verify -quiet "$out"

# The image must hold exactly what the player drags: the app and the link.
mount=$(mktemp -d)
hdiutil attach -nobrowse -readonly -mountpoint "$mount" "$out" >/dev/null
trap 'hdiutil detach -quiet "$mount" || true; rmdir "$mount" 2>/dev/null || true' EXIT
[[ -d "$mount/Whowolf.app" ]] || { echo "error: Whowolf.app missing in $out" >&2; exit 1; }
[[ $(readlink "$mount/Applications") == /Applications ]] ||
  { echo "error: the Applications link is missing in $out" >&2; exit 1; }
codesign --verify --deep --strict "$mount/Whowolf.app" ||
  { echo "error: the app in $out fails its signature check" >&2; exit 1; }
echo "Disk image: $out ($(du -h "$out" | cut -f1))"
