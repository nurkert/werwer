#!/usr/bin/env bash
# Packs the web build (app/build/web, from tool/build_webapp.sh) as one
# release file for relay servers that serve the web app (server/web_apps):
# the whole build including the app's pictures and sounds, compressible
# files gzipped, byte for byte reproducible.
#
#   tool/package_webapp.sh <version> <out.tar.gz>
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: tool/package_webapp.sh <version> <out.tar.gz>" >&2
  exit 2
fi
root=$(cd "$(dirname "$0")/.." && pwd)
web="$root/app/build/web"
if [[ ! -f "$web/index.html" ]]; then
  echo "error: $web/index.html is missing; run tool/build_webapp.sh first" >&2
  exit 1
fi
out=$(cd "$(dirname "$2")" && pwd)/$(basename "$2")
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

cp -R "$web/." "$stage/"
# Nothing that could outlive a game in the browser.
rm -f "$stage"/flutter_service_worker.js "$stage"/.last_build_id
find "$stage" -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.wasm' \
  -o -name '*.json' -o -name '*.html' -o -name '*.css' -o -name '*.otf' \
  -o -name '*.ttf' -o -name NOTICES \) -exec gzip -9 -n {} \;
tar --sort=name --owner=0 --group=0 --numeric-owner --mtime='@0' \
  -C "$stage" -cf - . | gzip -9 -n > "$out"
echo "Web app $1: $(du -h "$out" | cut -f1) in $out"
