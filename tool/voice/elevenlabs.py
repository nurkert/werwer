"""Generates the narrator's script (script.json) with an ElevenLabs voice,
one file per variant, into design/source/voice/<lang>/ (not in git).

    export ELEVENLABS_API_KEY=...           # your key; never commit it
    python3 tool/voice/elevenlabs.py --voice <voice id> --lang de

Only use a voice your ElevenLabs plan lets you use for a published,
commercial project. Existing files are kept (rerun to fill gaps); pass
--only key ... to redo some. Uses only the standard library.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tool/voice/script.json"
API = "https://api.elevenlabs.io/v1/text-to-speech/{voice}?output_format=mp3_44100_128"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--voice", required=True, help="ElevenLabs voice id")
    parser.add_argument("--lang", default="de", choices=["de", "en"])
    parser.add_argument("--model", default="eleven_multilingual_v2")
    parser.add_argument("--stability", type=float, default=0.49)
    parser.add_argument("--similarity", type=float, default=0.46)
    parser.add_argument("--style", type=float, default=0.2)
    parser.add_argument("--speed", type=float, default=1.0)
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()

    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        sys.exit("error: set ELEVENLABS_API_KEY first (your own key, never commit it)")

    out = ROOT / "design/source/voice" / args.lang
    out.mkdir(parents=True, exist_ok=True)
    moments = json.loads(SCRIPT.read_text(encoding="utf-8"))["moments"]
    done = 0
    for moment in moments:
        if args.only and moment["key"] not in args.only:
            continue
        for n, text in enumerate(moment[args.lang], start=1):
            target = out / f"{moment['key']}_{n}_{args.lang}.mp3"
            if target.exists() and not args.only:
                continue
            body = json.dumps({
                "text": text,
                "model_id": args.model,
                "language_code": args.lang,
                "voice_settings": {
                    "stability": args.stability,
                    "similarity_boost": args.similarity,
                    "style": args.style,
                    "speed": args.speed,
                    "use_speaker_boost": True,
                },
            }).encode()
            request = urllib.request.Request(
                API.format(voice=args.voice),
                data=body,
                headers={"xi-api-key": key, "Content-Type": "application/json",
                         "Accept": "audio/mpeg"},
            )
            for attempt in range(4):
                try:
                    with urllib.request.urlopen(request, timeout=120) as response:
                        target.write_bytes(response.read())
                    break
                except urllib.error.HTTPError as error:
                    detail = error.read().decode(errors="replace")[:300]
                    if error.code in (429, 500, 502, 503) and attempt < 3:
                        time.sleep(5 * (attempt + 1))
                        continue
                    sys.exit(f"error {error.code} for {target.name}: {detail}")
            done += 1
            print(f"{target.relative_to(ROOT)}  {text}")
    print(f"done: {done} new files in {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
