"""The town as floating islands (2.0): every kind of place on an island of
its own, joined by rope bridges, in a sky that goes from the stars (space,
at the top) down to the sea (the beach and the aquarium, at the bottom).

The buildings are the town's (docs/design/v3/src/town.py), lifted off
their ground plates and set on the islands; every layer is drawn for day,
dusk and night with the town's tint. The world is W x H; a phone sees the
middle column, a wide screen more.

    python3 islands.py export            # app/assets/art/islands/*.svg and island_layout_data.dart
    python3 islands.py preview out.png [day|dusk|night] [festival]
"""
import json
import math
import pathlib
import re
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "v3" / "src"))

import festivals  # noqa: E402
import town  # noqa: E402
from kit import cloud, duck, shade, tower101, tree, flower_patch  # noqa: E402

# The islands' night (2.1): moonlit, not the first version's near-black, so
# a child can still tell the places apart. Lamps and windows still glow.
town.TINT = {**town.TINT, "night": ((0.7, 0.75, 0.86), (20, 26, 56))}

APP = HERE.parents[2] / "app"
W, H = 780, 1760
SEA = 1650  # where the sea starts
OX = 195  # the middle column a phone shows first

# ---------------------------------------------------------------- the islands

# How each kind of ground looks: top, its light rim, the lip at the front,
# the side (soil), its dark lines, the rock underneath.
GROUNDS = {
    "grass": ("#A6DE97", "#C6EDB4", "#7CC46F", "#C98B5E", "#A86E43", "#9A7B63"),
    "meadow": ("#B9E58F", "#D3F0B0", "#8CC768", "#C98B5E", "#A86E43", "#9A7B63"),
    "snow": ("#F4FBFF", "#FFFFFF", "#CFE5F7", "#BFD7EE", "#9FC4E6", "#8FB3D6"),
    "moon": ("#D8D2F2", "#ECE8FF", "#B9B0E0", "#8E86C4", "#6F67A8", "#5D5794"),
    "candy": ("#FFD1E3", "#FFE7F0", "#FFB0CF", "#D9A066", "#B57E46", "#E3B98A"),
    "sand": ("#F6E2B3", "#FFF0CF", "#E8CB8F", "#E3C48C", "#C9A774", "#C9A774"),
}

# The town's buildings, where they are in its world (measured with their
# plates off: x0, y0, x1, y1).
TOWN_BOXES = {
    "space": (14, 46, 186, 228), "polar": (604, 94, 776, 228), "candy": (205, 122, 367, 230), "home": (235, 341, 332, 428),
    "school": (427, 327, 565, 432), "park": (210, 474, 386, 645), "shop": (431, 558, 521, 608), "food": (204, 681, 388, 762),
    "temple": (423, 722, 551, 808), "zoo": (595, 689, 766, 807), "aquarium": (18, 691, 192, 814), "dinoPark": (16, 467, 199, 636),
    "transport": (602, 489, 767, 630), "botanical": (20, 914, 182, 1032), "insects": (601, 891, 766, 1042),
    "grandma": (204, 877, 383, 1017), "travel": (431, 899, 591, 1028),
}

# kind -> (x, y of the island's top middle, ground, building scale, sits in the sea)
ISLANDS = {
    "space": (120, 250, "moon", 0.95, False),
    "candy": (390, 230, "candy", 1.15, False),
    "polar": (660, 250, "snow", 0.95, False),
    "mountain": (205, 480, "meadow", 1.0, False),
    "city": (575, 480, "grass", 1.0, False),
    "dinoPark": (110, 720, "grass", 0.95, False),
    "home": (390, 720, "grass", 1.55, False),
    "transport": (672, 720, "grass", 0.95, False),
    # 2.1: the islands that start bare (GROWS) are out at the edges, the
    # ones always built round home in the middle.
    "zoo": (215, 950, "meadow", 0.95, False),
    "food": (565, 950, "grass", 0.95, False),
    "school": (110, 1180, "grass", 1.1, False),
    "insects": (390, 1180, "meadow", 0.95, False),
    "temple": (672, 1180, "grass", 1.2, False),
    "botanical": (130, 1410, "grass", 0.95, False),
    "grandma": (390, 1410, "meadow", 1.0, False),
    "park": (650, 1410, "grass", 0.95, False),
    "aquarium": (130, 1660, "sand", 0.95, True),
    "water": (390, 1672, "sand", 1.0, True),
    "travel": (650, 1660, "sand", 1.0, True),
}

# The places on each island: which kinds a postcard can be pinned to there.
# (The city has the shop, Taipei 101 and the MRT station.)
PLACES_ON = {"city": ("shop", "station"), "mountain": ("mountain",), "water": ("water",)}

# Built only once a postcard arrives (the rest are always there).
GROWS = {"school", "park", "temple", "travel"}

PLATE = re.compile(r'^(<g transform="translate\(195 0\)">)?<rect x="[\d.]+" y="[\d.]+" width="[\d.]+" height="[\d.]+" rx="2[06]" fill="#[0-9A-Fa-f]{6}"/>'
                   r'(<rect x="[\d.]+" y="[\d.]+" width="[\d.]+" height="[\d.]+" rx="26" fill="url\(#grassdots\)"/>)?')


# Trees the town drew at a building's edge, which would float off an island.
STRAY = {"zoo": [(752, 724, 11)], "transport": [(752, 616, 10)], "insects": [(752, 980, 11, "#58C46B")]}


def town_building(kind):
    """The town's drawing of [kind], its ground plate and stray trees taken away."""
    body = town.SLOTS[kind][0]()
    for args in STRAY.get(kind, []):
        body = body.replace(tree(*args), "")
    return PLATE.sub(lambda m: m.group(1) or "", body, count=1)


