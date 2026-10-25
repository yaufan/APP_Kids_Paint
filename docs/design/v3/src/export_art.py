"""Writes the v3 art into the app: app/assets/art/** and lib/features/town/town_layout_data.dart.

    python3 export_art.py
"""
import io
import pathlib
import re
import subprocess
import tempfile

from PIL import Image

import festivals
import kit
import screens
import town

APP = pathlib.Path(__file__).resolve().parents[4] / "app"
ART = APP / "assets" / "art"

# Placeholders the app swaps for the chosen color (see lib/app/art.dart).
TOKEN, TOKEN_DARK, TOKEN_LIGHT = "#C0FFEE", "#C0FFE1", "#C0FFE2"


def standalone(svg):
    svg = re.sub(r' (role|aria-label|aria-hidden)="[^"]*"', "", svg)
    svg = re.sub(r' style="[^"]*"', "", svg, count=1)
    return svg.replace("<svg ", '<svg xmlns="http://www.w3.org/2000/svg" ', 1)


def write(rel, svg):
    path = ART / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(standalone(svg))


def main():
    for name in kit.ICONS:
        write(f"icons/{name}.svg", kit.icon(name, 24, "#000000"))
        write(f"icons/{name}_solid.svg", kit.solid(name, 24, "#000000"))
    for kind, _ in kit.PLACE_TYPES:
        write(f"places/{kind}.svg", kit.place_icon(kind, 64))
    for kind in kit.ANIMALS:
        write(f"animals/{kind}.svg", kit.animal(kind, 64))
    write("pigeon.svg", kit.pigeon(100, letter=True))
    write("pigeon_flying.svg", kit.pigeon(100, letter=False, flying=True))
    write("pigeon_flying_letter.svg", kit.pigeon(100, letter=True, flying=True))
    write("pigeon_asleep.svg", kit.pigeon(100, letter=False, asleep=True))
    write("logo.svg", screens.logo(48))
    write("ui/mini_album.svg", screens.mini_album(46))
    write("ui/mini_book.svg", screens.mini_book(46))
    write("ui/mini_paper.svg", screens.mini_paper(46))
    for name in festivals.DECOR:
        write(f"festivals/{name}.svg", festivals.icon(name))
    export_pages()
    # Tools in the chosen color: the generator's shades of a token color are
    # replaced by tokens the app fills in.
    base = "#FF5E5B"
    for name, fn in [("bucket", screens.tool_bucket), ("crayon", screens.tool_crayon)]:
        svg = fn(base).replace(kit.shade(base, -0.25), TOKEN_DARK).replace(kit.shade(base, 0.15), TOKEN_LIGHT).replace(base, TOKEN)
        write(f"tools/{name}.svg", svg)
    town.export(APP)


def export_pages():
    """Festival coloring pages as grayscale PNGs (app/assets/pages/<festival>.png)."""
    out = APP / "assets" / "pages"
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, page in festivals.PAGES.items():
            src = pathlib.Path(tmp) / f"{name}.svg"
            png = pathlib.Path(tmp) / f"{name}.png"
            src.write_text(page())
            subprocess.run(["node", str(pathlib.Path(__file__).with_name("render_svg.js")), str(src), str(png),
                            str(festivals.PAGE_W), str(festivals.PAGE_H)], check=True)
            gray = Image.open(png).convert("L")
            buf = io.BytesIO()
            gray.save(buf, format="PNG", optimize=True)
            (out / f"{name}.png").write_bytes(buf.getvalue())


if __name__ == "__main__":
    main()
