# Web app, served by the host

`tool/build_webapp.sh` fills this folder with the web build of the app, so
the host's phone can serve it to players who join in the browser. The
files are generated and not in git (only this note is); without them the
app works as before, just without joining in the browser.

Paths are flattened (`canvaskit/canvaskit.wasm` is `canvaskit__canvaskit.wasm`)
and large files are gzip-compressed (`.gz`). The app's own pictures, sounds
and fonts are not copied: the host serves them from its own bundle.
