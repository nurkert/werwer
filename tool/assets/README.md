# Asset tools

Python helpers to turn generated images into clean cutouts.

```bash
python3 -m venv .venv-assets && .venv-assets/bin/pip install -r tool/assets/requirements.txt
.venv-assets/bin/python tool/assets/slice_sheet.py design/sheets/sheet_props.png design/source/props haeuser kirchturm tanne_1 tanne_2 busch steine zaun fass kiste laterne
```

The game's sounds are CC0 recordings and Kenney packs, trimmed and
loudness-normalised with ffmpeg; sources and changes per file are in
`app/assets/sounds/CREDITS.md`.
