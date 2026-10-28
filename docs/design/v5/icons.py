"""Small pictures in the coloring-page style (0.15):

- buddy(kind): the animal friends a child picks on the first day, as big
  friendly heads (app/assets/art/animals/<kind>.svg).
- place_icon(kind): a place you can go into, as one of its characters on
  a soft round badge (app/assets/art/places/<kind>.svg); the other places
  keep their little buildings (docs/design/v3/src/kit.py).

    python3 icons.py [sheet.png]    # writes them into the app; a sheet to look at

docs/design/v3/src/export_art.py takes these too, so running it keeps them.
"""
import pathlib
import re
import sys
import tempfile

from PIL import Image

import characters
from kawaii import (DETAIL, GREEN, INK, ORANGE, PINK, WHITE, cheek, circle, ellipse, eye, line, mirror, shape, smile)

HERE = pathlib.Path(__file__).resolve().parent
APP = HERE.parents[2] / "app"
BOX = 400  # the buddies are drawn in a 400 x 400 square


def _svg(parts, view=f"0 0 {BOX} {BOX}", size=64):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="{view}">{"".join(parts)}</svg>'


def _bear():
    fur, inner, muzzle = "#C98B5E", "#F3C9A0", "#F6DCC0"
    ear = [circle(98, 102, 54, fur), circle(98, 102, 28, inner, w=DETAIL)]
    return [*ear, mirror(ear, BOX / 2),
            circle(200, 230, 150, fur),
            ellipse(200, 290, 70, 52, muzzle, w=DETAIL),
            ellipse(200, 268, 21, 15, "#5A3E2B", w=4), line("M200 283 V 296", w=5),
            smile(200, 302, 24, 7),
            eye(140, 216, 15), eye(260, 216, 15),
            cheek(104, 280), cheek(296, 280)]


def _rabbit():
    fur = "#FFF7F0"
    ear = [ellipse(146, 104, 36, 92, fur, rot=-10), ellipse(146, 112, 16, 62, PINK, w=DETAIL, rot=-10)]
    return [*ear, mirror(ear, BOX / 2),
            circle(200, 256, 136, fur),
            eye(148, 244, 15), eye(252, 244, 15),
            ellipse(200, 284, 14, 10, PINK, w=4),
            smile(200, 312, 24, 7),
            cheek(112, 300), cheek(288, 300)]


def _cat():
    fur, stripe = "#FFB766", "#E8923A"
    ear = [shape("M92 176 L 84 50 L 186 112 Z", fur), shape("M106 154 L 102 80 L 164 118 Z", PINK, w=DETAIL)]
    return [*ear, mirror(ear, BOX / 2),
            ellipse(200, 240, 160, 136, fur),
            *[shape(f"M{x - 9} 106 Q {x} 98 {x + 9} 106 L {x + 5} 150 Q {x} 156 {x - 5} 150 Z", stripe, w=4) for x in (172, 200, 228)],
            eye(138, 232, 15), eye(262, 232, 15),
            shape("M186 266 h 28 l -14 14 z", PINK, w=4),
            line("M200 280 Q 186 298 170 286 M200 280 Q 214 298 230 286", w=5),
            line("M96 270 L 40 260 M96 290 L 42 298 M304 270 L 360 260 M304 290 L 358 298", w=4),
            cheek(112, 296), cheek(288, 296)]


def _dog():
    fur, ear_color, spot = "#F2D3A8", "#B07548", "#E0B07A"
    ear = [ellipse(84, 218, 44, 94, ear_color, rot=14)]
    return [circle(200, 222, 142, fur),
            ellipse(262, 196, 48, 42, spot, w=DETAIL),
            *ear, mirror(ear, BOX / 2),
            ellipse(200, 284, 72, 52, WHITE, w=DETAIL),
            ellipse(200, 260, 25, 17, INK, w=4),
            smile(200, 294, 30, 9),
            eye(144, 206, 15), eye(260, 206, 15),
            cheek(122, 270), cheek(278, 270)]


def _panda():
    black = "#3A3A46"
    return [circle(98, 104, 50, black), circle(302, 104, 50, black),
            circle(200, 232, 150, WHITE),
            ellipse(144, 226, 38, 50, black, rot=28), ellipse(256, 226, 38, 50, black, rot=-28),
            circle(148, 224, 24, WHITE, w=0), circle(252, 224, 24, WHITE, w=0),
            eye(148, 224, 13), eye(252, 224, 13),
            ellipse(200, 282, 21, 14, INK, w=0),
            line("M200 294 V 304", w=5), smile(200, 308, 22, 6),
            cheek(108, 292), cheek(292, 292)]


def _fox():
    fur = ORANGE
    ear = [shape("M84 180 L 66 40 L 180 114 Z", fur), shape("M96 156 L 86 74 L 154 118 Z", "#FFE9D2", w=DETAIL)]
    return [*ear, mirror(ear, BOX / 2),
            ellipse(200, 236, 152, 132, fur),
            shape("M58 252 C 104 236 160 248 200 300 C 240 248 296 236 342 252 C 322 330 262 366 200 368 "
                  "C 138 366 78 330 58 252 Z", WHITE, w=DETAIL),
            eye(138, 218, 15), eye(262, 218, 15),
            ellipse(200, 304, 19, 13, INK, w=0),
            smile(200, 330, 22, 6),
            cheek(112, 284), cheek(288, 284)]


