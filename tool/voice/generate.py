"""Speaks the narrator's script (tool/voice/script.json) with Chatterbox,
for a voice whose owner agreed to be cloned (e.g. your own).

    ~/.venvs/chatterbox/bin/python tool/voice/generate.py \
        [--reference narrator.wav] [--lang de en] [--only key ...]

Without --reference Chatterbox uses its built-in voice. The model files
(about 3 GB) come from Hugging Face, or from --models if downloaded there. Clone only a voice
whose owner agreed. Raw files go to design/source/voice/<lang>/<key>_<n>_<lang>.wav;
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
SCRIPT = ROOT / "tool/voice/script.json"
OUT = ROOT / "design/source/voice"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--lang", nargs="+", default=["de", "en"])
    parser.add_argument("--only", nargs="*")
    parser.add_argument(
        "--models",
        type=Path,
        default=Path.home() / ".cache/whowolf-chatterbox",
        help="the model files, if downloaded by hand (else from Hugging Face)",
    )
    args = parser.parse_args()

    device = "mps" if torch.backends.mps.is_available() else "cpu"
    model = (
        ChatterboxMultilingualTTS.from_local(args.models, device)
        if (args.models / "t3_mtl23ls_v2.safetensors").exists()
        else ChatterboxMultilingualTTS.from_pretrained(device=device)
    )
    moments = json.loads(SCRIPT.read_text(encoding="utf-8"))["moments"]
    for moment in moments:
        if args.only and moment["key"] not in args.only:
            continue
        for lang in args.lang:
            for n, text in enumerate(moment[lang], start=1):
                take = n
                target = OUT / lang / f"{moment['key']}_{n}_{lang}.wav"
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.exists():
                    continue
                # Calm, warm narration: a little less exaggeration, and each
                # take with its own seed so they differ.
                torch.manual_seed(1000 * take + zlib.crc32(moment["key"].encode()) % 1000)
                random.seed(take)
                wav = model.generate(
                    text,
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
