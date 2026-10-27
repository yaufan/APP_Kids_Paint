"""Writes the characters into the app.

- app/assets/pages/<creature>.png: the coloring pages (grayscale, 600 x 800).
- app/assets/previews/<creature>.png: the character in its colors, cut
  out and small, for the cards children pick a page from.
- colors/<creature>.png: the same character in its colors, for the demo
  video (it colors each area the way the character really looks).

    python3 export.py [names...]
"""
import io
import pathlib
import sys
import tempfile

import numpy as np
from PIL import Image
from scipy import ndimage

import characters
import kawaii
import preview

HERE = pathlib.Path(__file__).resolve().parent
APP = HERE.parents[2] / "app"


PREVIEW = 256  # the longer side of a card's picture, in pixels


def cut_out(image):
    """The colored character without the white paper around it, cropped
    close and made small."""
    rgb = np.asarray(image.convert("RGB"))
    paper, _ = ndimage.label(rgb.min(axis=2) >= 248)
    edge = np.unique(np.concatenate([paper[0], paper[-1], paper[:, 0], paper[:, -1]]))
    outside = np.isin(paper, edge[edge > 0])
    rgba = np.dstack([rgb, np.where(outside, 0, 255).astype(np.uint8)])
    ys, xs = np.nonzero(~outside)
    pad = 6
    box = (max(xs.min() - pad, 0), max(ys.min() - pad, 0), min(xs.max() + pad + 1, rgb.shape[1]), min(ys.max() + pad + 1, rgb.shape[0]))
    out = Image.fromarray(rgba, "RGBA").crop(box)
    scale = PREVIEW / max(out.size)
    out = out.resize((round(out.width * scale), round(out.height * scale)), Image.LANCZOS)
    return out.quantize(colors=128, method=Image.Quantize.FASTOCTREE)  # a quarter of the size, looks the same


def save(image, out):
    buf = io.BytesIO()
    image.save(buf, format="PNG", optimize=True)
    out.write_bytes(buf.getvalue())


def main():
    names = sys.argv[1:] or list(characters.CHARACTERS)
    pages, previews, colors = APP / "assets" / "pages", APP / "assets" / "previews", HERE / "colors"
    previews.mkdir(exist_ok=True)
    colors.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name in names:
            parts = characters.CHARACTERS[name]()
            for colored, out in ((False, pages / f"{name}.png"), (True, colors / f"{name}.png")):
                png = pathlib.Path(tmp) / f"{name}.png"
                preview.render(kawaii.svg(parts, colored), png)
                image = Image.open(png).convert("RGB" if colored else "L")
                save(image, out)
                if colored:
                    save(cut_out(image), previews / f"{name}.png")
            print(name, flush=True)


if __name__ == "__main__":
    main()
