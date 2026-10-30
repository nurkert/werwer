#!/usr/bin/env bash
# Wraps the Flutter Linux bundle into an RPM for Fedora, openSUSE and relatives.
# Usage: tool/package_rpm.sh <version> <bundle-dir> <out.rpm>
#
# Needs rpmbuild (Debian/Ubuntu: apt install rpm). The dependencies are named
# by library (libgtk-3.so.0 …), which every RPM distribution provides under
# that name; only the GStreamer plugins have no library and are named per
# distribution. Automatic dependency scanning is off: it would also list the
# bundle's own libraries.
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: $0 <version> <bundle-dir> <out.rpm>" >&2; exit 2; }
version=$1
bundle=$(cd "$2" && pwd)
mkdir -p "$(dirname "$3")"
out="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  { echo "error: version must look like 0.1.0, got: $version" >&2; exit 2; }
[[ -x $bundle/whowolf ]] || { echo "error: $bundle is not the Flutter Linux bundle" >&2; exit 1; }
command -v rpmbuild >/dev/null ||
  { echo "error: rpmbuild missing (apt install rpm / dnf install rpm-build)" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
stage="$work/stage"
mkdir -p "$stage/opt/whowolf" "$stage/usr/bin"
cp -r "$bundle"/. "$stage/opt/whowolf/"
ln -s /opt/whowolf/whowolf "$stage/usr/bin/whowolf"
"$here/linux/install_share.sh" "$stage/usr"

cat >"$work/whowolf.spec" <<SPEC
Name:           whowolf
Version:        $version
Release:        1
Summary:        Werewolf party game at the table, everyone on their own phone
License:        Apache-2.0
URL:            https://whowolf.de
BuildArch:      x86_64
AutoReqProv:    no
Requires:       libgtk-3.so.0()(64bit)
Requires:       libsecret-1.so.0()(64bit)
Requires:       libasound.so.2()(64bit)
Requires:       libEGL.so.1()(64bit)
Requires:       libGLESv2.so.2()(64bit)
Requires:       libgstreamer-1.0.so.0()(64bit)
Requires:       (gstreamer1-plugins-good or gstreamer-plugins-good)

%global debug_package %{nil}
%global __os_install_post %{nil}
%define _build_id_links none

%description
Open-source werewolf game for one room: every player uses their own device
and the app is the narrator, so nobody has to sit out as game master.
End-to-end encrypted, no account.

%install
cp -a "$stage"/. %{buildroot}/

%files
/opt/whowolf
/usr/bin/whowolf
/usr/share/applications/de.whowolf.app.desktop
/usr/share/metainfo/de.whowolf.app.metainfo.xml
/usr/share/icons/hicolor/*/apps/de.whowolf.app.png
SPEC

rpmbuild --quiet -bb --define "_topdir $work/rpm" "$work/whowolf.spec"
cp "$work/rpm/RPMS/x86_64/whowolf-$version-1.x86_64.rpm" "$out"
echo "built $out"
