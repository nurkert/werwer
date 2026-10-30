#!/usr/bin/env bash
# Wraps the Flutter Linux bundle into a single-file Flatpak bundle, installable
# with `flatpak install --user whowolf-*.flatpak`; Flatpak fetches the runtime
# from Flathub on install.
# Usage: tool/package_flatpak.sh <version> <bundle-dir> <out.flatpak>
#
# Needs flatpak and flatpak-builder (apt install flatpak flatpak-builder).
# Adds the Flathub remote for the user if missing and installs the runtime
# and SDK of tool/flatpak/de.whowolf.app.yml there.
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: $0 <version> <bundle-dir> <out.flatpak>" >&2; exit 2; }
version=$1
bundle=$(cd "$2" && pwd)
mkdir -p "$(dirname "$3")"
out="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
  { echo "error: version must look like 0.1.0, got: $version" >&2; exit 2; }
[[ -x $bundle/whowolf ]] || { echo "error: $bundle is not the Flutter Linux bundle" >&2; exit 1; }
for tool in flatpak flatpak-builder; do
  command -v "$tool" >/dev/null ||
    { echo "error: $tool missing (apt install flatpak flatpak-builder)" >&2; exit 1; }
done
here=$(cd "$(dirname "$0")" && pwd)
flathub=https://dl.flathub.org/repo/flathub.flatpakrepo

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp "$here/flatpak/de.whowolf.app.yml" "$work/"
cp -R "$bundle" "$work/bundle"
cp -R "$here/linux" "$work/linux"

flatpak remote-add --user --if-not-exists flathub "$flathub"
flatpak-builder --user --install-deps-from=flathub --disable-rofiles-fuse --force-clean \
  --default-branch=stable --subject="Whowolf $version" \
  --repo="$work/repo" "$work/build" "$work/de.whowolf.app.yml"
rm -f "$out"
flatpak build-bundle --runtime-repo="$flathub" "$work/repo" "$out" de.whowolf.app stable
echo "built $out"
