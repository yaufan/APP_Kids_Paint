"""The food in the places where animals live (0.19): tap it, and the
animals walk (swim, fly) over and eat.

Each is three layers in the same 300 x 240 box, stacked in the app: the
back of the container, the food, the front of the container. The food
stands on the rim (y = RIM) and sinks into the container as it is eaten
(the app squashes it toward the rim); the container's bottom middle is
where it stands in the scene.

    python3 feeders.py [sheet.png]    # writes app/assets/art/feed/; a sheet to look at

Same drawing as the characters (kawaii.py), with lines as thick as theirs
look in the scene.
"""
import pathlib
import subprocess
import sys
import tempfile

from PIL import Image

from kawaii import INK, LEAF, RED, WHITE, YELLOW, circle, ellipse

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parents[2] / "app" / "assets" / "art" / "feed"
W, H, RIM = 300, 240, 150
LINE, FINE = 6, 4


def _s(w):
    return f'stroke="{INK}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"'


def path(d, fill, w=LINE):
    return f'<path d="{d}" fill="{fill}" {_s(w)}/>'


def stroke(d, w=FINE, color=INK):
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'


def greens(d):
    """Leafy tops (a carrot's): green bands with a dark edge."""
    return stroke(d, w=11) + stroke(d, w=5, color=LEAF)


def oval(cx, cy, rx, ry, fill, w=LINE, rot=0):
    return ellipse(cx, cy, rx, ry, fill, w=w, rot=rot)


def dot(cx, cy, r, fill, w=LINE):
    return circle(cx, cy, r, fill, w=w)


def svg(parts):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(parts)}</svg>'


# ---------------------------------------------------------------- the zoo: a basket of fruit

def zoo():
    back = [oval(150, RIM, 112, 22, "#A8682F")]
    food = [
        # A bunch of bananas leaning left, an apple, an orange.
        path("M70 160 C 64 112, 82 76, 112 62 C 104 92, 104 124, 116 160 Z", YELLOW),
        path("M96 160 C 94 116, 112 84, 142 74 C 132 102, 132 130, 140 160 Z", "#FFE27A"),
        stroke("M112 62 L 118 54", w=8, color="#7A5230"),
        dot(184, 128, 34, RED), stroke("M184 96 C 184 88, 188 84, 192 82", w=FINE),
        path("M188 92 C 200 80, 214 82, 218 90 C 206 96, 196 96, 188 92 Z", LEAF, w=FINE),
        dot(226, 140, 28, "#FF9F45"),
        dot(150, 146, 24, "#FFD84D"),
    ]
    front = [
        path("M36 150 Q 150 186 264 150 L 244 226 Q 150 244 56 226 Z", "#E3A35E"),
        stroke("M48 178 Q 150 208 252 178"), stroke("M54 204 Q 150 230 246 204"),
        *[stroke(f"M{x} {170 + abs(x - 150) // 12} L {x + (x - 150) // 14} {226 - abs(x - 150) // 18}") for x in (86, 118, 150, 182, 214)],
        stroke("M36 150 Q 150 186 264 150", w=14, color=INK), stroke("M36 150 Q 150 186 264 150", w=8, color="#C9833F"),
    ]
    return back, food, front


# ---------------------------------------------------------------- the aquarium: a clam with pellets

def aquarium():
    shell = "#FFB3C7"
    back = [
        # The top half of the shell, open behind.
        path("M58 150 C 52 88, 98 40, 150 40 C 202 40, 248 88, 242 150 Z", shell),
        *[stroke(f"M150 148 L {150 + dx} {58 + abs(dx) // 2}") for dx in (-70, -36, 0, 36, 70)],
        oval(150, RIM, 92, 16, "#F28FAA"),
    ]
    food = [dot(x, y, 11, c, w=FINE) for x, y, c in [
        (104, 150, "#C9844E"), (128, 142, "#E0A060"), (154, 146, "#C9844E"), (180, 141, "#E0A060"), (202, 151, "#C9844E"),
        (116, 128, "#E0A060"), (142, 122, "#C9844E"), (168, 124, "#E0A060"), (192, 131, "#C9844E"), (154, 102, WHITE)]]
    front = [
        path("M54 150 Q 150 176 246 150 C 238 204, 196 232, 150 232 C 104 232, 62 204, 54 150 Z", shell),
        *[stroke(f"M150 228 L {150 + dx} {162 + abs(dx) // 14}") for dx in (-64, -32, 0, 32, 64)],
    ]
    return back, food, front


