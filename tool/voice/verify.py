"""Listens to every narrator file and checks it says exactly its line in
script.json: transcribes it offline with whisper.cpp and compares word by
word. Passing files get a <name>.ok next to them holding the line they
were checked against; encode.py takes only those. Files that say something
else are listed, and with --remove deleted, so the next elevenlabs.py run
makes them again.

    python3 tool/voice/verify.py de [--remove]

Needs whisper-cli (brew install whisper-cpp) and a model, by default
~/whisper-models/ggml-large-v3-turbo.bin (or set WHISPER_MODEL).
"""

import argparse
import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "design/source/voice"
SCRIPT = ROOT / "tool/voice/script.json"
MODEL = Path(
    os.environ.get("WHISPER_MODEL", Path.home() / "whisper-models/ggml-large-v3-turbo.bin")
)


# Words that sound the same; the transcriber cannot tell them apart.
SOUNDS_ALIKE = {
    "wehrwolf": "werwolf",
    "wehrwölfe": "werwölfe",
    "wehrwölfen": "werwölfen",
    "wehrwolfs": "werwolfs",
    "säherin": "seherin",
    "seeherin": "seherin",
}


def words(text: str) -> list[str]:
    """Lower case, without punctuation: what can be heard."""
    found = re.findall(r"[\wäöüß']+", text.lower())
    return [SOUNDS_ALIKE.get(w, w) for w in found]


def says(line: str, heard: str) -> bool:
    """Whether [heard] is [line]; compounds may be split or joined."""
    return "".join(words(line)) == "".join(words(heard))


def text(variant) -> str:
    """A variant is its line, or {"text": line, "if": [facts]}."""
    return variant if isinstance(variant, str) else variant["text"]


def transcribe(path: Path, lang: str, scratch: Path) -> str:
    wav = scratch / f"{path.stem}.wav"
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(path),
         "-ar", "16000", "-ac", "1", str(wav)],
        check=True,
    )
    out = subprocess.run(
        ["whisper-cli", "-m", str(MODEL), "-l", lang, "-nt", "-np", str(wav)],
        capture_output=True, text=True, check=True,
    ).stdout
    return " ".join(out.split())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("lang", nargs="?", default="de", choices=["de", "en"])
    parser.add_argument("--remove", action="store_true",
                        help="delete files that fail, so elevenlabs.py makes them again")
    args = parser.parse_args()
    if not shutil.which("whisper-cli"):
        sys.exit("error: whisper-cli not found (brew install whisper-cpp)")
    if not MODEL.exists():
        sys.exit(f"error: no whisper model at {MODEL} (set WHISPER_MODEL)")

    folder = SOURCE / args.lang
    moments = json.loads(SCRIPT.read_text(encoding="utf-8"))["moments"]
    failed, missing, checked = [], [], 0
    with tempfile.TemporaryDirectory() as tmp:
        for moment in moments:
            for n, variant in enumerate(moment[args.lang], start=1):
                line = text(variant)
                name = f"{moment['key']}_{n}_{args.lang}"
                audio = next(
                    (p for ext in ("wav", "mp3") if (p := folder / f"{name}.{ext}").exists()),
                    None,
                )
                ok = folder / f"{name}.ok"
                if audio is None:
                    missing.append(name)
                    continue
                if ok.exists() and ok.read_text(encoding="utf-8") == line:
                    continue
                checked += 1
                heard = transcribe(audio, args.lang, Path(tmp))
                if says(line, heard):
                    ok.write_text(line, encoding="utf-8")
                    print(f"ok    {name}")
                    continue
                ok.unlink(missing_ok=True)
                diff = difflib.ndiff(words(line), words(heard))
                changes = " ".join(d for d in diff if d[0] in "+-")
                failed.append(name)
                print(f"FAIL  {name}\n      script: {line}\n      heard:  {heard}\n      diff:   {changes}")
                if args.remove:
                    for extra in (audio, audio.with_suffix(".txt")):
                        extra.unlink(missing_ok=True)

    print(f"\n{checked} checked, {len(failed)} failed, {len(missing)} missing")
    if failed:
        action = "removed; run elevenlabs.py again" if args.remove else "rerun with --remove, then elevenlabs.py"
        print(f"failed ({action}): {' '.join(failed)}")
    if missing:
        print(f"missing: {' '.join(missing)}")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
