"""Writes the characters into the app.

- app/assets/pages/<creature>.png: the coloring pages (grayscale, 600 x 800).
- colors/<creature>.png: the same character in its colors, for the demo
  video (it colors each area the way the character really looks).

    python3 export.py [names...]
"""
import io
import pathlib
import sys
import tempfile

from PIL import Image

import characters
import kawaii
import preview

HERE = pathlib.Path(__file__).resolve().parent
APP = HERE.parents[2] / "app"


def main():
    names = sys.argv[1:] or list(characters.CHARACTERS)
    pages, colors = APP / "assets" / "pages", HERE / "colors"
    colors.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name in names:
            parts = characters.CHARACTERS[name]()
            for colored, out in ((False, pages / f"{name}.png"), (True, colors / f"{name}.png")):
                png = pathlib.Path(tmp) / f"{name}.png"
                preview.render(kawaii.svg(parts, colored), png)
                image = Image.open(png).convert("RGB" if colored else "L")
                buf = io.BytesIO()
                image.save(buf, format="PNG", optimize=True)
                out.write_bytes(buf.getvalue())
            print(name, flush=True)


if __name__ == "__main__":
    main()
