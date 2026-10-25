# Prompts: stage assets (sheets, frame, backdrop)

Generated with Codex CLI 0.164.0 (built-in image generation), 2026-10-25. Attached references: `design/reference/mondbuehne.jpg` (+ character sheets where named).
Common header: match the "Mondbühne" style exactly (flat 2D cartoon cutouts, bold dark outlines, light cardboard edge, early-2000s TV cartoon look, generic, original designs, no text).
Sheet rule: TRANSPARENT background with real alpha, no glow/halo/shadows, elements complete and separated by wide transparent gaps.

- `sheets/sheet_figures.png` → `source/figures/{seherin,dorfbewohner,magd}.png`: three full-body cutout puppets on sticks (seer and villager from their reference sheets, plus a new villager woman with red hair, white headscarf, red skirt, apron and wooden bucket).
- `source/figures/werwolf.png`: single full-body cutout of the werewolf (three-quarter view facing right, sly grin, stick at the bottom), transparent background; references: style + `characters/werwolf.jpg`.
- `sheets/sheet_props.png` → `source/props/*.png`: row of 4 half-timbered houses, church tower, two pine trees, bush, rocks, fence segment, barrel, crate, lantern on a post – each on a small wooden stand.
- `source/stage/rahmen.png`: puppet-theatre frame only (carved wooden proscenium with gold trim and sun ornament, red velvet curtains gathered at the sides, stage floor edge with scalloped footlight covers), central opening fully transparent.
- `source/stage/prospekt.png`: painted night backdrop (indigo sky, stars, clouds, big cream moon, mountains, castle on a hill, hills and pine forest), opaque.

Cutting: `tool/assets/slice_sheet.py` (sheets) and `tool/assets/clean_alpha.py` (single images) remove generator glow and split elements by alpha.
