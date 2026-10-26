#!/usr/bin/env bash
# Builds the web app and puts it into app/assets/webapp/, flattened and
# compressed, so the host's phone can serve it to players who join in the
# browser (see app/assets/webapp/README.md). Run it before building the
# app for a release; CI does.
#
#   tool/build_webapp.sh
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root/app"
out=assets/webapp

# The web app must not contain an older copy of itself.
find "$out" -mindepth 1 ! -name README.md -delete

flutter build web --release --no-web-resources-cdn --no-tree-shake-icons \
  --dart-define=APP_VERSION="${APP_VERSION:-dev}"

web=build/web
# What the browser needs. The app's own assets (build/web/assets/assets)
# stay out: the host serves them from its own bundle.
files=(
  index.html flutter_bootstrap.js main.dart.js sodium.js splash.css
  manifest.json favicon.png version.json
  canvaskit/canvaskit.js canvaskit/canvaskit.wasm
)
while IFS= read -r f; do files+=("${f#"$web"/}"); done < <(
  find "$web/icons" "$web/assets" -type f ! -path "$web/assets/assets/*" | sort
)

for f in "${files[@]}"; do
  if [[ ! -f "$web/$f" ]]; then
    echo "error: $web/$f is missing; did the web build change?" >&2
    exit 1
  fi
  flat="$out/${f//\//__}"
  case "$f" in
    *.js | *.wasm | *.json | NOTICES | */NOTICES | *.html | *.css | *.otf)
      gzip -9 -n -c "$web/$f" > "$flat.gz" ;;
    *)
      cp "$web/$f" "$flat" ;;
  esac
done

echo "Web app: $(du -sh "$out" | cut -f1) in $out"
