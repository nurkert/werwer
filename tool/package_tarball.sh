#!/usr/bin/env bash
# Packs the Flutter Linux bundle as a plain archive for any distribution:
# unpack it anywhere and start whowolf/whowolf. share/ holds the desktop
# entry and icons for whoever wants to link them in.
# Usage: tool/package_tarball.sh <version> <bundle-dir> <out.tar.gz>
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: $0 <version> <bundle-dir> <out.tar.gz>" >&2; exit 2; }
bundle=$(cd "$2" && pwd)
mkdir -p "$(dirname "$3")"
out="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"
[[ -x $bundle/whowolf ]] || { echo "error: $bundle is not the Flutter Linux bundle" >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/whowolf"
cp -R "$bundle"/. "$work/whowolf/"
"$here/linux/install_share.sh" "$work/whowolf"
tar -C "$work" --owner=0 --group=0 --numeric-owner -czf "$out" whowolf
echo "built $out"