# ---------------------------------------------------------------- the dinosaur park: a stone bowl of leaves

def dino_park():
    back = [oval(150, RIM, 108, 20, "#7D786E")]
    fern = "#58B368"
    food = []
    for angle, length in ((-38, 104), (-16, 120), (8, 124), (30, 110), (-56, 82), (50, 86)):
        food.append(f'<g transform="rotate({angle} 150 160)">'
                    + path(f"M150 162 C 126 {150 - length * 0.5}, 136 {164 - length}, 150 {156 - length} "
                           f"C 164 {164 - length}, 174 {150 - length * 0.5}, 150 162 Z", fern)
                    + stroke(f"M150 158 L 150 {164 - length}") + "</g>")
    food += [dot(118, 142, 14, "#FF5E5B", w=FINE), dot(134, 150, 12, "#FF5E5B", w=FINE), dot(188, 146, 14, "#A98BFF", w=FINE)]
    front = [
        path("M40 150 Q 150 180 260 150 C 256 206, 212 234, 150 234 C 88 234, 44 206, 40 150 Z", "#BDB6A8"),
        oval(98, 196, 14, 9, "#A39C8E", w=FINE), oval(196, 206, 18, 10, "#A39C8E", w=FINE), oval(150, 186, 9, 6, "#A39C8E", w=FINE),
    ]
    return back, food, front


# ---------------------------------------------------------------- the insect house: watermelon on a dish

def insects():
    back = [oval(150, RIM + 26, 116, 18, "#C98F55")]
    food = []
    for cx, rot in ((112, -18), (186, 16)):
        food.append(f'<g transform="rotate({rot} {cx} 176)">'
                    + path(f"M{cx - 58} 170 Q {cx} 190 {cx + 58} 170 L {cx} 66 Z", "#FF6F7D")
                    + stroke(f"M{cx - 58} 170 Q {cx} 190 {cx + 58} 170", w=16, color=INK)
                    + stroke(f"M{cx - 58} 170 Q {cx} 190 {cx + 58} 170", w=10, color="#6BCB77")
                    + "".join(oval(cx + dx, y, 4, 7, INK, w=1) for dx, y in ((-18, 150), (6, 140), (20, 158), (-4, 118), (8, 100)))
                    + "</g>")
    front = [
        path("M30 176 Q 150 202 270 176 C 262 212, 214 230, 150 230 C 86 230, 38 212, 30 176 Z", "#E8B678"),
        stroke("M58 204 Q 150 222 242 204"),
    ]
    return back, food, front


# ---------------------------------------------------------------- the polar sea: a bucket of fish

def polar():
    back = [
        stroke("M62 150 C 62 60, 238 60, 238 150", w=12, color=INK), stroke("M62 150 C 62 60, 238 60, 238 150", w=6, color="#C7D3DE"),
        oval(150, RIM, 92, 18, "#5B6E82"),
    ]
    food = []
    for x, rot, color in ((112, -20, "#7CB8E8"), (150, 4, "#A0C8EC"), (190, 22, "#7CB8E8")):
        food.append(f'<g transform="rotate({rot} {x} 170)">'
                    + path(f"M{x - 18} 176 C {x - 22} 130, {x - 12} 112, {x} 104 C {x + 12} 112, {x + 22} 130, {x + 18} 176 Z", color)
                    + path(f"M{x} 106 L {x - 22} 74 Q {x} 84 {x + 22} 74 Z", color, w=FINE)
                    + "</g>")
    front = [
        path("M58 150 Q 150 172 242 150 L 226 228 Q 150 242 74 228 Z", "#9FB6CC"),
        stroke("M64 176 Q 150 198 236 176", w=FINE), stroke("M70 206 Q 150 226 230 206", w=FINE),
        dot(62, 154, 7, "#C7D3DE", w=FINE), dot(238, 154, 7, "#C7D3DE", w=FINE),
    ]
    return back, food, front


