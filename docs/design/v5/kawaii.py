"""The coloring-page characters (0.11 on): drawn like a toddler's coloring
book, one big friendly character per page.

- Round, chunky shapes; a big head with big black eyes (a white shine),
  blush cheeks and a small smile.
- Thick, even black outlines (OUTLINE px), thinner inner lines (DETAIL px).
- Few, large areas to color; no texture, no shading, no background.

Each character is drawn once with its real colors (characters.py). The
coloring page is the same drawing with every color turned white; only
the eyes' black (INK) stays.

Pages are 600 x 800 (PAGE_W x PAGE_H); characters face right.
"""
import re

PAGE_W, PAGE_H = 600, 800
INK = "#222222"
OUTLINE, DETAIL = 9, 6

# Colors used by several characters.
PINK = "#FF9AAE"
BLUSH = "#FF9AAE"
WHITE = "#FFFFFF"
CREAM = "#FFF4DD"
RED = "#FF5E5B"
ORANGE = "#FF9F45"
YELLOW = "#FFD84D"
GREEN = "#6BCB77"
LEAF = "#58B368"
SKY = "#7CC7FF"
BLUE = "#4DA3FF"
PURPLE = "#A98BFF"
BROWN = "#B07548"
GRAY = "#A9B6C8"
DARK = "#4A4F5C"


def _stroke(w):
    return f'stroke="{INK}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"'


def ellipse(cx, cy, rx, ry, fill, w=OUTLINE, rot=0):
    t = f' transform="rotate({rot} {cx} {cy})"' if rot else ""
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{fill}" {_stroke(w)}{t}/>'


def circle(cx, cy, r, fill, w=OUTLINE):
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" {_stroke(w)}/>'


def shape(d, fill, w=OUTLINE):
    """A closed shape (an SVG path)."""
    return f'<path d="{d}" fill="{fill}" {_stroke(w)}/>'


def rect(x, y, w, h, r, fill, sw=OUTLINE):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" {_stroke(sw)}/>'


def line(d, w=DETAIL):
    """An open line (a fold, a smile)."""
    return f'<path d="{d}" fill="none" {_stroke(w)}/>'


def tube(d, width, fill):
    """A thick round-ended band along a path (a trunk, a neck, a stem)."""
    return (f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{width + 2 * OUTLINE}" stroke-linecap="round" stroke-linejoin="round"/>'
            f'<path d="{d}" fill="none" stroke="{fill}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>')


def mirror(parts, axis=PAGE_W / 2):
    """The same parts flipped left to right about x = [axis]."""
    return f'<g transform="translate({2 * axis} 0) scale(-1 1)">{"".join(parts)}</g>'


def scallop(cx, cy, r_in, r_out, n):
    """A round shape with [n] bumps (a lion's mane, a flower, a cloud)."""
    import math
    pts = []
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        pts.append((cx + r_in * math.cos(a), cy + r_in * math.sin(a)))
    d = f"M{pts[0][0]:.1f} {pts[0][1]:.1f}"
    for i in range(n):
        a = 2 * math.pi * (i + 0.5) / n
        c = (cx + r_out * math.cos(a), cy + r_out * math.sin(a))
        d += f" Q{c[0]:.1f} {c[1]:.1f} {pts[i + 1][0]:.1f} {pts[i + 1][1]:.1f}"
    return d + "Z"


def eye(x, y, r=15):
    """A big black eye with a white shine."""
    return (f'<ellipse cx="{x}" cy="{y}" rx="{r * 0.82:.1f}" ry="{r}" fill="{INK}"/>'
            f'<circle cx="{x - r * 0.28:.1f}" cy="{y - r * 0.38:.1f}" r="{r * 0.34:.1f}" fill="#FFFFFF"/>')


def cheek(x, y, rx=15, ry=10):
    return ellipse(x, y, rx, ry, BLUSH, w=4)


def smile(x, y, w=22, h=10):
    return line(f"M{x - w / 2} {y} Q {x} {y + h * 2} {x + w / 2} {y}")


def nostril(x, y, r=4):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}"/>'


def svg(parts, colored=True):
    """The character as an SVG page: in its colors, or as a coloring page."""
    body = "".join(parts)
    if not colored:
        keep = (INK, "#FFFFFF")
        body = re.sub(r'(fill|stroke)="(#[0-9A-Fa-f]{6})"',
                      lambda m: m.group(0) if m.group(2).upper() in keep else f'{m.group(1)}="#FFFFFF"', body)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {PAGE_W} {PAGE_H}" width="{PAGE_W}" height="{PAGE_H}">'
            f'<rect width="{PAGE_W}" height="{PAGE_H}" fill="#FFFFFF"/>{body}</svg>')
