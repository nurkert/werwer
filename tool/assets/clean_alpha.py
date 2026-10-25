"""Remove generator glow from a single transparent PNG.

Usage: python tool/assets/clean_alpha.py IN.png OUT.png
"""

import sys

import numpy as np
from PIL import Image

from slice_sheet import clean_alpha

rgba = clean_alpha(np.array(Image.open(sys.argv[1]).convert("RGBA")))
Image.fromarray(rgba).save(sys.argv[2], optimize=True)
