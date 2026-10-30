#!/usr/bin/env bash
# Renders the images of the Windows setup wizard from wizard.svg and
# wizard-small.svg as 24-bit BMPs at 100, 150 and 200 % (Inno Setup picks the
# one that fits the screen), plus wizard-preview.png to look at.
#
# Type is Ancizar Serif from app/assets/fonts, through an own fontconfig.
# Needs rsvg-convert (brew install librsvg) and python3. The BMPs are checked
# in: whoever changes an SVG runs this script and commits them.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
for tool in rsvg-convert python3; do
  command -v "$tool" >/dev/null ||
    { echo "error: $tool missing (rsvg-convert: brew install librsvg)" >&2; exit 1; }
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cat >"$work/fonts.conf" <<CONF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig><dir>$root/app/assets/fonts</dir><cachedir>$work/cache</cachedir></fontconfig>
CONF
export FONTCONFIG_FILE="$work/fonts.conf"
# librsvg only loads images next to the SVG.
cp "$root/design/source/brand/emblem.png" "$root/design/source/brand/wordmark.png" "$work/"
cp "$here/wizard.svg" "$here/wizard-small.svg" "$work/"

# PNG (8-bit RGB or RGBA, from rsvg-convert) to a bottom-up 24-bit BMP, the
# format every Inno Setup version reads; the images are opaque, alpha is dropped.
to_bmp() {
  python3 - "$1" "$2" <<'PY'
import struct, sys, zlib

src, dst = sys.argv[1], sys.argv[2]
data = open(src, "rb").read()
assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
pos, idat, width, height, bpp = 8, b"", 0, 0, 0
while pos < len(data):
    length, kind = struct.unpack(">I4s", data[pos:pos + 8])
    chunk = data[pos + 8:pos + 8 + length]
    if kind == b"IHDR":
        width, height, depth, colour = struct.unpack(">IIBB", chunk[:10])
        assert depth == 8 and colour in (2, 6), "expected 8-bit RGB or RGBA"
        bpp = 4 if colour == 6 else 3
    elif kind == b"IDAT":
        idat += chunk
    pos += 12 + length
raw = zlib.decompress(idat)
stride = width * bpp
rows, prev = [], bytearray(stride)
for y in range(height):
    kind = raw[y * (stride + 1)]
    line = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
    for x in range(stride):
        a = line[x - bpp] if x >= bpp else 0
        b = prev[x]
        c = prev[x - bpp] if x >= bpp else 0
        if kind == 1:
            line[x] = (line[x] + a) & 255
        elif kind == 2:
            line[x] = (line[x] + b) & 255
        elif kind == 3:
            line[x] = (line[x] + (a + b) // 2) & 255
        elif kind == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            line[x] = (line[x] + pred) & 255
    rows.append(bytes(line))
    prev = line
pad = (4 - (width * 3) % 4) % 4
pixels = bytearray()
for line in reversed(rows):
    for x in range(width):
        r, g, b = line[x * bpp:x * bpp + 3]
        pixels += bytes((b, g, r))
    pixels += b"\0" * pad
header = struct.pack("<2sIHHI", b"BM", 54 + len(pixels), 0, 0, 54)
info = struct.pack("<IiiHHIIiiII", 40, width, height, 1, 24, 0, len(pixels), 2835, 2835, 0, 0)
open(dst, "wb").write(header + info + bytes(pixels))
PY
}

for scale in 100 150 200; do
  rsvg-convert -w $((164 * scale / 100)) -h $((314 * scale / 100)) "$work/wizard.svg" -o "$work/wizard.png"
  to_bmp "$work/wizard.png" "$here/wizard-$scale.bmp"
  rsvg-convert -w $((55 * scale / 100)) -h $((55 * scale / 100)) "$work/wizard-small.svg" -o "$work/small.png"
  to_bmp "$work/small.png" "$here/wizard-small-$scale.bmp"
  [[ $scale -eq 200 ]] && cp "$work/wizard.png" "$here/wizard-preview.png"
done
ls -l "$here"/*.bmp "$here/wizard-preview.png"
