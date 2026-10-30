#!/usr/bin/env bash
# Installs what every Linux package shares under <prefix>/share: the desktop
# entry, the AppStream metadata and the icons (128, 256 and 512 px).
# Usage: tool/linux/install_share.sh <prefix>   e.g. "$root/usr" or /app
set -euo pipefail

[[ $# -eq 1 ]] || { echo "usage: $0 <prefix>" >&2; exit 2; }
prefix=$1
here=$(cd "$(dirname "$0")" && pwd)

install -D -m 0644 "$here/de.whowolf.app.desktop" "$prefix/share/applications/de.whowolf.app.desktop"
install -D -m 0644 "$here/de.whowolf.app.metainfo.xml" "$prefix/share/metainfo/de.whowolf.app.metainfo.xml"
for size in 128 256 512; do
  install -D -m 0644 "$here/icons/de.whowolf.app-$size.png" \
    "$prefix/share/icons/hicolor/${size}x${size}/apps/de.whowolf.app.png"
done
