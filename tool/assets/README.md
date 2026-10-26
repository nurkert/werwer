# Asset tools

Python helpers to turn generated images into clean cutouts.

```bash
python3 -m venv .venv-assets && .venv-assets/bin/pip install -r tool/assets/requirements.txt
.venv-assets/bin/python tool/assets/slice_sheet.py design/sheets/sheet_props.png design/source/props haeuser kirchturm tanne_1 tanne_2 busch steine zaun fass kiste laterne
```

Night sounds are synthesised, not recorded (wind, crickets, owl, yawn):

```bash
.venv-assets/bin/python tool/assets/synth_sounds.py design/source/sounds
for f in wind crickets owl yawn; do
  ffmpeg -y -i design/source/sounds/$f.wav -c:a libmp3lame -b:a 64k app/assets/sounds/$f.mp3
done
```
