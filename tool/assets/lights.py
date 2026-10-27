"""Find the lights painted into the stage sets and scenery pieces, so the
app and the website can make them glow (task 015).

Usage: python tool/assets/lights.py

For every stage set (`app/assets/stage/*.webp`) and scenery piece
(`app/assets/stage/scenery/*.webp`) it looks for
  - warm lights: windows, lanterns, footlights (bright, orange to yellow),
  - stars: small pale points in the sky above the horizon,
  - reflections: warm streaks in the water band of a set.
Positions and sizes are fractions of the picture. The result goes to
`app/lib/src/stage/lights.g.dart` and `website/src/data/lights.json`.
"""

import json
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

SETS = Path("app/assets/stage")
PIECES = Path("app/assets/stage/scenery")
DART = Path("app/lib/src/stage/lights.g.dart")
JSON = Path("website/src/data/lights.json")

# Per set (looked up by eye): where warm lights are searched (rectangles
# x0, y0, x1, y1 as fractions; elsewhere bark, straw and stage boards would
# count), lights set by hand, where the sky ends (stars above it) and the
# water's rectangle (reflections inside it).
SETS_CONFIG = {
    "village": {"bands": [(0, 0.36, 1, 0.62)], "sky": 0.36, "water": (0.35, 0.62, 0.97, 0.697)},
    "nightlake": {"bands": [(0, 0.5, 1, 0.6)], "extra": [(0.185, 0.775, 0.03, 1)], "sky": 0.42, "water": (0, 0.6, 1, 0.67)},
    "hunt": {"bands": [], "extra": [(0.86, 0.86, 0.012, 0.7)], "skyStars": 0.4},
    "dusk": {"bands": [(0.05, 0.55, 0.95, 0.8)], "skyStars": 0.22},
    "finale": {"bands": [(0, 0.55, 1, 0.8)]},
    "theatre": {"bands": [(0, 0.85, 1, 0.98), (0, 0.48, 1, 0.62)], "skyStars": 0.5},
    "curtain": {"bands": [], "extra": [(0.217, 0.15, 0.03, 1), (0.777, 0.15, 0.03, 1)]},
    "backstage": {"bands": [(0.78, 0.36, 0.99, 0.62)], "extra": [(0.068, 0.205, 0.03, 1)]},
    "morning": {"bands": []},
}

# Scenery pieces: their lanterns and windows, set by hand.
PIECE_LIGHTS = {
    "branch": [(0.65, 0.81, 0.07, 1)],
    "house": [(0.75, 0.44, 0.08, 0.9)],
    "lamppost": [(0.49, 0.25, 0.12, 1)],
    "oak": [(0.84, 0.5, 0.04, 0.9)],
    "reeds": [(0.86, 0.64, 0.06, 1)],
    "garland": [(0.15, 0.53, 0.025, 1), (0.317, 0.72, 0.025, 1), (0.494, 0.82, 0.025, 1), (0.68, 0.72, 0.025, 1), (0.846, 0.53, 0.025, 1)],
}

MAX_LIGHTS = 80
MAX_STARS = 60
MAX_RIPPLES = 30


def hsv(rgb: np.ndarray):
    r, g, b = (rgb[..., i] for i in range(3))
    mx = rgb.max(axis=-1)
    mn = rgb.min(axis=-1)
    d = mx - mn + 1e-6
    h = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    s = np.where(mx > 0, d / (mx + 1e-6), 0)
    return h, s, mx


def blobs(mask: np.ndarray, weight: np.ndarray, min_area: int, max_area: int, limit: int):
    """Connected bright spots: (x, y, radius, strength) as fractions."""
    labels, n = ndimage.label(mask)
    if n == 0:
        return []
    idx = np.arange(1, n + 1)
    area = ndimage.sum(np.ones_like(weight), labels, idx)
    power = ndimage.sum(weight, labels, idx)
    centres = ndimage.center_of_mass(weight, labels, idx)
    h, w = mask.shape
    out = []
    for a, p, (cy, cx) in zip(area, power, centres):
        if a < min_area or a > max_area:
            continue
        out.append((cx / w, cy / h, float(np.sqrt(a / np.pi)) / w, float(p)))
    out.sort(key=lambda b: -b[3])
    out = out[:limit]
    top = out[0][3] if out else 1
    return [(round(x, 4), round(y, 4), round(r, 4), round(min(1, s / top) ** 0.5, 2)) for x, y, r, s in out]


