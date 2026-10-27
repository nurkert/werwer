# Design credits

All artwork in this folder is original to the Whowolf project. AI-generated assets are listed with tool, date and prompt so they can be traced and regenerated.

| File | Tool | Date | Prompt |
|---|---|---|---|
| `reference/boards/board_{a..e}.png` (concept boards for every screen), `reference/boards/board_f.png` (puppets in 3D) | Codex CLI 0.164.0 (image generation) | 2026-10-27 | [`prompts/board_a.md`](prompts/board_a.md) … [`prompts/board_f.md`](prompts/board_f.md) |
| `source/scenes/*.png` → `app/assets/stage/*.webp` (painted stage sets per scene, without moon, task 012) | Codex CLI 0.164.0 (image generation) | 2026-10-27 | shared text in [`prompts/scenes.md`](prompts/scenes.md) |
| `sheets/poses/<persona>.png` → `source/figures/poses/<persona>_<n>.png` → `app/assets/figures/poses/*.webp` (three villager poses per persona) | Codex CLI 0.164.0 (image generation) | 2026-10-27 | [`prompts/poses.md`](prompts/poses.md) |
| `store/{de,en}/*.jpg` (App Store screenshots, 6.7" iPhone, 1290 × 2796) | rendered from the app by `app/test/screens_test.dart` (`PIXEL_RATIO=3 SCREEN_SIZE=430x932`) | 2026-10-27 | none |
| `sheets/scenery/*.png` → `source/scenery/*.png` → `app/assets/stage/scenery/*.webp` (sixteen cardboard scenery pieces: trees, house, stall, fences, curtains, hanging branches, garland, valance) | Codex CLI 0.164.0 (image generation) | 2026-10-27 | [`prompts/scenery.md`](prompts/scenery.md) |
| `app/assets/icon/*.png` (app icon: village set, moon, werewolf, seer and farmer, wordmark) | composed with ImageMagick from the project's own assets | 2026-10-27 | none |
| `reference/ui_concept_v1.png` (UI concept board, direction for task 012) | Codex CLI 0.164.0 (image generation) | 2026-10-27 | [`prompts/ui_concept.md`](prompts/ui_concept.md) |
| `reference/mondbuehne.jpg` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/mondbuehne.md`](prompts/mondbuehne.md) |
| `characters/werwolf.jpg` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/characters.md`](prompts/characters.md) |
| `characters/seherin.jpg` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/characters.md`](prompts/characters.md) |
| `characters/dorfbewohner.jpg` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/characters.md`](prompts/characters.md) |
| `sheets/*`, `source/**` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/stage.md`](prompts/stage.md) |
| `sheets/logo_sheet.png`, `source/brand/*`, `sheets/cast_*.png`, new `source/figures/*` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/brand_and_cast.md`](prompts/brand_and_cast.md) |
| `sheets/sheep_sheet.png` → `source/sheep/*` | Codex CLI 0.164.0 (image generation) | 2026-10-25 | four sheep in a jump cycle, black sheep, lamb, meadow stile, meadow mound, dream stars; transparent sheet cut with `tool/assets/slice_sheet.py` |
| `sheets/logo_sheet.png`… see above; `.impeccable/mocks/*` (direction comps, not shipped) | Codex CLI 0.164.0 | 2026-10-25 | prompts embedded in the PNG files |
| `assets/plates/*`, `website/src/assets/plates/*` (game-box world: box, table cluster, lantern, decor, felt) | Codex CLI 0.164.0 (image generation from comp region crops) | 2026-10-25 | prompt embedded in each PNG (`impeccable embed-prompt --read`) |
| `sheets/sheet_stage_far.png`, `sheets/sheet_stage_near.png` → `source/stage/ebene_*.png` (hero depth planes: sky, moon, clouds, mountains with castle, hills, meadow) | Codex CLI 0.164.0 (image generation) | 2026-10-25 | [`prompts/stage.md`](prompts/stage.md), prompts embedded in the sheets and in `ebene_himmel.png` |
| `source/stage/box-tray.png` (open box interior for the unboxing animation) | Codex CLI 0.164.0 | 2026-10-25 | prompt embedded in the PNG |
| `sheets/cast_village_{a,b,c}.png` → `source/figures/{baeckerin,fischerin,schneiderin,gaensehirtin,wirtin,schmied,mueller,spielmann,imker}.png` (village ensemble) | Codex CLI 0.164.0 (image generation) | 2026-10-26 | [`prompts/village_ensemble.md`](prompts/village_ensemble.md) |
| `sheets/cast_village_{d,e,f}.png` → nine more villagers; `sheets/roles/<persona>.png` → `source/figures/roles/<persona>_<role>.png` (every persona in every role's costume) | Codex CLI 0.164.0 (image generation) | 2026-10-26 | [`prompts/village_ensemble.md`](prompts/village_ensemble.md), [`prompts/costumes.md`](prompts/costumes.md) |

## Third-party icons

Platform logos on the download page come from [Simple Icons](https://simpleicons.org) 16.34.0 (CC0 1.0). The logos are trademarks of their respective owners and are used only to identify the platform.
| `source/brand/phone-puppet.png` (phone as cardboard puppet, blank screen) | Codex CLI 0.164.0 | 2026-10-25 | prompt embedded in the PNG |
| `source/brand/phone-island.png`, `source/brand/phone-edge.png` (modern phone puppets, blank displays) | Codex CLI 0.164.0 | 2026-10-25 | prompt embedded in the PNGs |
