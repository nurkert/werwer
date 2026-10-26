"""Speaks the narrator's lines (tool/voice/lines.json) with Chatterbox.

    ~/.venvs/chatterbox/bin/python tool/voice/generate.py \
        [--reference narrator.wav] [--lang de en] [--takes 2] [--only key ...]

Without --reference Chatterbox uses its built-in voice. Clone only a voice
whose owner agreed. Raw takes go to design/source/voice/<key>_<lang>_<n>.wav;
tool/voice/encode.sh turns them into the app's files.
"""

import argparse
import json
import random
import zlib
from pathlib import Path

import torch
import torchaudio
from chatterbox.mtl_tts import ChatterboxMultilingualTTS

ROOT = Path(__file__).resolve().parents[2]
LINES = ROOT / "tool/voice/lines.json"
OUT = ROOT / "design/source/voice"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--lang", nargs="+", default=["de", "en"])
    parser.add_argument("--takes", type=int, default=2)
    parser.add_argument("--only", nargs="*")
    args = parser.parse_args()

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    model = ChatterboxMultilingualTTS.from_pretrained(device=device)
    lines = json.loads(LINES.read_text(encoding="utf-8"))["lines"]
    OUT.mkdir(parents=True, exist_ok=True)
    for line in lines:
        if args.only and line["key"] not in args.only:
            continue
        for lang in args.lang:
            for take in range(1, args.takes + 1):
                target = OUT / f"{line['key']}_{lang}_{take}.wav"
                if target.exists():
                    continue
                # Calm, warm narration: a little less exaggeration, and each
                # take with its own seed so they differ.
                torch.manual_seed(1000 * take + zlib.crc32(line["key"].encode()) % 1000)
                random.seed(take)
                wav = model.generate(
                    line[lang],
                    language_id=lang,
                    audio_prompt_path=str(args.reference) if args.reference else None,
                    exaggeration=0.45,
                    cfg_weight=0.45,
                    temperature=0.75 + 0.05 * take,
                )
                torchaudio.save(str(target), wav, model.sr)
                print(target.relative_to(ROOT))


if __name__ == "__main__":
    main()
