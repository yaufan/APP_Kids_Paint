"""Writes the v3 art into the app: app/assets/art/** and lib/features/town/town_layout_data.dart.

    python3 export_art.py
"""
import io
import math
import pathlib
import re
import subprocess
import tempfile

from PIL import Image

import creatures
import festivals
import kit
import screens
import town

APP = pathlib.Path(__file__).resolve().parents[4] / "app"
ART = APP / "assets" / "art"

# Placeholders the app swaps for the chosen color (see lib/app/art.dart).
TOKEN, TOKEN_DARK, TOKEN_LIGHT = "#C0FFEE", "#C0FFE1", "#C0FFE2"


# Stamp shapes, black, tinted by the app; the canvas draws the same shapes
# (lib/features/canvas/coloring.dart, stampContains).
def _star():
    pts = []
    for k in range(10):
        r = 1 if k % 2 == 0 else 0.45
        pts.append(f"{r * math.sin(k * math.pi / 5):.3f} {-r * math.cos(k * math.pi / 5):.3f}")
    return f'<svg viewBox="-1 -1 2 2" width="48" height="48"><path d="M{" L".join(pts)} Z" fill="#000"/></svg>'


def _flower():
    petals = "".join(f'<circle cx="{0.55 * math.sin(k * 2 * math.pi / 5):.3f}" cy="{-0.55 * math.cos(k * 2 * math.pi / 5):.3f}" r="0.42" fill="#000"/>'
                     for k in range(5))
    return f'<svg viewBox="-1 -1 2 2" width="48" height="48">{petals}<circle r="0.4" fill="#000"/></svg>'


STAMPS = {
    "star": _star(),
    "heart": '<svg viewBox="-1.3 -1.2 2.6 2.4" width="48" height="48"><path d="M0 1 C -1.6 -0.1, -1.1 -1.2, 0 -0.45 C 1.1 -1.2, 1.6 -0.1, 0 1 Z" fill="#000"/></svg>',
    "flower": _flower(),
    "paw": '<svg viewBox="-1 -1 2 2" width="48" height="48"><ellipse cy="0.35" rx="0.55" ry="0.45" fill="#000"/>'
           '<circle cx="-0.62" cy="-0.2" r="0.22" fill="#000"/><circle cx="-0.24" cy="-0.6" r="0.24" fill="#000"/>'
           '<circle cx="0.24" cy="-0.6" r="0.24" fill="#000"/><circle cx="0.62" cy="-0.2" r="0.22" fill="#000"/></svg>',
}


def standalone(svg):
    svg = re.sub(r' (role|aria-label|aria-hidden)="[^"]*"', "", svg)
    svg = re.sub(r' style="[^"]*"', "", svg, count=1)
    if "xmlns=" in svg.split(">", 1)[0]:
        return svg
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
    for cid in creatures.CREATURES:
        write(f"creatures/{cid}.svg", creatures.outline(cid))
    for habitat, scene in creatures.SCENES.items():
        write(f"scenes/{habitat}.svg", scene())
    export_pages()
    # Tools in the chosen color: the generator's shades of a token color are
    # replaced by tokens the app fills in.
    base = "#FF5E5B"
    for name, fn in [("bucket", screens.tool_bucket), ("crayon", screens.tool_crayon),
                     ("glitter", screens.tool_glitter_pen), ("stamp", screens.tool_stamp)]:
        svg = fn(base).replace(kit.shade(base, -0.25), TOKEN_DARK).replace(kit.shade(base, 0.15), TOKEN_LIGHT).replace(base, TOKEN)
        write(f"tools/{name}.svg", svg)
    write("tools/rainbow.svg", screens.tool_rainbow())
    write("tools/eraser.svg", screens.tool_eraser())
    for shape, svg in STAMPS.items():
        write(f"stamps/{shape}.svg", svg)
    town.export(APP)


def export_pages():
    """Coloring pages as grayscale PNGs: app/assets/pages/<festival or creature>.png."""
    out = APP / "assets" / "pages"
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        pages = {**festivals.PAGES, **{cid: draw for cid, (_, draw) in creatures.CREATURES.items()}}
        for name, page in pages.items():
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
