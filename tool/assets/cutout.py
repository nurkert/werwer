"""Cut the pieces of a generated sheet out of a painted (not transparent)
background: grow the background from the border through smooth pixels,
the pale cardboard rims stop it. Writes one PNG per piece, left to right,
top to bottom.

    python cutout.py SHEET.png OUTDIR name1 name2 ...
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

src, out, names = sys.argv[1], Path(sys.argv[2]), sys.argv[3:]
img = np.array(Image.open(src).convert("RGB")).astype(np.float32)
gray = img.mean(axis=2)
# Local contrast: background gradients are soft, rims are hard.
gx = ndimage.sobel(ndimage.gaussian_filter(gray, 1.2), axis=1)
gy = ndimage.sobel(ndimage.gaussian_filter(gray, 1.2), axis=0)
edge = np.hypot(gx, gy)
smooth = edge < np.percentile(edge, 55)
labels, n = ndimage.label(smooth)
border = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))) - {0}
background = np.isin(labels, list(border))
# Close small gaps so the background reaches into the crevices, then
# everything else is piece.
background = ndimage.binary_opening(background, iterations=1)
piece = ~background
piece = ndimage.binary_fill_holes(piece)
piece = ndimage.binary_opening(piece, iterations=2)
plabels, count = ndimage.label(piece)
sizes = ndimage.sum(piece, plabels, range(1, count + 1))
keep = [i + 1 for i, s in enumerate(sizes) if s > piece.size * 0.004]
boxes = ndimage.find_objects(plabels)
items = []
for i in keep:
    sl = boxes[i - 1]
    items.append((sl[0].start, sl[1].start, i, sl))
# Rows of pieces: sort by row band, then x.
items.sort(key=lambda t: (round(t[0] / (img.shape[0] / 3)), t[1]))
print(f"{len(items)} pieces, {len(names)} names")
out.mkdir(parents=True, exist_ok=True)
rgba = np.array(Image.open(src).convert("RGBA"))
for (y, x, i, sl), name in zip(items, names):
    mask = ndimage.binary_erosion(plabels[sl] == i, iterations=1)
    alpha = ndimage.gaussian_filter(mask.astype(np.float32), 0.8)
    crop = rgba[sl].copy()
    crop[..., 3] = (alpha * 255).clip(0, 255).astype(np.uint8)
    Image.fromarray(crop).save(out / f"{name}.png", optimize=True)
    print(name, crop.shape[1], "x", crop.shape[0])
