#!/usr/bin/env bash
# Wraps the Flutter Linux bundle into a Debian package.
# Usage: tool/package_deb.sh <version> <bundle-dir> <out.deb>
set -euo pipefail

version="$1"
bundle="$2"
out="$3"
root="$(mktemp -d)"
here="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$root/DEBIAN" "$root/opt/whowolf" "$root/usr/bin"
cp -r "$bundle"/. "$root/opt/whowolf/"
ln -s /opt/whowolf/whowolf "$root/usr/bin/whowolf"
"$here/tool/linux/install_share.sh" "$root/usr"

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
 Open-source werewolf game for one room: every player uses their own
 device and the app is the narrator, so nobody has to sit out as game
 master. End-to-end encrypted, no account.
CONTROL

dpkg-deb --build --root-owner-group "$root" "$out"
rm -rf "$root"
