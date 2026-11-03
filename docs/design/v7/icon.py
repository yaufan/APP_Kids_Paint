"""The app's icon (2.2): what a child taps on the phone's home screen.

Three ideas, drawn at 1024 x 1024 on a full square (the phone cuts its own
shape: a circle, a rounded square). What matters stays inside the middle
two thirds, the part Android's adaptive icons always show.

    python3 icon.py preview out_dir            # the three ideas, and how they look small
    python3 icon.py export island              # the chosen one into the Android and iOS projects
"""
import math
import pathlib
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "v6"))
sys.path.insert(0, str(HERE.parent / "v3" / "src"))

import islands  # noqa: E402
import town  # noqa: E402
from kit import shade  # noqa: E402

S = 1024
RAINBOW = ["#FF5E5B", "#FF9F45", "#FFD166", "#5FCB79", "#4DA3FF", "#8C6CFF"]


def rainbow(cx, cy, r, band, colors=RAINBOW):
    """Half a rainbow, outside band first."""
    out = []
    for i, c in enumerate(colors):
        rr = r - i * band
        out.append(f'<path d="M{cx - rr} {cy} A{rr} {rr} 0 0 1 {cx + rr} {cy}" fill="none" stroke="{c}" '
                   f'stroke-width="{band + 1}" stroke-linecap="round"/>')
    return "".join(out)


def crayon(x, y, length, width, angle, color="#FF5E5B"):
    """A fat crayon whose tip is at (x, y), lying at [angle] degrees."""
    d, l = shade(color, -0.25), shade(color, 0.2)
    tip = width * 0.95
    body = (f'<rect x="{tip}" y="{-width / 2}" width="{length - tip}" height="{width}" rx="{width * 0.18}" fill="{color}"/>'
            f'<rect x="{tip + (length - tip) * 0.18}" y="{-width / 2}" width="{(length - tip) * 0.16}" height="{width}" fill="{d}" opacity=".55"/>'
            f'<rect x="{tip + (length - tip) * 0.62}" y="{-width / 2}" width="{(length - tip) * 0.16}" height="{width}" fill="{d}" opacity=".55"/>'
            f'<rect x="{tip}" y="{-width / 2 + width * 0.12}" width="{length - tip - width * 0.1}" height="{width * 0.16}" rx="{width * 0.08}" fill="{l}" opacity=".7"/>'
            f'<path d="M0 0 L{tip} {-width / 2 + 2} L{tip} {width / 2 - 2} Z" fill="#F7E1C0"/>'
            f'<path d="M0 0 L{tip * 0.42} {-width * 0.21} L{tip * 0.42} {width * 0.21} Z" fill="{d}"/>')
    return f'<g transform="translate({x} {y}) rotate({angle})">{body}</g>'


def home_island(cx, top, width):
    """The home island from the map (islands.py), its top middle at (cx, top), [width] wide."""
    isl = islands.Island("home")
    x, y, w, h = isl.box
    k = width / w
    content = islands.island_base(isl, 3) + islands.building(isl) + islands.decor(isl)
    return f'<g transform="translate({cx - width / 2} {top}) scale({k}) translate({-x} {-y})">{content}</g>'


def cloud(cx, cy, r, color="#FFFFFF"):
    return (f'<g fill="{color}"><circle cx="{cx - r}" cy="{cy}" r="{r * 0.75}"/><circle cx="{cx}" cy="{cy - r * 0.35}" r="{r}"/>'
            f'<circle cx="{cx + r * 1.05}" cy="{cy + r * 0.05}" r="{r * 0.7}"/><rect x="{cx - r * 1.6}" y="{cy}" width="{r * 3.3}" height="{r * 0.7}" rx="{r * 0.35}"/></g>')


def idea_island():
    """A floating island with home on it, a rainbow drawn behind it and the crayon that drew it."""
    bg = ('<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5DB4F7"/>'
          '<stop offset="1" stop-color="#BFE8FF"/></linearGradient></defs><rect width="1024" height="1024" fill="url(#bg)"/>')
    return bg, (cloud(230, 300, 46) + cloud(810, 250, 38)
                + rainbow(512, 560, 330, 34)
                + home_island(512, 300, 560)
                + crayon(700, 640, 330, 92, -40, "#FF5E5B"))


def idea_drawn_house():
    """The house drawn in crayon on coral paper, a rainbow over it (the in-app logo grown up)."""
    ink = "#FFFFFF"
    house = (f'<path d="M300 560 L512 360 L724 560" fill="none" stroke="{ink}" stroke-width="46" stroke-linecap="round" stroke-linejoin="round"/>'
             f'<path d="M345 535 V760 H679 V535" fill="#FFF6E8" stroke="{ink}" stroke-width="40" stroke-linejoin="round"/>'
             f'<rect x="465" y="630" width="94" height="130" rx="40" fill="#FF9F45"/>'
             f'<rect x="385" y="580" width="62" height="62" rx="14" fill="#4DA3FF"/><rect x="577" y="580" width="62" height="62" rx="14" fill="#4DA3FF"/>')
    star = '<path d="M250 250 l22 46 50 7-36 35 9 50-45-24-45 24 9-50-36-35 50-7z" fill="#FFD166"/>'
    return ('<rect width="1024" height="1024" fill="#FF6F61"/>'
            '<path d="M0 820 C 200 760, 380 790, 512 830 C 650 780, 840 770, 1024 820 V1024 H0 Z" fill="#6BCB77"/>',
            rainbow(512, 470, 300, 26) + house + star + crayon(760, 760, 300, 84, -50, "#FFD166"))


