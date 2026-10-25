"""Cut a generated sprite sheet into single transparent PNGs.

Usage: python tool/assets/slice_sheet.py SHEET.png OUT_DIR name1 name2 ...

Elements are found as connected regions of the alpha channel, ordered
top-to-bottom, then left-to-right, and saved under the given names. The faint
glow image generators like to add around cutouts is removed first.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

GLOW_ALPHA = 48  # alpha below this is glow/halo, not the cutout
SOLID_ALPHA = 200  # alpha above this is treated as fully opaque
MIN_AREA = 0.002  # ignore specks smaller than this share of the sheet
PADDING = 8
CLOSE_GAPS = 2  # pixels; keeps tiny detached details with their element


def clean_alpha(rgba: np.ndarray) -> np.ndarray:
    alpha = rgba[:, :, 3].astype(np.int32)
    alpha[alpha < GLOW_ALPHA] = 0
    alpha[alpha >= SOLID_ALPHA] = 255
    out = rgba.copy()
    out[:, :, 3] = alpha.astype(np.uint8)
    return out


def order_in_rows(boxes):
    """Group elements whose vertical centre lies inside a row, then sort by x."""
    rows = []
    for item in sorted(boxes, key=lambda b: b[1][0].start):
        centre = (item[1][0].start + item[1][0].stop) / 2
        for row in rows:
            if row["top"] <= centre <= row["bottom"]:
                row["items"].append(item)
                row["bottom"] = max(row["bottom"], item[1][0].stop)
                break
        else:
            rows.append({"top": item[1][0].start, "bottom": item[1][0].stop, "items": [item]})
    return [i for row in rows for i in sorted(row["items"], key=lambda b: b[1][1].start)]


def main() -> None:
    sheet, out_dir, names = sys.argv[1], Path(sys.argv[2]), sys.argv[3:]
    rgba = clean_alpha(np.array(Image.open(sheet).convert("RGBA")))
    mask = rgba[:, :, 3] > 0
    # Close small gaps so detached details (e.g. a lantern) stay with their element.
    merged = ndimage.binary_closing(mask, iterations=CLOSE_GAPS)
    labels, count = ndimage.label(merged)
    boxes = []
    for index, box in enumerate(ndimage.find_objects(labels), start=1):
        area = (labels[box] == index).sum()
        if area >= MIN_AREA * mask.size:
            boxes.append((index, box))
    boxes = order_in_rows(boxes)
    if len(boxes) != len(names):
        sys.exit(f"found {len(boxes)} elements but got {len(names)} names")
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, (index, box) in zip(names, boxes):
        y0 = max(box[0].start - PADDING, 0)
        y1 = min(box[0].stop + PADDING, rgba.shape[0])
        x0 = max(box[1].start - PADDING, 0)
        x1 = min(box[1].stop + PADDING, rgba.shape[1])
        crop = rgba[y0:y1, x0:x1].copy()
        crop[:, :, 3] = np.where(labels[y0:y1, x0:x1] == index, crop[:, :, 3], 0)
        Image.fromarray(crop).save(out_dir / f"{name}.png", optimize=True)
        print(f"{name}.png  {x1 - x0}x{y1 - y0}")


if __name__ == "__main__":
    main()
