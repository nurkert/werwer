#!/usr/bin/env bash
# Renders the disk image background from background.svg: one TIFF with 1x and
# 2x each, so Finder draws it sharp on Retina displays, plus a 2x preview.png
# to look at.
#
#   background.tiff           notarized builds (tool/apple_release.sh)
#   background-unsigned.tiff  unsigned builds: says how to open them the first time
#
# Type is Ancizar Serif and Manrope from app/assets/fonts, used through an own
# fontconfig so the result does not depend on the fonts of this machine.
#
# Needs rsvg-convert (brew install librsvg) and tiffutil (macOS). The TIFFs
# are checked in: whoever changes the SVG runs this script and commits them.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
for tool in rsvg-convert tiffutil; do
  command -v "$tool" >/dev/null ||
    { echo "error: $tool missing (rsvg-convert: brew install librsvg; tiffutil comes with macOS)" >&2; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat >"$work/fonts.conf" <<CONF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig><dir>$root/app/assets/fonts</dir><cachedir>$work/cache</cachedir></fontconfig>
CONF
export FONTCONFIG_FILE="$work/fonts.conf"
# librsvg only loads images next to the SVG.
cp "$root/design/source/brand/wordmark.png" "$work/"

render() { # <first-launch line, XML-escaped> <output.tiff> [preview.png]
  sed "s|@FIRST_LAUNCH@|$1|" "$here/background.svg" >"$work/background.svg"
  rsvg-convert -w 660 -h 420 "$work/background.svg" -o "$work/1x.png"
  rsvg-convert -w 1320 -h 840 "$work/background.svg" -o "$work/2x.png"
  tiffutil -cathidpicheck "$work/1x.png" "$work/2x.png" -out "$2"
  if [[ $# -eq 3 ]]; then cp "$work/2x.png" "$3"; fi
}

render 'Notarized by Apple · start Whowolf from Applications' "$here/background.tiff"
render 'First launch: System Settings › Privacy \&amp; Security › Open Anyway' \
  "$here/background-unsigned.tiff" "$here/preview.png"
ls -l "$here"/*.tiff "$here/preview.png"