class Island:
    """One island: where its top is, how wide, and where its building goes."""

    def __init__(self, name):
        self.name = name
        self.cx, self.cy, self.ground, self.k, self.at_sea = ISLANDS[name]
        if name in TOWN_BOXES:
            x0, y0, x1, y1 = TOWN_BOXES[name]
            self.bw, self.bh = (x1 - x0) * self.k, (y1 - y0) * self.k
        else:
            self.bw, self.bh = {"city": (196, 176), "mountain": (176, 120), "water": (170, 70)}[name]
        if name == "park":
            self.bw, self.bh = 168, 80
        self.rx = max(84.0, self.bw / 2 / 0.86)
        self.ry = self.rx * 0.3
        self.side = 18 if self.at_sea else 24
        self.cone = 0 if self.at_sea else self.rx * 0.72
        # Where the building's bottom middle stands.
        self.base = (self.cx, self.cy + self.ry * 0.38)

    @property
    def top(self):
        """The highest point drawn: the building's top, or the island's."""
        return min(self.base[1] - self.bh - 6, self.cy - self.ry - 4)

    @property
    def bottom(self):
        return self.cy + self.side + self.cone + (10 if self.at_sea else 4)

    @property
    def box(self):
        """Its picture's box in the world: x, y, w, h (whole numbers)."""
        x0 = math.floor(self.cx - self.rx - 26)
        y0 = math.floor(self.top - 8)
        return (x0, y0, math.ceil(self.cx + self.rx + 26) - x0, math.ceil(self.bottom + 4) - y0)

    def rim(self, toward):
        """A point on the island's top edge facing [toward] (world coords)."""
        a = math.atan2((toward[1] - self.cy) * 3.3, toward[0] - self.cx)
        return (self.cx + self.rx * 0.82 * math.cos(a), self.cy + self.ry * 0.55 * math.sin(a))


def _blob(cx, cy, rx, ry, n=3.2, wob=0.0, seed=0, steps=48):
    """A rounded, slightly uneven top: a superellipse with a little wobble."""
    pts = []
    for i in range(steps):
        a = 2 * math.pi * i / steps
        c, s = math.cos(a), math.sin(a)
        r = 1 + wob * (math.sin(3 * a + seed) * 0.6 + math.sin(5 * a + seed * 1.7) * 0.4)
        x = cx + rx * r * math.copysign(abs(c) ** (2 / n), c)
        y = cy + ry * r * math.copysign(abs(s) ** (2 / n), s)
        pts.append((x, y))
    return pts


def _path(pts, close=True):
    """A smooth closed path through [pts] (Catmull-Rom as cubic Béziers)."""
    n = len(pts)
    d = [f"M{pts[0][0]:.1f} {pts[0][1]:.1f}"]
    for i in range(n if close else n - 1):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d.append(f"C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f}")
    return " ".join(d) + (" Z" if close else "")


