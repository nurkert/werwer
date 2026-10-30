#!/usr/bin/env bash
# Wraps the Flutter Linux bundle into an AppImage that runs on most
# distributions without installing: make it executable and start it.
# Usage: tool/package_appimage.sh <version> <bundle-dir> <out.AppImage>
#
# appimagetool and the AppImage runtime are pinned to a version and a sha256
# below; the script downloads them to $APPIMAGE_TOOLS (default: a temporary
# directory) and checks them before it runs anything. appimagetool is itself
# an AppImage and runs with --appimage-extract-and-run, so no FUSE is needed.
#
# No system library goes into the image: GTK, GLib, Mesa, libsecret and
# GStreamer come from the system (a bundled GTK breaks on Wayland and with
# other Mesa versions). Only the bundle's own libraries ride along, found
# through the app's RUNPATH ($ORIGIN/lib). The script fails if one slips in.
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: $0 <version> <bundle-dir> <out.AppImage>" >&2; exit 2; }
version=$1
bundle=$(cd "$2" && pwd)
mkdir -p "$(dirname "$3")"
out="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  { echo "error: version must look like 0.1.0, got: $version" >&2; exit 2; }
[[ -x $bundle/whowolf && -d $bundle/lib && -d $bundle/data ]] ||
  { echo "error: $bundle is not the Flutter Linux bundle" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)

# Raise both lines of a tool together.
tool_url=https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage
tool_sha256=ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
runtime_url=https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64
runtime_sha256=2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
tools=${APPIMAGE_TOOLS:-$work/tools}
mkdir -p "$tools"

# Fetches url to file unless it is already there with sum; a file with the
# wrong sum is deleted and never run.
fetch() {
  local url=$1 sum=$2 file=$3
  if [[ ! -f $file ]] || ! echo "$sum  $file" | sha256sum -c --quiet - >/dev/null 2>&1; then
    curl -fsSL --retry 3 -o "$file.part" "$url"
    mv "$file.part" "$file"
  fi
  echo "$sum  $file" | sha256sum -c --quiet - ||
    { echo "error: $file does not match its pinned sha256" >&2; rm -f "$file"; exit 1; }
}
fetch "$tool_url" "$tool_sha256" "$tools/appimagetool-x86_64.AppImage"
fetch "$runtime_url" "$runtime_sha256" "$tools/runtime-x86_64"
chmod 0755 "$tools/appimagetool-x86_64.AppImage"

appdir="$work/Whowolf.AppDir"
mkdir -p "$appdir/usr/lib/whowolf"
cp -R "$bundle"/. "$appdir/usr/lib/whowolf/"
"$here/linux/install_share.sh" "$appdir/usr"
cat >"$appdir/AppRun" <<'APPRUN'
#!/bin/sh
# Starts Whowolf from the AppImage. No LD_LIBRARY_PATH: the app finds its
# own libraries through its RUNPATH, everything else comes from the system.
here="$(dirname "$(readlink -f "$0")")"
exec "$here/usr/lib/whowolf/whowolf" "$@"
APPRUN
chmod 0755 "$appdir/AppRun"
install -m 0644 "$here/linux/de.whowolf.app.desktop" "$appdir/de.whowolf.app.desktop"
install -m 0644 "$here/linux/icons/de.whowolf.app-256.png" "$appdir/de.whowolf.app.png"
ln -s de.whowolf.app.png "$appdir/.DirIcon"

forbidden=$(find "$appdir" \( -name 'libgtk*' -o -name 'libgdk*' -o -name 'libglib*' -o -name 'libgio*' \
  -o -name 'libwayland*' -o -name 'libEGL*' -o -name 'libGL*' -o -name 'libsecret*' -o -name 'libgst*' \) | head -n 5)
if [[ -n $forbidden ]]; then
  echo "error: the AppImage would bundle system libraries:" >&2
  echo "$forbidden" >&2
  exit 1
fi

rm -f "$out"
ARCH=x86_64 VERSION="$version" "$tools/appimagetool-x86_64.AppImage" --appimage-extract-and-run \
  --no-appstream --runtime-file "$tools/runtime-x86_64" "$appdir" "$out"
chmod 0755 "$out"
echo "built $out"
