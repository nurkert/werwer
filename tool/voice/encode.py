"""Turns the raw narrator files (design/source/voice/<lang>/*) into the
app's: silence trimmed, loudness-normalised, mono MP3 in
app/assets/voice/<lang>/, plus a manifest with every file's length, which
the walking narrator plans with. Takes only files that verify.py checked
against their current line.

    python3 tool/voice/encode.py de [en]
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "design/source/voice"
APP = ROOT / "app/assets/voice"
SCRIPT = ROOT / "tool/voice/script.json"


def text(variant) -> str:
    """A variant is its line, or {"text": line, "if": [facts]}."""
    return variant if isinstance(variant, str) else variant["text"]


def duration_ms(path: Path) -> int:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration",
         "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout
    return round(float(out) * 1000)


def main() -> None:
    langs = sys.argv[1:] or ["de"]
    moments = json.loads(SCRIPT.read_text(encoding="utf-8"))["moments"]
    manifest_path = APP / "manifest.json"
    manifest = (
        json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    )
    for lang in langs:
        (APP / lang).mkdir(parents=True, exist_ok=True)
        lines = {}
        for moment in moments:
            variants = []
            for n in range(1, len(moment[lang]) + 1):
                name = f"{moment['key']}_{n}_{lang}"
                raw = next(
                    (p for ext in ("wav", "mp3") if (p := SOURCE / lang / f"{name}.{ext}").exists()),
                    None,
                )
                if raw is None:
                    continue
                # Only what verify.py heard say exactly this line.
                ok = SOURCE / lang / f"{name}.ok"
                if not ok.exists() or ok.read_text(encoding="utf-8") != text(moment[lang][n - 1]):
                    print(f"skipped {name}: not verified against the script (verify.py)")
                    continue
                target = APP / lang / f"{name}.mp3"
                # Trim silence at both ends (keep 80 ms), even loudness,
                # a soft fade, mono, small.
                subprocess.run(
                    ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(raw),
                     "-af",
                     "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08,"
                     "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.08,areverse,"
                     "loudnorm=I=-18:TP=-1.5:LRA=9,afade=t=in:d=0.01",
                     "-ac", "1", "-ar", "44100", "-codec:a", "libmp3lame", "-q:a", "4",
                     "-map_metadata", "-1", str(target)],
                    check=True,
                )
                clip = {"file": f"{lang}/{name}.mp3", "ms": duration_ms(target)}
                variant = moment[lang][n - 1]
                if isinstance(variant, dict) and variant.get("if"):
                    clip["if"] = variant["if"]
                variants.append(clip)
            if variants:
                lines[moment["key"]] = variants
        manifest[lang] = lines
        count = sum(len(v) for v in lines.values())
        print(f"{lang}: {count} files, {len(lines)} of {len(moments)} moments")
    manifest_path.write_text(json.dumps(manifest, indent=1, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