def merge_close(points, dist):
    """Neighbouring spots of one window become one light."""
    kept = []
    for p in points:
        if all((p[0] - k[0]) ** 2 + (p[1] - k[1]) ** 2 > dist * dist for k in kept):
            kept.append(p)
    return kept


def sky_stars(v, rows, cols, line: float, rng, avoid):
    """Stars of our own where the sky is clear: on dark, smooth sky only
    (no clouds, hills, trees), evenly spread without clumps (a minimum
    distance between any two), thinning towards the horizon, a few bright
    ones among many faint. Returns (x, y, magnitude 0..1, phase seed)."""
    mean = ndimage.uniform_filter(v, 9)
    var = ndimage.uniform_filter(v * v, 9) - mean * mean
    clear = (v < 0.34) & (var < 0.0012) & (rows < line)
    # Keep away from the edge of clouds and hills a little.
    clear = ndimage.binary_erosion(clear, iterations=4)
    h, w = v.shape
    ys, xs = np.nonzero(clear)
    if len(xs) == 0:
        return []
    order = rng.permutation(len(xs))
    chosen = []
    grid = {}
    cell = 0.024
    for k in order:
        x, y = xs[k] / w, ys[k] / h
        # Dense high up, sparse near the horizon.
        if rng.random() > (1 - y / line) ** 1.3 * 0.9 + 0.1:
            continue
        if any((x - ax) ** 2 + (y - ay) ** 2 < 0.03 ** 2 for ax, ay in avoid):
            continue
        gx, gy = int(x / cell), int(y / cell)
        near = False
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                for px, py in grid.get((gx + dx, gy + dy), []):
                    if (x - px) ** 2 + (y - py) ** 2 < cell * cell:
                        near = True
        if near:
            continue
        grid.setdefault((gx, gy), []).append((x, y))
        chosen.append((x, y))
        if len(chosen) >= 170:
            break
    out = []
    for x, y in chosen:
        # Magnitudes as in a real sky: many faint, few bright.
        m = float(rng.random() ** 3.2)
        out.append((round(x, 4), round(y, 4), round(m, 3), round(float(rng.random()), 3)))
    return out


def analyse(path: Path, config: dict):
    sky = config.get("sky", 0)
    water = config.get("water")
    img = Image.open(path).convert("RGBA")
    rgba = np.asarray(img).astype(np.float32) / 255
    rgb = rgba[..., :3]
    alpha = rgba[..., 3]
    # Transparent pixels count as a mid tone: otherwise the pale cardboard
    # rim of a piece looks like a light against the empty corners.
    rgb = np.where(alpha[..., None] > 0.5, rgb, rgb[alpha > 0.5].mean(axis=0) if (alpha > 0.5).any() else 0.3)
    h, s, v = hsv(rgb)
    rows = np.arange(rgb.shape[0])[:, None] / rgb.shape[0]
    around = ndimage.gaussian_filter(v, sigma=max(6, rgb.shape[1] / 90))
    glow = v - around
    area = rgb.shape[0] * rgb.shape[1]
    scale = area / (1254 * 1254)
    # A light is much brighter than what is around it, not only bright:
    # straw, apples and the morning sky are bright too.
    warm = (v > 0.88) & (glow > 0.2) & (s > 0.42) & (h > 22) & (h < 60) & (alpha > 0.9)
    cols = np.arange(rgb.shape[1])[None, :] / rgb.shape[1]
    def rect(x0, y0, x1, y1):
        return (cols >= x0) & (cols <= x1) & (rows >= y0) & (rows <= y1)
    in_bands = np.zeros_like(warm)
    for band in config.get("bands", []):
        in_bands |= rect(*band)
    in_water = rect(*water) if water else np.zeros_like(warm)
    lights = blobs(warm & in_bands & ~in_water, v * s, max(3, 4 * scale), 2600 * scale, MAX_LIGHTS * 2)
    lights = merge_close(lights, 0.011)[:MAX_LIGHTS] + list(config.get("extra", []))
    stars = []
    if sky > 0:
        pale = (v > 0.7) & (glow > 0.25) & (s < 0.5) & (rows < sky) & (alpha > 0.5)
        stars = blobs(pale, v, 1, 60 * scale, MAX_STARS)
    line = config.get("skyStars", sky)
    own = sky_stars(v, rows, cols, line, np.random.default_rng(7), [(x, y) for x, y, _, _ in stars]) if line else []
    ripples = []
    if water:
        shine = (v > 0.55) & (glow > 0.12) & (s > 0.3) & (h > 18) & (h < 62) & in_water
        ripples = blobs(shine, v, max(2, 3 * scale), 3000 * scale, MAX_RIPPLES)
    return {"lights": lights, "stars": stars, "ripples": ripples, "sky": own}