def island_base(isl, seed=0):
    """The island itself: rock underneath, its soil side, its top."""
    top, rim, lip, soil, dark, rock = GROUNDS[isl.ground]
    cx, cy, rx, ry, d = isl.cx, isl.cy, isl.rx, isl.ry, isl.side
    shape = _blob(cx, cy, rx, ry, wob=0.035, seed=seed)
    s = []
    if isl.at_sea:
        # Sitting in the sea: foam all round at the waterline.
        s.append(f'<ellipse cx="{cx}" cy="{cy + d + 2}" rx="{rx * 1.1:.1f}" ry="{ry * 1.05:.1f}" fill="#FFFFFF" opacity=".75"/>')
        s.append(f'<ellipse cx="{cx}" cy="{cy + d + 4}" rx="{rx * 1.18:.1f}" ry="{ry * 1.1:.1f}" fill="none" stroke="#FFFFFF" stroke-width="2.5" opacity=".5"/>')
    else:
        # The rock underneath: a rounded cone with a few ledges, and roots.
        tip = (cx + rx * 0.12 * math.sin(seed), cy + d + isl.cone)
        left, right = (cx - rx * 0.98, cy + d * 0.6), (cx + rx * 0.98, cy + d * 0.6)
        cone = [left, (cx - rx * 0.72, cy + d + isl.cone * 0.35), (cx - rx * 0.36, cy + d + isl.cone * 0.7), tip,
                (cx + rx * 0.4, cy + d + isl.cone * 0.66), (cx + rx * 0.76, cy + d + isl.cone * 0.3), right]
        s.append(f'<path d="{_path(cone, close=False)} Z" fill="{rock}"/>')
        s.append(f'<path d="M{cx - rx * 0.5:.1f} {cy + d + isl.cone * 0.45:.1f} Q {cx - rx * 0.1:.1f} {cy + d + isl.cone * 0.62:.1f} {cx + rx * 0.3:.1f} {cy + d + isl.cone * 0.5:.1f}" '
                 f'stroke="{shade(rock, -0.18)}" stroke-width="3" fill="none" stroke-linecap="round"/>')
        s.append(f'<path d="M{cx - rx * 0.3:.1f} {cy + d + isl.cone * 0.78:.1f} q {rx * 0.15:.1f} {isl.cone * 0.06:.1f} {rx * 0.28:.1f} 0" '
                 f'stroke="{shade(rock, -0.18)}" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
        # Light on the rock's left, shadow on its right.
        s.append(f'<path d="M{left[0] + 6:.1f} {left[1] + 4:.1f} Q {cx - rx * 0.6:.1f} {cy + d + isl.cone * 0.4:.1f} {cx - rx * 0.3:.1f} {cy + d + isl.cone * 0.66:.1f}" '
                 f'stroke="{shade(rock, 0.18)}" stroke-width="5" fill="none" stroke-linecap="round" opacity=".7"/>')
        for k, (fx, length) in enumerate([(-0.55, 0.3), (-0.12, 0.42), (0.34, 0.26), (0.66, 0.2)]):
            x = cx + rx * fx
            y0 = cy + d + 2
            sway = 6 if k % 2 else -6
            s.append(f'<path d="M{x:.1f} {y0:.1f} q {sway} {isl.cone * length * 0.5:.1f} 0 {isl.cone * length:.1f}" stroke="#7FB26A" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
            s.append(f'<circle cx="{x + sway * 0.3:.1f}" cy="{y0 + isl.cone * length:.1f}" r="2.6" fill="#8FCB76"/>')
    # The side: the top's outline pushed down, and the band between.
    side = [(x, y + d) for x, y in shape]
    s.append(f'<path d="{_path(side)}" fill="{soil}"/>')
    s.append(f'<rect x="{cx - rx * 1.0:.1f}" y="{cy:.1f}" width="{rx * 2.0:.1f}" height="{d:.1f}" fill="{soil}"/>')
    for k, f in enumerate((0.42, 0.75)):
        y = cy + ry * 0.62 + d * f
        s.append(f'<path d="M{cx - rx * 0.86:.1f} {y:.1f} Q {cx:.1f} {y + ry * 0.5:.1f} {cx + rx * 0.86:.1f} {y:.1f}" stroke="{dark}" stroke-width="2" fill="none" opacity=".55"/>')
    for k in range(5):
        x = cx - rx * 0.7 + k * rx * 0.36
        y = cy + ry * 0.75 + d * (0.35 + 0.3 * (k % 2))
        s.append(f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="5" ry="3.4" fill="{dark}" opacity=".5"/>')
    # The top, its lip at the front and a light rim at the back.
    s.append(f'<path d="{_path(shape)}" fill="{lip}"/>')
    inner = [(x, y - 3.5) for x, y in _blob(cx, cy, rx * 0.985, ry * 0.97, wob=0.035, seed=seed)]
    s.append(f'<path d="{_path(inner)}" fill="{top}"/>')
    s.append(f'<path d="M{cx - rx * 0.78:.1f} {cy - ry * 0.55:.1f} Q {cx:.1f} {cy - ry * 1.12:.1f} {cx + rx * 0.78:.1f} {cy - ry * 0.55:.1f}" '
             f'stroke="{rim}" stroke-width="4" fill="none" stroke-linecap="round" opacity=".9"/>')
    if isl.ground == "candy":
        # Icing dripping over the side.
        drips = "".join(f'<path d="M{cx + rx * f - 7:.1f} {cy + ry * 0.7:.1f} q 7 {14 + 8 * (k % 2)} 14 0 z" fill="{top}"/>'
                        for k, f in enumerate((-0.8, -0.45, -0.1, 0.25, 0.6)))
        s.append(drips)
    if isl.ground == "moon":
        s.append("".join(f'<ellipse cx="{cx + rx * fx:.1f}" cy="{cy + ry * fy:.1f}" rx="{r}" ry="{r * 0.45:.1f}" fill="{lip}"/>'
                         for fx, fy, r in [(-0.6, -0.1, 9), (0.55, 0.2, 7), (0.2, -0.45, 5)]))
    return "".join(s)


def building(isl):
    """The town's building for [isl], set on its island."""
    if isl.name == "city":
        return city(isl)
    if isl.name == "mountain":
        return mountain(isl)
    if isl.name == "water":
        return beach(isl)
    if isl.name == "park":
        return park(isl)
    x0, y0, x1, y1 = TOWN_BOXES[isl.name]
    bx, by = isl.base
    k = isl.k
    tx, ty = bx - (x0 + x1) / 2 * k, by - y1 * k
    return f'<g transform="translate({tx:.1f} {ty:.1f}) scale({k})">{town_building(isl.name)}</g>'


def city(isl):
    """The city island: the shop, Taipei 101 and an MRT station."""
    bx, by = isl.base
    shop_k = 1.25
    x0, y0, x1, y1 = TOWN_BOXES["shop"]
    shop = f'<g transform="translate({bx - 40 - (x0 + x1) / 2 * shop_k:.1f} {by + 4 - y1 * shop_k:.1f}) scale({shop_k})">{town_building("shop")}</g>'
    station = (f'<g transform="translate({bx + 58} {by - 14})">'
               '<rect x="-30" y="-26" width="60" height="26" rx="6" fill="#E3F4FB" stroke="#7FA7C9" stroke-width="1.4"/>'
               '<path d="M-36 -26 Q 0 -44 36 -26 Z" fill="#4DA8FF" stroke="#2C7FD6" stroke-width="1.4"/>'
               '<circle cx="0" cy="-14" r="7" fill="#FFFFFF" stroke="#2C7FD6" stroke-width="1.6"/><path d="M-4 -14 h8" stroke="#2C7FD6" stroke-width="2"/>'
               '<rect x="-24" y="-8" width="12" height="8" rx="2" fill="#A9E0FF"/><rect x="12" y="-8" width="12" height="8" rx="2" fill="#A9E0FF"/></g>')
    tower = tower101(bx + 4, by - 4, 0.78)
    return tower + shop + station + tree(bx - 86, by + 2, 10) + tree(bx + 94, by - 2, 9, "#58C46B")


def park(isl):
    """The park island: a pond with ducks (they can be poked), a slide, trees."""
    bx, by = isl.base
    return (f'<path d="M{bx - 6} {by - 4} C {bx + 2} {by - 26}, {bx + 62} {by - 30}, {bx + 78} {by - 14} C {bx + 90} {by + 2}, {bx + 60} {by + 10}, {bx + 30} {by + 8} C {bx + 6} {by + 6}, {bx - 10} {by + 6}, {bx - 6} {by - 4} Z" '
            'fill="#7CCFFF" stroke="#43A9E0" stroke-width="1.5"/>'
            f'<path d="M{bx + 14} {by - 8} q 6 -3 12 0 M{bx + 46} {by - 2} q 6 -3 12 0" stroke="#D8F3FF" stroke-width="2" fill="none" stroke-linecap="round"/>'
            f'<g transform="translate({bx - 70} {by - 36})"><path d="M0 30 L8 0 H22 L22 30" stroke="#FF8FB1" stroke-width="4" fill="none" stroke-linejoin="round"/>'
            '<path d="M22 0 Q 44 8 46 30" stroke="#FFC94A" stroke-width="7" fill="none" stroke-linecap="round"/></g>'
            + tree(bx - 30, by - 12, 13) + tree(bx + 34, by - 20, 11, "#58C46B") + tree(bx + 92, by - 6, 10, "#4DB860", "pine")
            + flower_patch(bx - 80, by + 10) + flower_patch(bx - 20, by + 14, ("#FFFFFF", "#FF8FB1", "#FFD166")))


def mountain(isl):
    """The mountain island: two green peaks, a cable car going up."""
    bx, by = isl.base
    peaks = (f'<path d="M{bx - 88} {by} C {bx - 60} {by - 70}, {bx - 34} {by - 108}, {bx - 6} {by - 112} C {bx + 22} {by - 108}, {bx + 40} {by - 64}, {bx + 60} {by - 40} '
             f'C {bx + 72} {by - 64}, {bx + 84} {by - 70}, {bx + 96} {by - 50} L {bx + 100} {by} Z" fill="url(#mtB)"/>'
             f'<path d="M{bx - 88} {by} C {bx - 50} {by - 46}, {bx - 10} {by - 60}, {bx + 30} {by - 34} C {bx + 54} {by - 46}, {bx + 80} {by - 36}, {bx + 100} {by} Z" fill="url(#mtF)"/>'
             f'<path d="M{bx - 22} {by - 98} l 16 -14 l 14 12 q -14 8 -30 2 z" fill="#FFFFFF" opacity=".85"/>')
    cable = (f'<path d="M{bx - 74} {by - 6} L {bx - 6} {by - 108}" stroke="#5D6470" stroke-width="1.6"/>'
             + "".join(f'<g transform="translate({bx - 74 + 68 * f:.1f} {by - 6 - 102 * f:.1f})"><path d="M0 0 v 6" stroke="#5D6470" stroke-width="1.4"/>'
                       f'<rect x="-8" y="6" width="16" height="12" rx="3" fill="{c}"/><rect x="-5" y="8.5" width="10" height="5" rx="1.5" fill="#A9E0FF"/></g>'
                       for f, c in ((0.3, "#FF5E5B"), (0.68, "#FFD23F"))))
    return peaks + cable + tree(bx - 60, by + 6, 10, "#4DB860", "pine") + tree(bx + 78, by + 6, 9, "#58C46B", "pine")


def beach(isl):
    """The beach island (河邊海邊): sand, a palm, a parasol and a little pool."""
    bx, by = isl.base
    return (f'<ellipse cx="{bx + 34}" cy="{by - 6}" rx="40" ry="11" fill="#7CCFFF" stroke="#43A9E0" stroke-width="1.4"/>'
            f'<path d="M{bx + 18} {by - 8} q 6 -3 12 0 M{bx + 40} {by - 4} q 6 -3 12 0" stroke="#D8F3FF" stroke-width="2" fill="none" stroke-linecap="round"/>'
            + tree(bx - 52, by + 2, 15, "#3FB37A", "palm")
            + f'<path d="M{bx - 10} {by - 4} V {by - 44}" stroke="#8A6A4A" stroke-width="2.4"/>'
            f'<path d="M{bx - 36} {by - 40} Q {bx - 10} {by - 66} {bx + 16} {by - 40} Z" fill="#FF5E5B"/>'
            f'<path d="M{bx - 27} {by - 40} Q {bx - 22} {by - 58} {bx - 10} {by - 59} Q {bx - 2} {by - 58} {bx + 7} {by - 40} Z" fill="#FFFFFF"/>'
            f'<path d="M{bx - 18} {by - 40} Q {bx - 14} {by - 56} {bx - 10} {by - 59} Q {bx - 6} {by - 56} {bx - 2} {by - 40} Z" fill="#FF5E5B"/>'
            f'<rect x="{bx + 64}" y="{by - 12}" width="14" height="10" rx="2" fill="#FFD23F"/><path d="M{bx + 66} {by - 12} q 5 -8 10 0" stroke="#FF8A3D" stroke-width="2" fill="none"/>')


def ghost(isl):
    """What will be built, drawn faintly, and a wooden sign: an island
    nobody has sent a postcard to yet."""
    bx, by = isl.base
    sign = (f'<g transform="translate({bx + isl.rx * 0.55:.1f} {by - 2:.1f})"><rect x="-2" y="-24" width="4" height="24" fill="#8A6A4A"/>'
            '<rect x="-15" y="-36" width="30" height="16" rx="3" fill="#E8C79A" stroke="#B9935E" stroke-width="1.4"/>'
            '<path d="M-8 -28 h16" stroke="#B9935E" stroke-width="2" stroke-linecap="round"/></g>')
    return f'<g opacity=".22">{building(isl)}</g>' + sign


def decor(isl):
    """Little things on the islands that have room: trees and flowers."""
    cx, cy, rx, ry = isl.cx, isl.cy, isl.rx, isl.ry
    if isl.ground in ("snow", "moon", "candy", "sand") or isl.name in ("city", "mountain"):
        return ""
    s = []
    if isl.name == "home":
        s.append(tree(cx - rx * 0.78, cy + ry * 0.35, 12) + tree(cx + rx * 0.8, cy + ry * 0.2, 11, "#58C46B"))
        s.append(flower_patch(cx - rx * 0.45, cy + ry * 0.75) + flower_patch(cx + rx * 0.5, cy + ry * 0.8, ("#FFFFFF", "#FF8FB1", "#FFD166")))
    else:
        s.append(flower_patch(cx - rx * 0.72, cy + ry * 0.6))
    return "".join(s)


def island_svg(isl, built=True, seed=0):
    """One island's picture, in world coordinates cut to its box."""
    x, y, w, h = isl.box
    content = island_base(isl, seed) + (building(isl) if built else ghost(isl)) + (decor(isl) if built else "")
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{x} {y} {w} {h}">'
            f'{town.DEFS}{content}</svg>')


# ---------------------------------------------------------------- the sky, the sea, the bridges

def sky(phase="day"):
    """Top to bottom: deep sky with stars round the space island, light
    sky, clouds, and the sea at the bottom."""
    stops = {
        "day": [(0, "#5DAEF5"), (0.45, "#9BD6FF"), (0.9, "#D8F1FF")],
        "dusk": [(0, "#5E5AA8"), (0.4, "#9C8AD6"), (0.75, "#FF9F8A"), (0.92, "#FFD9A3")],
        "night": [(0, "#141E4A"), (0.6, "#2A3A78"), (0.92, "#4A5FA6")],
    }[phase]
    sea = {"day": ("#4DB6F0", "#8ED8FF"), "dusk": ("#5F7FC4", "#E6A58F"), "night": ("#27508F", "#3D6CB0")}[phase]
    s = ['<defs><linearGradient id="isky" x1="0" y1="0" x2="0" y2="1">'
         + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient>'
         f'<linearGradient id="isea" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{sea[1]}"/><stop offset="1" stop-color="{sea[0]}"/></linearGradient></defs>',
         f'<rect width="{W}" height="{H}" fill="url(#isky)"/>']
    # Stars: high up always (space is up there), everywhere at night.
    n = 90 if phase == "night" else 22
    for i in range(n):
        x = (i * 137.5) % W
        y = 10 + (i * 71.3) % (1300 if phase == "night" else 330)
        r = 1.1 + (i % 3) * 0.6
        op = (0.55 + (i % 4) * 0.12) * (1 if phase == "night" else 0.5)
        s.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="#FFF3C2" opacity="{op:.2f}"/>')
    if phase == "day":
        s.append('<g transform="translate(560 120)"><circle r="40" fill="#FFE27A" opacity=".35"/><circle r="26" fill="#FFD23F"/></g>')
    elif phase == "dusk":
        s.append('<g transform="translate(560 140)"><circle r="54" fill="#FFB47A" opacity=".45"/><circle r="32" fill="#FF8A4C"/></g>')
    else:
        s.append('<g transform="translate(560 120)"><circle r="46" fill="#FFF3C2" opacity=".12"/><circle r="32" fill="#FFF3C2" opacity=".16"/>'
                 '<circle r="23" fill="#FFF3C2"/><circle cx="10" cy="-8" r="19" fill="#17204A"/></g>')
    clouds = "".join(cloud(x, y, sc, op) for x, y, sc, op in CLOUDS)
    s.append(f'<g opacity="{0.45 if phase == "night" else 1}">{town.tint(clouds, phase)}</g>')
    # The sea, with gentle waves.
    s.append(f'<rect y="{SEA}" width="{W}" height="{H - SEA}" fill="url(#isea)"/>')
    s.append(f'<path d="M0 {SEA} H {W}" stroke="#FFFFFF" stroke-width="3" opacity=".6"/>')
    for row, y in enumerate(range(SEA + 24, H, 30)):
        for x in range(-20 + (row % 2) * 40, W, 80):
            s.append(f'<path d="M{x} {y} q 10 -6 20 0 t 20 0" stroke="#FFFFFF" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".55"/>')
    return "".join(s)


# Rope bridges between neighbours (from, to); the rainbow joins the candy island.
BRIDGES = [
    ("home", "mountain"), ("home", "city"), ("home", "dinoPark"), ("home", "transport"), ("home", "zoo"), ("home", "food"),
    ("mountain", "space"), ("city", "polar"), ("zoo", "school"), ("zoo", "insects"), ("food", "insects"), ("food", "temple"),
    ("insects", "grandma"), ("school", "botanical"), ("temple", "park"), ("botanical", "aquarium"), ("grandma", "water"), ("park", "travel"),
]
RAINBOWS = [("mountain", "candy"), ("candy", "city")]
RAIL = ("transport", "home")  # a rail bridge: the little train goes across and back


def _curve(a, b, sag):
    """Points along a sagging bridge from a to b."""
    mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2 + sag
    return [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * mx + t * t * b[0], (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * my + t * t * b[1])
            for t in (i / 24 for i in range(25))]


def rail_points():
    """The rail bridge's line, from the transport island to home."""
    A, B = Island(RAIL[0]), Island(RAIL[1])
    a, b = A.rim((B.cx, B.cy)), B.rim((A.cx, A.cy))
    return _curve(a, b, 8)


def rail(pts):
    """A rail bridge: a deck, two rails and its sleepers."""
    d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
    return (f'<path d="{d}" stroke="#7E8A99" stroke-width="13" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="#B8C3D1" stroke-width="9" fill="none" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="#6E5338" stroke-width="7" fill="none" stroke-dasharray="3 6"/>'
            + "".join(f'<path d="M{" L".join(f"{x:.1f} {y + dy:.1f}" for x, y in pts)}" stroke="#5D6470" stroke-width="1.4" fill="none"/>' for dy in (-2.5, 2.5)))


def ladder(a, b):
    """A rope ladder hanging from one island down to the one below."""
    s = []
    for dx in (-9, 9):
        s.append(f'<path d="M{a[0] + dx:.1f} {a[1]:.1f} Q {(a[0] + b[0]) / 2 + dx + 6:.1f} {(a[1] + b[1]) / 2:.1f} {b[0] + dx:.1f} {b[1]:.1f}" stroke="#8A5A36" stroke-width="2.6" fill="none"/>')
    steps = int(abs(b[1] - a[1]) / 16)
    for i in range(1, steps):
        t = i / steps
        x = (1 - t) ** 2 * a[0] + 2 * (1 - t) * t * ((a[0] + b[0]) / 2 + 6) + t * t * b[0]
        y = a[1] + (b[1] - a[1]) * t
        s.append(f'<path d="M{x - 9:.1f} {y:.1f} H {x + 9:.1f}" stroke="#D9A574" stroke-width="4" stroke-linecap="round"/>')
    return "".join(s)


def bridges():
    s = []
    for f, t in BRIDGES:
        A, B = Island(f), Island(t)
        a, b = A.rim((B.cx, B.cy)), B.rim((A.cx, A.cy))
        length = math.dist(a, b)
        if abs(b[1] - a[1]) > 2.2 * abs(b[0] - a[0]):
            s.append(ladder(a, b))
            continue
        pts = _curve(a, b, 10 + length * 0.07)
        d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
        if {f, t} == set(RAIL):
            s.append(rail(rail_points()))
            continue
        rope = "M" + " L".join(f"{x:.1f} {y - 12:.1f}" for x, y in _curve((a[0], a[1] + 2), (b[0], b[1] + 2), 4 + length * 0.05))
        s.append(f'<path d="{d}" stroke="#8A5A36" stroke-width="12" fill="none" stroke-linecap="round"/>')
        s.append(f'<path d="{d}" stroke="#D9A574" stroke-width="8.5" fill="none" stroke-linecap="round" stroke-dasharray="7 3"/>')
        s.append(f'<path d="{rope}" stroke="#8A5A36" stroke-width="2" fill="none"/>')
        for i in range(2, 23, 4):
            (x, y), (rx_, ry_) = pts[i], _curve((a[0], a[1] + 2), (b[0], b[1] + 2), 4 + length * 0.05)[i]
            s.append(f'<path d="M{x:.1f} {y - 3:.1f} L {rx_:.1f} {ry_ - 12:.1f}" stroke="#8A5A36" stroke-width="1.4"/>')
    for f, t in RAINBOWS:
        A, B = Island(f), Island(t)
        a, b = A.rim((B.cx, B.cy)), B.rim((A.cx, A.cy))
        for k, c in enumerate(["#FF6B6B", "#FFB347", "#FFE066", "#7BD389", "#6FC3FF", "#B79CFF"]):
            off = (k - 2.5) * 4.5
            pts = _curve((a[0], a[1] + off), (b[0], b[1] + off), -46)
            s.append(f'<path d="M{" L".join(f"{x:.1f} {y:.1f}" for x, y in pts)}" stroke="{c}" stroke-width="5" fill="none" stroke-linecap="round"/>')
    return "".join(s)


# ---------------------------------------------------------------- toys (things to poke)


def train():
    """A little two-car train, facing left (toward home)."""
    cars = []
    for k, x in enumerate((0, 36)):
        cars.append(f'<rect x="{x}" y="0" width="34" height="16" rx="{6 if k == 0 else 4}" fill="#F3F6FA" stroke="#7FA7C9" stroke-width="1.2"/>'
                    f'<rect x="{x + 4}" y="3" width="9" height="6" rx="1.5" fill="#A9E0FF"/><rect x="{x + 16}" y="3" width="9" height="6" rx="1.5" fill="#A9E0FF"/>'
                    f'<rect x="{x}" y="11" width="34" height="2.4" fill="#4DA3FF"/>')
    return f'<g>{"".join(cars)}<circle cx="3" cy="13" r="1.6" fill="#FFD23F"/></g>'


def sailboat():
    return ('<g><path d="M2 22 H 52 Q 48 32 40 32 H 12 Q 6 32 2 22 Z" fill="#FF8A3D" stroke="#C9692A" stroke-width="1.4"/>'
            '<path d="M26 22 V 0" stroke="#8A6A4A" stroke-width="2"/><path d="M28 2 L 48 20 H 28 Z" fill="#FFFFFF" stroke="#C5CFDC" stroke-width="1.2"/>'
            '<path d="M24 6 L 8 20 H 24 Z" fill="#FFD23F" stroke="#E0A21C" stroke-width="1.2"/></g>')


def hot_air_balloon():
    return ('<g><path d="M22 0 C 40 0, 46 22, 30 38 L 14 38 C -2 22, 4 0, 22 0 Z" fill="#FF8FB1" stroke="#E0668C" stroke-width="1.4"/>'
            '<path d="M22 0 C 30 6, 30 30, 26 38 L 18 38 C 14 30, 14 6, 22 0 Z" fill="#FFD84D"/>'
            '<path d="M15 38 L 17 46 M29 38 L 27 46" stroke="#8A6A4A" stroke-width="1.2"/>'
            '<rect x="15" y="46" width="14" height="10" rx="2" fill="#C98B5E" stroke="#8A5A36" stroke-width="1.2"/></g>')


def _toys():
    """name -> (kind, island it is on, art box, tap box, picture or None)."""
    park, beachi = Island("park"), Island("water")
    px, py = park.base
    t = {
        "train": ("train", None, None, None, train),
        "duckPark": ("duck", "park", (px + 14, py - 22, 32, 20), (px + 13, py - 31, 34, 32), lambda: duck(px + 30, py - 8)),
        "duckPark2": ("duck", "park", (px + 40, py - 14, 32, 20), (px + 39, py - 23, 34, 32), lambda: duck(px + 56, py, flip=True)),
        "duckSea": ("duck", None, (490, 1704, 32, 20), (489, 1695, 34, 32), lambda: duck(506, 1718)),
        "boat": ("boat", None, (560, 1690, 54, 34), (556, 1686, 62, 42), sailboat),
        "balloon": ("balloon", None, (468, 586, 44, 56), (462, 580, 56, 68), hot_air_balloon),
    }
    city = Island("city")
    cbx, cby = city.base
    t["tower"] = ("tower", "city", None, (cbx - 4, cby - 190, 50, 186), None)
    for i, (x, y, sc, _) in enumerate(CLOUDS):
        if i in POKEABLE_CLOUDS:
            t[f"cloud{i}"] = ("cloud", None, None, (x + 2 * sc, y + 8 * sc, 76 * sc, 33 * sc), None)
    return t


# The sky's clouds: x, y, scale, opacity; some can be poked to rain.
CLOUDS = [(40, 390, 0.9, 0.95), (640, 400, 0.8, 0.9), (300, 600, 0.7, 0.85), (520, 830, 0.85, 0.9), (20, 1040, 0.8, 0.9),
          (700, 1060, 0.7, 0.85), (260, 1290, 0.75, 0.9), (560, 1300, 0.7, 0.85), (40, 1540, 0.8, 0.9), (690, 1550, 0.7, 0.85)]
POKEABLE_CLOUDS = {0, 2, 3, 6, 7}


def train_box():
    """Where the train's picture stands (its bottom middle) on the rail, at the transport end."""
    x, y = rail_points()[3]
    return (x - 35, y - 18, 70, 16)


def tower_top(city):
    bx, by = city.base
    return (bx + 4 + 22 * 0.78, by - 4 - 232 * 0.78)


# ---------------------------------------------------------------- festivals

def _hanging(a, b, item, n):
    """A string sagging from a to b with [item](x, y, i) hanging from it."""
    s = [f'<path d="M{a[0]:.1f} {a[1]:.1f} Q{(a[0] + b[0]) / 2:.1f} {(a[1] + b[1]) / 2 + 16:.1f} {b[0]:.1f} {b[1]:.1f}" stroke="#8A6A4A" stroke-width="1.2" fill="none"/>']
    for k in range(n):
        t = (k + 1) / (n + 1)
        x = (1 - t) ** 2 * a[0] + 2 * (1 - t) * t * (a[0] + b[0]) / 2 + t * t * b[0]
        y = (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * ((a[1] + b[1]) / 2 + 16) + t * t * b[1]
        s.append(item(round(x, 1), round(y, 1), k))
    return "".join(s)


def _under_bridges(item, n=3):
    """[item]s hanging under the bridges round home."""
    out = []
    for f, t in [("home", "dinoPark"), ("home", "transport"), ("home", "school"), ("home", "temple"), ("temple", "park"), ("school", "park")]:
        A, B = Island(f), Island(t)
        a, b = A.rim((B.cx, B.cy)), B.rim((A.cx, A.cy))
        out.append(_hanging((a[0], a[1] + 14), (b[0], b[1] + 14), item, n))
    return "".join(out)


def _on_home(dx, dy):
    """A point on the home island's top, [dx] and [dy] from its middle (as fractions)."""
    home = Island("home")
    return home.cx + home.rx * dx, home.cy + home.ry * dy


def island_festival(name):
    L, G = town.LANTERN, town.LANTERN_GOLD
    if name == "lunarNewYear":
        x, y = _on_home(-0.5, 0.55)
        return _under_bridges(lambda x, y, i: festivals.lantern(x, y)) + festivals.lion(x, y)
    if name == "lantern":
        rising = [(300, 330, 1.0), (470, 300, 0.8), (90, 560, 0.9), (690, 580, 1.0), (300, 840, 0.8), (480, 1060, 0.9), (120, 1300, 0.8), (640, 1270, 1.0)]
        colors = [(L, G), (G, L), ("#FF8FB1", G)]
        return "".join(festivals.sky_lantern(x, y, s) for x, y, s in rising) + _under_bridges(lambda x, y, i: festivals.lantern(x, y, 7, *colors[i % 3]))
    if name == "childrensDay":
        floating = [(300, 360, 0), (480, 330, 3), (90, 580, 1), (700, 600, 4), (300, 860, 5), (470, 1080, 2), (130, 1320, 3), (640, 1300, 0)]
        x, y = _on_home(0.55, 0.3)
        return (_under_bridges(lambda x, y, i: festivals.pennant(x, y, festivals.RAINBOW[i % 6]), 4)
                + "".join(festivals.balloon(x, y, festivals.RAINBOW[c]) for x, y, c in floating)
                + festivals.balloon(x, y - 40, festivals.RAINBOW[3], 0.8) + festivals.balloon(x + 12, y - 46, festivals.RAINBOW[0], 0.8))
    if name == "dragonBoat":
        return (festivals.dragon_boat(240, 1720, "#3FB37A") + festivals.dragon_boat(560, 1740, "#FF8A3D", flip=True)
                + festivals.dragon_boat(90, 1745, "#4DA8FF") + _under_bridges(lambda x, y, i: festivals.zongzi(x, y, 0.9), 2))
    if name == "midAutumn":
        if town.PHASE == "night":
            moon = (f'<g transform="translate(560 120)"><circle r="60" fill="{town.MOON}" opacity=".12"/><circle r="46" fill="{town.MOON}" opacity=".18"/>'
                    f'<circle r="34" fill="{town.MOON}"/>' + festivals.rabbit(6, 6, "#E9D9A0") + '</g>')
        else:
            moon = '<g transform="translate(90 120)"><circle r="18" fill="#FFFFFF" opacity=".75"/></g>'
        x, y = _on_home(0.5, 0.6)
        pomelos = (f'<g transform="translate({x:.1f} {y:.1f})"><circle cx="0" cy="0" r="8" fill="#B5D86A" stroke="#7FA83A" stroke-width="1.2"/>'
                   '<path d="M0 -8 l2 -4 l4 1" stroke="#3A9A4C" stroke-width="1.4" fill="none"/><circle cx="13" cy="3" r="7" fill="#C7E07A" stroke="#7FA83A" stroke-width="1.2"/></g>')
        rx, ry = _on_home(-0.55, 0.6)
        return moon + pomelos + f'<g transform="translate({rx:.1f} {ry:.1f})">' + festivals.rabbit(0, 0, "#FFFFFF", 1.2) + '</g>'
    if name == "christmas":
        x, y = _on_home(0.62, 0.55)
        tree_ = re.sub(r'translate\(160 432\)', f'translate({x:.1f} {y:.1f})', festivals.christmas().split('<path d="M41 374')[0])
        tree_ = tree_.replace('<g transform="translate(195 0)">', '', 1)
        bulbs = _under_bridges(lambda x, y, i: town.glow(x, y + 3, 5, [L, G, town.BULB_GREEN, town.BULB_BLUE][i % 4])
                               + f'<circle cx="{x}" cy="{y + 3}" r="2.4" fill="{[L, G, town.BULB_GREEN, town.BULB_BLUE][i % 4]}"/>', 5)
        return tree_ + bulbs
    if name == "newYearsEve":
        colors = [G, "#FFFFFF", "#FF8FB1", "#8C6CFF"]
        return _under_bridges(lambda x, y, i: festivals.pennant(x, y, colors[i % 4]), 4)
    raise KeyError(name)


# ---------------------------------------------------------------- export

def export(app_dir=APP):
    out = pathlib.Path(app_dir) / "assets" / "art" / "islands"
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.svg"):
        old.unlink()
    toys = _toys()
    for phase in town.PHASES:
        town.PHASE = phase
        (out / f"sky_{phase}.svg").write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{sky(phase)}</svg>')
        (out / f"bridges_{phase}.svg").write_text(town.tint(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{bridges()}</svg>', phase))
        for i, name in enumerate(ISLANDS):
            isl = Island(name)
            (out / f"island_{name}_{phase}.svg").write_text(town.tint(island_svg(isl, True, seed=i), phase))
            if name in GROWS:
                (out / f"island_{name}_lot_{phase}.svg").write_text(town.tint(island_svg(isl, False, seed=i), phase))
        for name, (kind, on, art, tap, draw) in toys.items():
            if draw is None:
                continue
            x, y, w, h = train_box() if name == "train" else art
            body = draw() if name != "train" else f'<g transform="translate({x} {y})">{train()}</g>'
            (out / f"toy_{name}_{phase}.svg").write_text(town.tint(
                f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{x} {y} {w} {h}">{body}</svg>' if name != "boat" and name != "balloon"
                else f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{body}</svg>', phase))
        for name in festivals.DECOR:
            (out / f"festival_{name}_{phase}.svg").write_text(town.tint(
                f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{town.DEFS}{island_festival(name)}</svg>', phase))
    town.PHASE = "day"
    write_dart(app_dir, toys)
    print(f"{len(list(out.glob('*.svg')))} pictures in {out}")


def _r(r):
    return "Rect.fromLTWH(" + ", ".join(f"{round(v, 1):g}" for v in r) + ")"


def _o(p):
    return f"Offset({round(p[0], 1):g}, {round(p[1], 1):g})"


def write_dart(app_dir, toys):
    enter = {"city": "shop", "home": None, "school": None, "park": None, "temple": None, "travel": None, "mountain": None, "water": None}
    lines = ["// Generated by docs/design/v6/islands.py; do not edit.", "", "import 'dart:ui';", "",
             f"const islandWorld = Size({W}, {H});", "", "/// Left edge of the column a phone shows first.",
             f"const islandColumnLeft = {OX}.0;", "",
             "/// Every island, back to front: its picture's box (`island_<name>_<phase>.svg`), where a tap",
             "/// counts (its top and building), the place you go into from it (null: its postcards), where",
             "/// the child's own pictures hop, and whether it is bare until a postcard arrives",
             "/// (`island_<name>_lot_<phase>.svg`).",
             "const islands = <String, ({Rect box, Rect tap, String? enter, List<Offset> folks, bool grows})>{"]
    for name in sorted(ISLANDS, key=lambda n: ISLANDS[n][1]):
        isl = Island(name)
        tap = (isl.cx - isl.rx, isl.top, 2 * isl.rx, isl.cy + isl.ry + isl.side - isl.top)
        go = enter.get(name, name)
        folks = [(isl.cx - isl.rx * 0.62, isl.cy + isl.ry * 0.45), (isl.cx + isl.rx * 0.62, isl.cy + isl.ry * 0.5)]
        lines.append(f"  '{name}': (box: {_r(isl.box)}, tap: {_r(tap)}, enter: {f"'{go}'" if go else 'null'}, "
                     f"folks: [{', '.join(_o(p) for p in folks)}], grows: {'true' if name in GROWS else 'false'}),")
    lines += ["};", "", "/// Where each kind of place's postcards are pinned, and on which island.",
              "const islandPins = <String, ({String island, Offset pin})>{"]
    for name in ISLANDS:
        isl = Island(name)
        bx, by = isl.base
        kinds = PLACES_ON.get(name, (name,))
        for kind in kinds:
            if name == "city":
                pin = (bx - 40, by - 76) if kind == "shop" else (bx + 58, by - 50)
            else:
                pin = (bx, max(isl.top + 14, by - isl.bh * 0.8))
            lines.append(f"  '{kind}': (island: '{name}', pin: {_o(pin)}),")
    home = Island("home")
    lines += ["};", "",
              "/// On the home island: where the child's animal walks, and where Gugu sleeps at night.",
              f"const islandWalker = {_o((home.cx + home.rx * 0.42, home.cy + home.ry * 0.62))};",
              f"const islandPerch = {_o((home.cx - home.rx * 0.6, home.cy + home.ry * 0.25))};", "",
              "/// The tip of Taipei 101 on the city island, where its fireworks go up.",
              f"const islandTowerTop = {_o(tower_top(Island('city')))};", "",
              "/// Festivals with a decoration layer (`festival_<name>_<phase>.svg`).",
              "const islandFestivalLayers = {" + ", ".join(f"'{k}'" for k in festivals.DECOR) + "};", "",
              "/// Things to poke: what they are, the island they stand on (they float with it),",
              "/// their picture's box (`toy_<name>_<phase>.svg`), where a tap counts. The train runs",
              "/// along [islandRail] and back; 101 and the clouds have no picture of their own.",
              "const islandToys = <String, ({String kind, String? on, Rect? art, Rect tap})>{"]
    for name, (kind, on, art, tap, draw) in toys.items():
        if name == "train":
            art = train_box()
            tap = (art[0] - 4, art[1] - 10, art[2] + 8, art[3] + 16)
        lines.append(f"  '{name}': (kind: '{kind}', on: {f"'{on}'" if on else 'null'}, art: {_r(art) if art else 'null'}, tap: {_r(tap)}),")
    pts = rail_points()
    lines += ["};", "", "/// The rail bridge the train runs along, from the transport island to home.",
              "const islandRail = [" + ", ".join(_o(p) for p in pts[3:-3]) + "];", ""]
    dart = pathlib.Path(app_dir) / "lib" / "features" / "town" / "island_layout_data.dart"
    dart.write_text("\n".join(lines))


# ---------------------------------------------------------------- previews

def world(phase="day", built=None, festival=None):
    """The whole world at [phase], stacked as the app stacks it."""
    town.PHASE = phase
    parts = [sky(phase), town.tint(bridges(), phase)]
    toys = _toys()
    for name in sorted(ISLANDS, key=lambda n: ISLANDS[n][1]):
        isl = Island(name)
        shown = built is None or name not in GROWS or name in built
        body = island_svg(isl, shown, seed=list(ISLANDS).index(name))
        inner = re.sub(r"^<svg[^>]*>|</svg>$", "", body)
        parts.append(town.tint(inner, phase))
    for name, (kind, on, art, tap, draw) in toys.items():
        if draw is None:
            continue
        if name == "train":
            x, y, w, h = train_box()
            parts.append(town.tint(f'<g transform="translate({x} {y})">{train()}</g>', phase))
        elif name in ("boat", "balloon"):
            parts.append(town.tint(f'<g transform="translate({art[0]} {art[1]})">{draw()}</g>', phase))
        else:
            parts.append(town.tint(draw(), phase))
    if festival:
        parts.append(town.tint(town.DEFS + island_festival(festival), phase))
    town.PHASE = "day"
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(parts)}</svg>'


def render(svg_text, out, w=W, h=H):
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg_text)
    subprocess.run(["node", str(HERE / "render_alpha.js"), f.name, str(out), str(w), str(h)], check=True)


if __name__ == "__main__":
    if sys.argv[1:] == ["export"]:
        export()
    elif sys.argv[1:2] == ["preview"]:
        out = pathlib.Path(sys.argv[2])
        phase = sys.argv[3] if len(sys.argv) > 3 else "day"
        fest = sys.argv[4] if len(sys.argv) > 4 else None
        render(world(phase, festival=fest), out)