def _frog():
    skin = "#8CD47E"
    return [circle(118, 130, 66, skin), circle(282, 130, 66, skin),
            ellipse(200, 252, 176, 128, skin),
            circle(118, 130, 44, WHITE, w=0), circle(282, 130, 44, WHITE, w=0),
            eye(118, 132, 16), eye(282, 132, 16),
            circle(186, 226, 5, INK, w=0), circle(214, 226, 5, INK, w=0),
            smile(200, 262, 64, 14),
            cheek(84, 268), cheek(316, 268)]


def _penguin():
    coat = "#3D4A66"
    return [circle(200, 222, 156, coat),
            shape("M200 146 C 150 92 66 124 72 214 C 78 304 148 356 200 356 C 252 356 322 304 328 214 "
                  "C 334 124 250 92 200 146 Z", WHITE),
            eye(146, 222, 15), eye(254, 222, 15),
            shape("M176 262 L 224 262 L 200 292 Z", ORANGE, w=6),
            cheek(108, 276), cheek(292, 276)]


BUDDIES = {"bear": _bear, "rabbit": _rabbit, "cat": _cat, "dog": _dog, "panda": _panda, "fox": _fox, "frog": _frog,
           "penguin": _penguin}


def buddy(kind, size=64):
    return _svg(BUDDIES[kind](), size=size)


# The places you can go into: kind -> (its character, its badge's color,
# and for a tall one, the part shown: its head).
PLACES = {
    "zoo": ("lion", "#FFE6B8", (106, 106, 494, 494)),
    "aquarium": ("whale", "#D6ECFF"),
    "dinoPark": ("trex", "#DDF5D2", (130, 150, 470, 476)),
    "transport": ("bus", "#FFE3D6"),
    "botanical": ("sunflower", "#E4F6D8"),
    "insects": ("ladybug", "#FFE0E6"),
    "shop": ("apple", "#FFF1C7"),
    "space": ("rocket", "#E2DCFF"),
    "food": ("takoyaki", "#FFE9CF"),
    "polar": ("penguin", "#DDF1FF"),
    "candy": ("lollipop", "#FFE3F1"),
    "grandma": ("cow", "#E6F5D8"),
}
_BOXES = {}  # character -> its drawing's bounding box on its page


def _box(name):
    """Where [name] is drawn on its 600 x 800 page (rendered once)."""
    if name not in _BOXES:
        import kawaii
        import preview
        with tempfile.TemporaryDirectory() as tmp:
            png = pathlib.Path(tmp) / "c.png"
            preview.render(kawaii.svg(characters.CHARACTERS[name]()), png)
            gray = Image.open(png).convert("L").point(lambda v: 255 if v < 250 else 0)
            _BOXES[name] = gray.getbbox()
    return _BOXES[name]


def place_icon(kind, size=64):
    """[kind]'s character on a round badge, or None for the places that are
    still little buildings."""
    if kind not in PLACES:
        return None
    name, badge, *part = PLACES[kind]
    x0, y0, x1, y1 = part[0] if part else _box(name)
    # The character fits in the badge's middle; lines twice as thick so
    # they still show at the size of a thumb.
    scale = 470 / max(x1 - x0, y1 - y0)
    tx, ty = 300 - scale * (x0 + x1) / 2, 300 - scale * (y0 + y1) / 2
    art = re.sub(r'stroke-width="([\d.]+)"', lambda m: f'stroke-width="{float(m.group(1)) * 1.8:.1f}"', "".join(characters.CHARACTERS[name]()))
    art = re.sub(r'id="([\w-]+)"', r'id="icon-\1"', art).replace('url(#', 'url(#icon-')
    return _svg([f'<circle cx="300" cy="300" r="296" fill="{badge}"/>',
                 '<defs><clipPath id="badge"><circle cx="300" cy="300" r="296"/></clipPath></defs>',
                 f'<g clip-path="url(#badge)"><g transform="translate({tx:.1f} {ty:.1f}) scale({scale:.3f})">{art}</g></g>'],
                view="0 0 600 600", size=size)


def export():
    for kind in BUDDIES:
        (APP / "assets" / "art" / "animals" / f"{kind}.svg").write_text(buddy(kind))
    for kind, (name, *_) in PLACES.items():
        if name in characters.CHARACTERS:
            (APP / "assets" / "art" / "places" / f"{kind}.svg").write_text(place_icon(kind))


def sheet(out):
    """Every buddy and badge, big and at a thumb's size, to look at."""
    import subprocess

    import preview
    names = [(k, buddy(k, 400)) for k in BUDDIES] + [(k, place_icon(k, 400)) for k, (n, *_) in PLACES.items() if n in characters.CHARACTERS]
    big, small = 160, 42
    image = Image.new("RGB", (len(names) * big, big + small + 20), "#FFF8EC")
    with tempfile.TemporaryDirectory() as tmp:
        for i, (kind, text) in enumerate(names):
            src, png = pathlib.Path(tmp) / f"{kind}.svg", pathlib.Path(tmp) / f"{kind}.png"
            src.write_text(text)
            subprocess.run(["node", str(preview.RENDER), str(src), str(png), "400", "400"], check=True)
            im = Image.open(png).convert("RGB")
            image.paste(im.resize((big, big), Image.LANCZOS), (i * big, 0))
            image.paste(im.resize((small, small), Image.LANCZOS), (i * big + (big - small) // 2, big + 10))
    image.save(out)


if __name__ == "__main__":
    export()
    if len(sys.argv) > 1:
        sheet(sys.argv[1])
