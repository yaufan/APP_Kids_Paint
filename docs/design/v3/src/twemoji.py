"""Coloring-page line art from Twemoji.

Twemoji (https://github.com/jdecked/twemoji) graphics are CC BY 4.0: free to
use and change, commercially too, as long as they are credited. The source
SVGs used here sit in twemoji/ with their license (LICENSE-GRAPHICS).

A Twemoji is a stack of flat colored shapes. Drawn in the same order with a
white fill and an ink outline, the shapes on top hide the lines below them,
so what is left is the outline of every colored area: a coloring page whose
areas are the ones the artist colored. Small dark shapes (eyes, nostrils)
stay solid ink.

    python3 twemoji.py 1f418 [1f996 ...]   # preview sheets with part numbers in /tmp
"""
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

DIR = Path(__file__).with_name("twemoji")
NS = "{http://www.w3.org/2000/svg}"
INK = "#222222"


def shapes(code):
    """The drawable shapes of a Twemoji, in paint order: (tag, attributes, fill)."""
    root = ET.parse(DIR / f"{code}.svg").getroot()
    out = []

    def walk(el, fill):
        fill = el.get("fill", fill)
        tag = el.tag.replace(NS, "")
        if tag in ("path", "circle", "ellipse", "rect", "polygon"):
            attrs = {k: v for k, v in el.attrib.items() if k not in ("fill", "opacity")}
            out.append((tag, attrs, fill))
        for child in el:
            walk(child, fill)

    walk(root, "#000000")
    return out


def luminance(color):
    color = color.lstrip("#")
    if len(color) == 3:
        color = "".join(c * 2 for c in color)
    r, g, b = (int(color[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def element(tag, attrs, style):
    a = " ".join(f'{k}="{v}"' for k, v in attrs.items())
    return f"<{tag} {a} {style}/>"


class Pen:
    """How the line art is drawn: ink color and line width (in the units the
    shapes are drawn in, so a scaled-up Twemoji gets a thinner number)."""

    def __init__(self, width=0.6, ink=INK):
        self.width, self.ink = width, ink

    @property
    def area(self):
        """An area to color: white with an ink outline."""
        return (f'fill="#FFFFFF" stroke="{self.ink}" stroke-width="{self.width:.3f}" '
                f'stroke-linejoin="round" stroke-linecap="round"')

    @property
    def solid(self):
        """Solid ink: eyes, nostrils, stripes."""
        return f'fill="{self.ink}" stroke="none"'

    @property
    def line(self):
        """A line on its own: a mouth, a crease."""
        return (f'fill="none" stroke="{self.ink}" stroke-width="{self.width:.3f}" '
                f'stroke-linejoin="round" stroke-linecap="round"')


def parts(code, pen, drop=(), black=(), white=(), dark=0.2):
    """Each part of the Twemoji as line art (None where dropped), in paint
    order and in its own 36 x 36 units, so extra shapes can go in between.

    drop: part numbers to leave out (shading, sparkles); black: parts drawn
    as solid ink; white: dark parts that should still be colorable. By
    default a part is solid ink when its color is darker than [dark] and it
    is small (an eye), otherwise an area to color.
    """
    out = []
    for i, (tag, attrs, fill) in enumerate(shapes(code)):
        if i in drop:
            out.append(None)
            continue
        solid = i in black or (i not in white and fill != "none" and luminance(fill) < dark and _small(tag, attrs))
        out.append(element(tag, attrs, pen.solid if solid else pen.area))
    return out


def line_art(code, pen, drop=(), black=(), white=(), dark=0.2):
    """The whole Twemoji as line art (see [parts])."""
    return "".join(p for p in parts(code, pen, drop, black, white, dark) if p)


def bounds(code, drop=()):
    """Bounding box (x0, y0, x1, y1) of the parts kept, in 36 x 36 units.
    Curve control points count too, so it can be a little generous."""
    xs, ys = [], []
    for i, (tag, attrs, _) in enumerate(shapes(code)):
        if i in drop:
            continue
        for x, y in _points(tag, attrs):
            xs.append(x)
            ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def _points(tag, attrs):
    if tag == "circle":
        cx, cy, r = (float(attrs[k]) for k in ("cx", "cy", "r"))
        return [(cx - r, cy - r), (cx + r, cy + r)]
    if tag == "ellipse":
        cx, cy, rx, ry = (float(attrs[k]) for k in ("cx", "cy", "rx", "ry"))
        r = max(rx, ry)  # it may be rotated
        return [(cx - r, cy - r), (cx + r, cy + r)]
    if tag == "rect":
        x, y, w, h = (float(attrs.get(k, 0)) for k in ("x", "y", "width", "height"))
        return [(x, y), (x + w, y + h)]
    return _path_points(attrs.get("d", ""))


def _path_points(d):
    """Every end and control point of an SVG path, in absolute units."""
    tokens = re.findall(r"[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?", d)
    sizes = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7, "Z": 0}
    pts, x, y, sx, sy, cmd, i = [], 0.0, 0.0, 0.0, 0.0, "M", 0
    while i < len(tokens):
        if tokens[i].isalpha():
            cmd = tokens[i]
            i += 1
            if cmd in "Zz":
                x, y = sx, sy
                continue
        n = sizes[cmd.upper()]
        args = [float(t) for t in tokens[i:i + n]]
        i += n
        rel = cmd.islower()
        up = cmd.upper()
        if up == "H":
            x = x + args[0] if rel else args[0]
            pts.append((x, y))
        elif up == "V":
            y = y + args[0] if rel else args[0]
            pts.append((x, y))
        elif up == "A":
            x, y = (x + args[5], y + args[6]) if rel else (args[5], args[6])
            pts.append((x, y))
        else:
            for k in range(0, n, 2):
                px, py = (x + args[k], y + args[k + 1]) if rel else (args[k], args[k + 1])
                pts.append((px, py))
            x, y = pts[-1]
        if up == "M":
            sx, sy = x, y
            cmd = "l" if rel else "L"  # more pairs after a move are lines
    return pts


def _small(tag, attrs):
    if tag == "circle":
        return float(attrs["r"]) < 2.6
    if tag == "ellipse":
        return max(float(attrs["rx"]), float(attrs["ry"])) < 2.6
    if tag == "path":
        nums = [float(n) for n in re.findall(r"-?\d*\.?\d+", attrs.get("d", ""))]
        return len(nums) < 40
    return False


def preview(code):
    """An HTML sheet: the original, the line art, then every part on its own
    (in red over the rest), numbered, for choosing drop / black / white."""
    items = shapes(code)
    def svg(body, size=160):
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 36 36">{body}</svg>'
    faint = "".join(element(t, a, 'fill="#eee" stroke="#ccc" stroke-width="0.1"') for t, a, _ in items)
    cells = [("original", svg("".join(element(t, a, f'fill="{f}"') for t, a, f in items))),
             ("line art", svg(line_art(code, Pen(0.35))))]
    for i, (tag, attrs, fill) in enumerate(items):
        cells.append((f"{i} {fill}", svg(faint + element(tag, attrs, 'fill="#e33" stroke="#000" stroke-width="0.2"'), 110)))
    body = "".join(f'<div style="display:inline-block;text-align:center;margin:2px;font:11px sans-serif">{c}<br>{t}</div>' for t, c in cells)
    return f'<html><body style="margin:4px;background:#fff">{body}</body></html>'


if __name__ == "__main__":
    for code in sys.argv[1:]:
        Path(f"/tmp/tw_{code}.html").write_text(preview(code))
        print(f"/tmp/tw_{code}.html", len(shapes(code)), "parts")
