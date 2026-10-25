"""Writes the v3 art into the app: app/assets/art/** and lib/features/town/town_layout_data.dart.

    python3 export_art.py
"""
import pathlib
import re

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
    write("logo.svg", screens.logo(48))
    write("ui/mini_album.svg", screens.mini_album(46))
    write("ui/mini_book.svg", screens.mini_book(46))
    # Tools in the chosen color: the generator's shades of a token color are
    # replaced by tokens the app fills in.
    base = "#FF5E5B"
    for name, fn in [("bucket", screens.tool_bucket), ("crayon", screens.tool_crayon)]:
        svg = fn(base).replace(kit.shade(base, -0.25), TOKEN_DARK).replace(kit.shade(base, 0.15), TOKEN_LIGHT).replace(base, TOKEN)
        write(f"tools/{name}.svg", svg)
    town.export(APP)


if __name__ == "__main__":
    main()
