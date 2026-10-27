"""Writes the narrator's script (script.json) as a list to record or
generate, one file per variant: <key>_<n>_<lang>.mp3.

    python3 tool/voice/export.py de     -> tool/voice/recording_de.csv and .md
"""

import csv
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def text(variant) -> str:
    """A variant is its line, or {"text": line, "if": [facts]}."""
    return variant if isinstance(variant, str) else variant["text"]


def main() -> None:
    lang = sys.argv[1] if len(sys.argv) > 1 else "de"
    script = json.loads((HERE / "script.json").read_text(encoding="utf-8"))
    rows = [
        (f"{m['key']}_{n}_{lang}.mp3", text(v), m["direction"],
         m["when"] + (f" Only if: {', '.join(v['if'])}." if isinstance(v, dict) else ""))
        for m in script["moments"]
        for n, v in enumerate(m[lang], start=1)
    ]
    with open(HERE / f"recording_{lang}.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["file", "text", "direction", "when"])
        writer.writerows(rows)
    lines = [
        f"# Erzähler-Aufnahmen ({lang})",
        "",
        f"{len(rows)} Dateien. Pro Zeile eine Datei, genau unter diesem Namen speichern.",
        "",
        "| Datei | Text | Regie |",
        "|---|---|---|",
    ]
    lines += [f"| `{file}` | {text} | {direction} |" for file, text, direction, _ in rows]
    (HERE / f"recording_{lang}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"{len(rows)} lines -> recording_{lang}.csv / .md")


if __name__ == "__main__":
    main()
