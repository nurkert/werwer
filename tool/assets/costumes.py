"""Cut the role-costume sheets (one per persona, five roles left to right)
into single figures and write the app's WebP files.

Usage: python tool/assets/costumes.py design/sheets/roles/*.png

A sheet `design/sheets/roles/<persona>.png` becomes
`design/source/figures/roles/<persona>_<role>.png` and
`app/assets/figures/roles/<persona>_<role>.webp` (560 px high).
"""

import subprocess
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROLES = ["werewolf", "seer", "witch", "hunter", "cupid"]
SOURCE = Path("design/source/figures/roles")
APP = Path("app/assets/figures/roles")
HEIGHT = 560


def split_by_columns(sheet: Path, names: list[str]) -> None:
    """Fallback when figures touch (a bow tip on a wing): cut at the emptiest
    column near each expected border, then trim every piece."""
    rgba = np.array(Image.open(sheet).convert("RGBA"))
    alpha = rgba[:, :, 3].astype(float)
    density = np.convolve(alpha.sum(axis=0), np.ones(15) / 15, mode="same")
    width = rgba.shape[1]
    step = width / len(names)
    cuts = [0]
    for k in range(1, len(names)):
        lo, hi = int((k - 0.35) * step), int((k + 0.35) * step)
        cuts.append(lo + int(np.argmin(density[lo:hi])))
    cuts.append(width)
    SOURCE.mkdir(parents=True, exist_ok=True)
    for name, x0, x1 in zip(names, cuts, cuts[1:]):
        piece = rgba[:, x0:x1].copy()
        # Splinters of a neighbour touch the cut; the figure is the largest
        # region. Loose parts of its own (a bee, a spark) stay.
        labels, count = ndimage.label(piece[:, :, 3] > 48)
        sizes = ndimage.sum(np.ones_like(labels), labels, range(1, count + 1))
        largest = int(np.argmax(sizes)) + 1
        edges = set(labels[:, 0]) | set(labels[:, -1])
        drop = [i for i in edges if i not in (0, largest)]
        piece[np.isin(labels, drop), 3] = 0
        ys, xs = np.nonzero(piece[:, :, 3] > 48)
        crop = piece[max(ys.min() - 8, 0) : ys.max() + 9, max(xs.min() - 8, 0) : xs.max() + 9]
        Image.fromarray(crop).save(SOURCE / f"{name}.png", optimize=True)
        print(f"{name}.png  {crop.shape[1]}x{crop.shape[0]} (column split)")


def main() -> None:
    APP.mkdir(parents=True, exist_ok=True)
    for sheet in map(Path, sys.argv[1:]):
        persona = sheet.stem
        names = [f"{persona}_{role}" for role in ROLES]
        sliced = subprocess.run(
            [sys.executable, "tool/assets/slice_sheet.py", str(sheet), str(SOURCE), *names],
            check=False,
        )
        if sliced.returncode != 0:
            split_by_columns(sheet, names)
        for name in names:
            image = Image.open(SOURCE / f"{name}.png").convert("RGBA")
            width = round(image.width * HEIGHT / image.height)
            image.resize((width, HEIGHT), Image.LANCZOS).save(
                APP / f"{name}.webp", "WEBP", quality=78, method=6
            )


if __name__ == "__main__":
    main()