# ---------------------------------------------------------------- the farm: a trough of hay and carrots

def farm():
    wood, dark = "#C98B57", "#A26A3B"
    back = [path("M34 150 L 266 150 L 256 138 L 44 138 Z", dark)]
    food = [
        path("M44 158 C 40 120, 70 104, 96 116 C 104 88, 140 80, 158 104 C 176 82, 218 90, 220 118 C 246 108, 266 128, 256 158 Z", "#F2C94C"),
        *[stroke(f"M{x} {y} L {x + dx} {y - 20}", color="#C99A2E") for x, y, dx in ((80, 140, -8), (112, 130, 6), (150, 126, -4), (186, 130, 8), (222, 140, -6))],
        f'<g transform="rotate(-24 110 140)">' + greens("M110 94 L 98 72 M110 94 L 112 68 M110 94 L 124 74") + path("M100 150 L 120 150 L 110 92 Z", "#FF9F45") + "</g>",
        f'<g transform="rotate(20 196 140)">' + greens("M196 98 L 184 76 M196 98 L 198 72 M196 98 L 210 78") + path("M186 150 L 206 150 L 196 96 Z", "#FF9F45") + "</g>",
    ]
    front = [
        path("M54 214 L 54 238 L 76 238 L 76 214 Z", dark), path("M224 214 L 224 238 L 246 238 L 246 214 Z", dark),
        path("M30 150 L 270 150 L 254 218 L 46 218 Z", wood),
        stroke("M38 174 L 262 174", w=FINE), stroke("M42 196 L 258 196", w=FINE),
        dot(56, 162, 4, INK, w=1), dot(244, 162, 4, INK, w=1), dot(60, 206, 4, INK, w=1), dot(240, 206, 4, INK, w=1),
    ]
    return back, food, front


FEEDERS = {"zoo": zoo, "aquarium": aquarium, "dinoPark": dino_park, "insects": insects, "polar": polar, "farm": farm}
LAYERS = ("back", "food", "front")


def export():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, draw in FEEDERS.items():
        for layer, parts in zip(LAYERS, draw()):
            (OUT / f"{name}_{layer}.svg").write_text(svg(parts))
    print(f"{len(FEEDERS) * len(LAYERS)} pictures in {OUT}")


def sheet(out):
    """Every feeder full, half eaten and nearly empty, to look at."""
    import preview
    tile = 220
    image = Image.new("RGB", (len(FEEDERS) * tile, 3 * tile), "#E9F3DF")
    with tempfile.TemporaryDirectory() as tmp:
        for i, (name, draw) in enumerate(FEEDERS.items()):
            back, food, front = draw()
            for j, level in enumerate((1.0, 0.5, 0.15)):
                squash = f'<g transform="translate(0 {RIM * (1 - level)}) scale(1 {level})">{"".join(food)}</g>'
                src = pathlib.Path(tmp) / f"{name}{j}.svg"
                png = pathlib.Path(tmp) / f"{name}{j}.png"
                src.write_text(svg(back + [squash] + front))
                subprocess.run(["node", str(preview.RENDER), str(src), str(png), str(W), str(H)], check=True)
                im = Image.open(png).convert("RGBA")
                bg = Image.new("RGBA", im.size, "#E9F3DF")
                bg.alpha_composite(im)
                image.paste(bg.convert("RGB").resize((tile, tile * H // W), Image.LANCZOS), (i * tile, j * tile))
    image.save(out)


if __name__ == "__main__":
    export()
    if len(sys.argv) > 1:
        sheet(sys.argv[1])
