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
3. **Verify:** `python3 tool/voice/verify.py de` transcribes every file
   offline (whisper.cpp) and compares it word by word with the script.
   `--remove` deletes the ones that say something else; run step 2 again to
   make them anew. Changed lines in the script are made anew on the next
   run of step 2 by themselves (each file keeps its text next to it).
4. **Encode:** `python3 tool/voice/encode.py de` trims, normalises, shortens
   every pause between sentences to at most 700 ms (longer ones sound like
   the voice broke off) and writes
   `app/assets/voice/<lang>/` plus `manifest.json` (lengths for the walk and
   the facts a line needs). It takes only verified files.
   It also writes each clip's inner pauses (at least 250 ms) into the
   manifest; the walking narrator changes phones only there.
   `python3 tool/voice/pauses.py` adds them to an existing manifest
   without re-encoding; `VOICE_SOURCE=…` reads the raw recordings
   from another checkout.

**Writing lines:** every variant is a short, complete sentence that is
true whenever it is said, players are spoken of gender-neutrally, and at
least five variants fit every table (a test checks it). A line that names a
detail carries the facts it needs: `{"text": "...", "if": ["deaths"]}` with
`deaths`/`no_deaths`, `wolves`/`wolf`, `witch` (see `storyFacts`).

Without recordings the app shows the lines and, if switched on, the host
speaks them with the system voice.
