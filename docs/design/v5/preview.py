"""A sheet of characters in color and as coloring pages, to look at.

    python3 preview.py out.png [names...]
"""
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image

import characters
import kawaii

RENDER = pathlib.Path(__file__).resolve().parents[1] / "v3" / "src" / "render_svg.js"


def render(svg_text, png):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg_text)
    subprocess.run(["node", str(RENDER), f.name, str(png), str(kawaii.PAGE_W), str(kawaii.PAGE_H)], check=True)
    pathlib.Path(f.name).unlink()


def main():
    out = pathlib.Path(sys.argv[1])
    names = sys.argv[2:] or list(characters.CHARACTERS)
    w, h = 240, 320
    sheet = Image.new("RGB", (w * len(names), h * 2), "white")
    with tempfile.TemporaryDirectory() as tmp:
        for i, name in enumerate(names):
            parts = characters.CHARACTERS[name]()
            for j, colored in enumerate((True, False)):
                png = pathlib.Path(tmp) / f"{name}_{j}.png"
                render(kawaii.svg(parts, colored), png)
                sheet.paste(Image.open(png).convert("RGB").resize((w, h), Image.LANCZOS), (i * w, j * h))
    sheet.save(out)


if __name__ == "__main__":
    main()
