# Narrator voice

The narrator's lines live in one place, `script.json`: every moment of the
game with several variants (German and English), when it is spoken and how.
The app picks a variant per moment (the same on every phone, never the same
twice in a row) and lets the voice walk around the table
(`app/lib/src/game/walking_narrator.dart`).

1. **Edit the script:** `script.json`. A test checks that every moment the
   app can say is there in both languages.
2. **Record or generate**, one file per variant, named `<key>_<n>_<lang>`:
   - with ElevenLabs (a voice your plan lets you publish):
     ```sh
     export ELEVENLABS_API_KEY=...        # your own key, never commit it
     python3 tool/voice/elevenlabs.py --voice <voice id> --lang de
     ```
   - by hand: `python3 tool/voice/export.py de` writes the list
     (`recording_de.md`, `.csv`) to read out or paste;
   - with a cloned voice whose owner agreed (Chatterbox, offline):
     `~/.venvs/chatterbox/bin/python tool/voice/generate.py --reference me.wav`.

   Raw files go to `design/source/voice/<lang>/` (not in git).
3. **Encode:** `python3 tool/voice/encode.py de` trims, normalises and writes
   `app/assets/voice/<lang>/` plus `manifest.json` (lengths for the walk).

Without recordings the app shows the lines and, if switched on, the host
speaks them with the system voice.
