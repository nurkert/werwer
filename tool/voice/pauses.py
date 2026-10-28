"""Finds the pauses inside the narrator's clips: stretches of silence of
at least MIN_PAUSE_MS between two words, where the walking narrator may
hand the voice to another phone without anyone hearing the switch.

encode.py calls find_pauses for every clip it writes. Run on its own, it
adds the pauses to the existing manifest from the encoded files:

    python3 tool/voice/pauses.py
"""

import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "app/assets/voice"

# Shorter gaps are breaths inside a phrase; a switch there would be heard.
MIN_PAUSE_MS = 250
# Below this level counts as silence (the clips are loudness-normalised).
NOISE_DB = -40
# Silence touching the clip's ends is no pause between words.
EDGE_MS = 60


def find_pauses(path: Path, length_ms: int) -> list[list[int]]:
    """[start, end] in ms of every inner pause of the clip at [path]."""
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af",
         f"silencedetect=noise={NOISE_DB}dB:d={MIN_PAUSE_MS / 1000}",
         "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    ).stderr
    starts = [float(v) for v in re.findall(r"silence_start: ([0-9.]+)", out)]
    ends = [float(v) for v in re.findall(r"silence_end: ([0-9.]+)", out)]
    pauses = []
    for start, end in zip(starts, ends):
        s, e = round(start * 1000), round(end * 1000)
        if s > EDGE_MS and e < length_ms - EDGE_MS and e - s >= MIN_PAUSE_MS:
            pauses.append([s, e])
    return pauses


def main() -> None:
    manifest_path = APP / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    found = 0
    for lines in manifest.values():
        for variants in lines.values():
            for clip in variants:
                pauses = find_pauses(APP / clip["file"], clip["ms"])
                if pauses:
                    clip["pauses"] = pauses
                    found += len(pauses)
                else:
                    clip.pop("pauses", None)
    manifest_path.write_text(
        json.dumps(manifest, indent=1, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print(f"{found} pauses")


if __name__ == "__main__":
    main()
