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

## Depth planes for the landing hero (replaces the single `prospekt.png` there)

Generated with Codex CLI 0.164.0, 2026-10-25, three generations. Attached references: `source/stage/prospekt.png` (content and palette), `source/props/haeuser.png`, `source/props/tanne_1.png`, `source/props/busch.png` (cardboard cutout style). The exact prompts are embedded in the PNGs (`impeccable embed-prompt --read <file>`).

- `sheets/sheet_stage_far.png` → `source/stage/{ebene_berge,ebene_mond,ebene_wolke_1,ebene_wolke_2,ebene_wolke_3}.png`: long mountain strip with the castle, moon disc, three clouds, all with the cardboard rim, transparent sheet. `ebene_berge.png` was dimmed (brightness 0.8, saturation 0.85) so the far plane sits back.
- `sheets/sheet_stage_near.png` → `source/stage/{ebene_huegel,ebene_wiese}.png`: forested hill strip and near meadow strip. The bottom cardboard rim of `ebene_wiese.png` was cropped so the meadow runs into a flat fill below.
- `source/stage/ebene_himmel.png`: opaque painted night sky without moon or landscape. Colour-graded towards the `prospekt.png` sky (stars kept as generated).

Cutting: `tool/assets/slice_sheet.py`.