def idea_bear():
    """The child's buddy (the bear) peeking over a postcard with a crayon."""
    bear = (HERE.parents[2] / "app/assets/art/animals/bear.svg").read_text()
    inner = bear[bear.index(">") + 1:bear.rindex("</svg>")]
    vb = bear.split('viewBox="')[1].split('"')[0].split()
    bw = float(vb[2])
    k = 520 / bw
    return ('<rect width="1024" height="1024" fill="#FFD166"/>',
            '<g transform="translate(512 640) rotate(-6)"><rect x="-300" y="-150" width="600" height="380" rx="36" fill="#FFFFFF"/>'
            + rainbow(0, 140, 220, 26).replace("<path", "<path opacity='.95'") + '</g>'
            + f'<g transform="translate({512 - 260} 170) scale({k})">{inner}</g>'
            + crayon(690, 720, 300, 88, -45, "#FF5E5B"))


IDEAS = {"island": idea_island, "house": idea_drawn_house, "bear": idea_bear}


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" viewBox="0 0 {S} {S}">'
            f'<defs>{town.DEFS}</defs>{body}</svg>')


def render(svg_text, out, size=S):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg_text.replace(f'width="{S}" height="{S}"', f'width="{size}" height="{size}"', 1))
    subprocess.run(["node", str(HERE.parent / "v6" / "render_alpha.js"), f.name, str(out), str(size), str(size)], check=True)


def preview(out_dir):
    out = pathlib.Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    for name, idea in IDEAS.items():
        render(svg("".join(idea())), out / f"icon_{name}.png")


def export(name):
    """Android: legacy squares and round icons in every density, and an adaptive icon
    (the same picture as its foreground on a plain background); iOS: every AppIcon size."""
    app = HERE.parents[2] / "app"
    back, front = IDEAS[name]()
    with tempfile.TemporaryDirectory() as tmp:
        big, bg_png, fg_png = (pathlib.Path(tmp) / n for n in ("icon.png", "bg.png", "fg.png"))
        render(svg(back + front), big)
        render(svg(back), bg_png)
        render(svg(front), fg_png)
        from PIL import Image, ImageDraw
        src = Image.open(big).convert("RGBA")
        bg_src, fg_src = Image.open(bg_png).convert("RGBA"), Image.open(fg_png).convert("RGBA")
        res = app / "android/app/src/main/res"
        for density, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
            d = res / f"mipmap-{density}"
            d.mkdir(parents=True, exist_ok=True)
            sq = src.resize((px, px), Image.LANCZOS)
            mask = Image.new("L", (px, px), 0)
            ImageDraw.Draw(mask).rounded_rectangle([0, 0, px - 1, px - 1], radius=px * 0.22, fill=255)
            rounded = Image.new("RGBA", (px, px), (0, 0, 0, 0))
            rounded.paste(sq, (0, 0), mask)
            rounded.save(d / "ic_launcher.png")
            circle = Image.new("L", (px, px), 0)
            ImageDraw.Draw(circle).ellipse([0, 0, px - 1, px - 1], fill=255)
            round_icon = Image.new("RGBA", (px, px), (0, 0, 0, 0))
            round_icon.paste(sq, (0, 0), circle)
            round_icon.save(d / "ic_launcher_round.png")
            # Adaptive (Android 8 and up): 108 dp layers of which about the middle 72 show.
            # The background fills it all; the picture sits in those middle 72.
            fg = (px * 108) // 48
            bg_src.resize((fg, fg), Image.LANCZOS).save(d / "ic_launcher_background.png")
            inner = (px * 72) // 48
            layer = Image.new("RGBA", (fg, fg), (0, 0, 0, 0))
            layer.paste(fg_src.resize((inner, inner), Image.LANCZOS), ((fg - inner) // 2, (fg - inner) // 2))
            layer.save(d / "ic_launcher_foreground.png")
        any_dpi = res / "mipmap-anydpi-v26"
        any_dpi.mkdir(exist_ok=True)
        xml = ('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
               '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
               '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
        (any_dpi / "ic_launcher.xml").write_text(xml)
        (any_dpi / "ic_launcher_round.xml").write_text(xml)
        ios = app / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
        for f in ios.glob("Icon-App-*.png"):
            w = float(f.name.split("-")[2].split("x")[0])
            scale = int(f.name.split("@")[1][0])
            px = round(w * scale)
            flat = Image.new("RGB", (px, px), (255, 255, 255))
            flat.paste(src.resize((px, px), Image.LANCZOS), (0, 0), src.resize((px, px), Image.LANCZOS))
            flat.save(f)
        # The picture itself, for the docs and the store page.
        src.save(HERE / f"icon_{name}.png")


if __name__ == "__main__":
    if sys.argv[1] == "preview":
        preview(sys.argv[2])
    elif sys.argv[1] == "export":
        export(sys.argv[2])