def dart_list(name, items):
    rows = ",\n".join(f"    ({x}, {y}, {r}, {s})" for x, y, r, s in items)
    return f"  {name}: [\n{rows}{',' if rows else ''}\n  ]" if rows else f"  {name}: []"


def main():
    result = {}
    for path in sorted(SETS.glob("*.webp")):
        name = path.stem
        result[name] = analyse(path, SETS_CONFIG.get(name, {"bands": []}))
    for name, lights in PIECE_LIGHTS.items():
        result[f"scenery/{name}"] = {"lights": lights, "stars": [], "ripples": [], "sky": []}
    JSON.parent.mkdir(parents=True, exist_ok=True)
    JSON.write_text(json.dumps(result, separators=(",", ":")) + "\n")

    out = [
        "// Generated by tool/assets/lights.py; do not edit.",
        "",
        "/// A light painted into a picture: centre and radius as fractions of",
        "/// its width and height, and how bright it is (0 to 1).",
        "typedef PaintedLight = (double x, double y, double r, double strength);",
        "",
        "/// The lights of one picture (task 015).",
        "typedef PaintedLights = ({",
        "  List<PaintedLight> lights,",
        "  List<PaintedLight> stars,",
        "  List<PaintedLight> ripples,",
        "  // Stars of our own on clear sky: x, y, magnitude (0 faint to 1",
        "  // bright), a seed for their own pace.",
        "  List<PaintedLight> sky,",
        "});",
        "",
        "/// Per stage set (`village`) and scenery piece (`scenery/lamppost`).",
        "const Map<String, PaintedLights> paintedLights = {",
    ]
    for name, data in result.items():
        if not any(data.values()):
            continue
        out.append(f"  '{name}': (")
        for key in ("lights", "stars", "ripples", "sky"):
            items = data[key]
            if not items:
                out.append(f"    {key}: [],")
                continue
            out.append(f"    {key}: [")
            out.extend(f"      ({x}, {y}, {r}, {s})," for x, y, r, s in items)
            out.append("    ],")
        out.append("  ),")
    out.append("};")
    DART.write_text("\n".join(out) + "\n")
    for name, data in result.items():
        print(f"{name:24} lights {len(data['lights']):3} stars {len(data['stars']):3} ripples {len(data['ripples']):3}")


def preview(out_dir: Path):
    """Draw what was found over each picture, to check by eye."""
    from PIL import ImageDraw
    data = json.loads(JSON.read_text())
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, d in data.items():
        src = (PIECES / f"{name.split('/')[1]}.webp") if "/" in name else SETS / f"{name}.webp"
        img = Image.open(src).convert("RGBA")
        bg = Image.new("RGBA", img.size, (40, 40, 60, 255))
        bg.alpha_composite(img)
        draw = ImageDraw.Draw(bg)
        w, h = img.size
        for key, colour in (("lights", (255, 0, 255)), ("stars", (0, 255, 255)), ("ripples", (0, 255, 0)), ("sky", (255, 255, 0))):
            for x, y, r, _ in d[key]:
                rr = (2 + 6 * r) if key == "sky" else max(3, r * w * 1.6)
                draw.ellipse((x * w - rr, y * h - rr, x * w + rr, y * h + rr), outline=colour, width=2)
        bg.convert("RGB").save(out_dir / f"{name.replace('/', '_')}.png")


if __name__ == "__main__":
    import sys
    main()
    if len(sys.argv) > 1:
        preview(Path(sys.argv[1]))

