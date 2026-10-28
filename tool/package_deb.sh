#!/usr/bin/env bash
# Wraps the Flutter Linux bundle into a Debian package.
# Usage: tool/package_deb.sh <version> <bundle-dir> <out.deb>
set -euo pipefail

version="$1"
bundle="$2"
out="$3"
root="$(mktemp -d)"
here="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$root/DEBIAN" "$root/opt/whowolf" "$root/usr/bin" \
  "$root/usr/share/applications" "$root/usr/share/icons/hicolor/256x256/apps"
cp -r "$bundle"/. "$root/opt/whowolf/"
ln -s /opt/whowolf/whowolf "$root/usr/bin/whowolf"
cp "$here/app/assets/icon/icon.png" "$root/usr/share/icons/hicolor/256x256/apps/de.whowolf.app.png"

cat > "$root/usr/share/applications/de.whowolf.app.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Whowolf
Comment=Werewolf at the table. Everyone on their own phone.
Exec=/opt/whowolf/whowolf
Icon=de.whowolf.app
Categories=Game;BoardGame;
Terminal=false
DESKTOP

cat > "$root/DEBIAN/control" <<CONTROL
Package: whowolf
Version: ${version}
Section: games
Priority: optional
Architecture: amd64
Maintainer: Whowolf contributors <https://github.com/nurkert/whowolf>
Depends: libgtk-3-0, libsecret-1-0, libasound2t64 | libasound2, libegl1, libgles2, libgstreamer1.0-0, libgstreamer-plugins-base1.0-0, gstreamer1.0-plugins-good
Homepage: https://whowolf.de
Description: Werewolf party game at the table, everyone on their own phone
 Open-source social deduction game; the app is the narrator.
 Pre-release build: a concept in development, nothing playable yet.
CONTROL

dpkg-deb --build --root-owner-group "$root" "$out"
rm -rf "$root"
