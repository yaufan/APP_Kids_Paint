"""Taiwan's festivals in the town: decorations, icons and coloring pages.

The app shows a festival's decoration layer on the dates in
app/lib/core/festivals.dart, and Gugu brings that festival's coloring page.
Decorations are drawn in world coordinates (see town.py) and stay off the
buildings, so they look right however much of the town is built.
"""
import math

import town
from town import BULB_BLUE, BULB_GREEN, LANTERN, LANTERN_GOLD, MOON, OX, W, glow

# ---------------------------------------------------------------- pieces


def lantern(x, y, r=7, body=LANTERN, trim=LANTERN_GOLD):
    """A round paper lantern hanging from (x, y)."""
    top = y + 4
    return (glow(x, top + r + 1, r * 2.2, trim)
            + f'<path d="M{x} {y} V{top}" stroke="#8A6A4A" stroke-width="1.2"/>'
            f'<rect x="{x - r * 0.55:.1f}" y="{top}" width="{r * 1.1:.1f}" height="3" rx="1" fill="{trim}"/>'
            f'<ellipse cx="{x}" cy="{top + r + 2}" rx="{r}" ry="{r * 1.05:.1f}" fill="{body}"/>'
            f'<path d="M{x} {top + 3} V{top + 2 * r + 1} M{x - r * 0.5:.1f} {top + 4} Q{x - r * 0.75:.1f} {top + r + 2} {x - r * 0.5:.1f} {top + 2 * r}'
            f' M{x + r * 0.5:.1f} {top + 4} Q{x + r * 0.75:.1f} {top + r + 2} {x + r * 0.5:.1f} {top + 2 * r}" stroke="{trim}" stroke-width="1" fill="none" opacity=".8"/>'
            f'<rect x="{x - r * 0.55:.1f}" y="{top + 2 * r + 1}" width="{r * 1.1:.1f}" height="3" rx="1" fill="{trim}"/>'
            f'<path d="M{x} {top + 2 * r + 4} v6" stroke="{trim}" stroke-width="2" stroke-linecap="round"/>')


def sky_lantern(x, y, s=1.0):
    """A Pingxi sky lantern rising, wider at the top."""
    return (glow(x, y, 20 * s, LANTERN_GOLD)
            + f'<g transform="translate({x} {y}) scale({s})">'
            f'<path d="M-9 -13 H9 L7 9 H-7 Z" fill="{LANTERN_GOLD}"/>'
            '<path d="M-9 -13 H9 L8.2 -9 H-8.2 Z" fill="#FFFFFF" opacity=".5"/>'
            '<path d="M-3 -13 L-2 9 M3 -13 L2 9" stroke="#FFFFFF" stroke-width="1" opacity=".55"/>'
            f'<ellipse cx="0" cy="5" rx="4" ry="3" fill="{LANTERN}" opacity=".7"/></g>')


def balloon(x, y, color, s=1.0):
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M0 13 C -3 20, 3 24, 0 32" stroke="#9FB3C8" stroke-width="1.2" fill="none"/>'
            f'<ellipse cx="0" cy="0" rx="9" ry="11" fill="{color}"/>'
            f'<path d="M-2 11 L2 11 L0 14 Z" fill="{color}"/>'
            '<ellipse cx="-3" cy="-4" rx="2.2" ry="3.4" fill="#FFFFFF" opacity=".6"/></g>')


def zongzi(x, y, s=1.0):
    """Rice dumplings tied together, hanging from (x, y)."""
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M0 0 V5" stroke="#8A6A4A" stroke-width="1.2"/>'
            '<path d="M0 5 L9 20 H-9 Z" fill="#5FBF72" stroke="#3A9A4C" stroke-width="1.2" stroke-linejoin="round"/>'
            '<path d="M-5 13 H5" stroke="#E8C79A" stroke-width="2"/>'
            '<path d="M0 5 L3 20" stroke="#3A9A4C" stroke-width="1"/></g>')


def pennant(x, y, color):
    return f'<path d="M{x - 6} {y} H{x + 6} L{x} {y + 12} Z" fill="{color}"/>'


RAINBOW = ["#FF5E5B", "#FFC94A", "#5FCB79", "#4DA8FF", "#8C6CFF", "#FF8FB1"]
PILLARS = list(range(14, W, 64))
# Where hanging things would cover a building: home, and the school's clock tower.
BUSY = [(226, 322), (456, 510)]


def under_viaduct(item, per_gap=2):
    """A string sagging between the MRT pillars with [item](x, y, i) hanging from it."""
    s, i = [], 0
    for a, b in zip(PILLARS, PILLARS[1:]):
        a, b = a + 9, b
        s.append(f'<path d="M{a} 333 Q{(a + b) / 2} 345 {b} 333" stroke="#8A6A4A" stroke-width="1.2" fill="none"/>')
        for k in range(per_gap):
            t = (k + 1) / (per_gap + 1)
            x = a + (b - a) * t
            if any(lo <= x <= hi for lo, hi in BUSY):
                continue
            y = 333 + 24 * t * (1 - t)  # on the sagging string
            s.append(item(round(x, 1), round(y, 1), i))
            i += 1
    return "".join(s)


def mid(*parts):
    return town.mid(*parts)


# ---------------------------------------------------------------- decorations


def lunar_new_year():
    """過年: red lanterns under the MRT, spring couplets and 福 on home, a lion dance."""
    door = ('<rect x="62" y="393" width="5" height="24" rx="1" fill="#E0503A"/><rect x="88" y="393" width="5" height="24" rx="1" fill="#E0503A"/>'
            '<g transform="translate(77.5 383) rotate(45)"><rect x="-5.5" y="-5.5" width="11" height="11" fill="#E0503A"/></g>'
            '<circle cx="77.5" cy="383" r="3.2" fill="#FFD23F"/><rect x="76.3" y="381.8" width="2.4" height="2.4" fill="#E0503A"/>')
    return (under_viaduct(lambda x, y, i: lantern(x, y))
            + mid(door, lion(160, 456)))


def lion(x, y):
    """A small lion dance on the avenue."""
    return (f'<g transform="translate({x} {y})">'
            '<ellipse cx="2" cy="1" rx="22" ry="3.5" fill="rgba(30,60,40,.18)"/>'
            '<path d="M-20 -2 Q-18 -16 -4 -16 H6 V-2 Z" fill="#FFC94A" stroke="#E0A21C" stroke-width="1.2"/>'
            '<path d="M-20 -6 Q-10 -10 0 -6" stroke="#FF5E5B" stroke-width="2.4" fill="none"/>'
            '<path d="M-18 -2 v3 M-8 -2 v3 M2 -2 v3" stroke="#3A3F4B" stroke-width="2.4" stroke-linecap="round"/>'
            '<circle cx="12" cy="-12" r="11" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.4"/>'
            '<path d="M3 -20 Q12 -28 21 -20" stroke="#FFC94A" stroke-width="3" fill="none" stroke-linecap="round"/>'
            '<circle cx="9" cy="-14" r="3.4" fill="#FFFFFF"/><circle cx="16" cy="-14" r="3.4" fill="#FFFFFF"/>'
            '<circle cx="9.5" cy="-13.5" r="1.6" fill="#2A211D"/><circle cx="16.5" cy="-13.5" r="1.6" fill="#2A211D"/>'
            '<path d="M6 -6 Q12.5 -2 19 -6" stroke="#FFFFFF" stroke-width="2" fill="none" stroke-linecap="round"/>'
            '<circle cx="12" cy="-24" r="2.6" fill="#FFFFFF"/></g>')


def lantern_festival():
    """元宵節: sky lanterns over the mountains and colored lanterns under the MRT."""
    rising = [(OX + 40, 150, 1.0), (OX + 120, 96, 0.8), (OX + 230, 128, 1.1), (OX + 262, 54, 0.7),
              (OX + 370, 150, 0.9), (70, 120, 0.9), (150, 60, 0.7), (640, 120, 1.0), (730, 70, 0.8)]
    colors = [(LANTERN, LANTERN_GOLD), (LANTERN_GOLD, LANTERN), ("#FF8FB1", LANTERN_GOLD)]
    return ("".join(sky_lantern(x, y, s) for x, y, s in rising)
            + under_viaduct(lambda x, y, i: lantern(x, y, 7, *colors[i % 3])))


def childrens_day():
    """兒童節: bunting under the MRT and balloons floating up."""
    floating = [(OX + 60, 120, 0), (OX + 150, 70, 3), (OX + 250, 150, 1), (OX + 350, 100, 4),
                (60, 90, 5), (700, 120, 2), (620, 60, 3)]
    return (under_viaduct(lambda x, y, i: pennant(x, y, RAINBOW[i % len(RAINBOW)]), per_gap=3)
            + "".join(balloon(x, y, RAINBOW[c]) for x, y, c in floating)
            + mid(balloon(118, 360, RAINBOW[3], 0.8), balloon(130, 354, RAINBOW[0], 0.8), balloon(124, 344, RAINBOW[1], 0.8)))


def dragon_boat(x, y, color, flip=False):
    """A dragon boat with its rowers and drum."""
    t = f"translate({x} {y})" + (" scale(-1 1)" if flip else "")
    rowers = "".join(f'<circle cx="{-18 + k * 9}" cy="-9" r="3.2" fill="#FFD2B8" stroke="#C98B5E" stroke-width=".8"/>'
                     f'<path d="M{-18 + k * 9} -6 l-5 9" stroke="#C98B5E" stroke-width="1.6"/>' for k in range(5))
    return (f'<g transform="{t}">'
            '<ellipse cx="0" cy="3" rx="36" ry="3" fill="#FFFFFF" opacity=".5"/>'
            f'{rowers}'
            f'<path d="M-30 -4 H28 Q26 4 18 5 H-24 Q-30 3 -30 -4 Z" fill="{color}" stroke="{town.shade(color, -0.3)}" stroke-width="1.4"/>'
            f'<path d="M-26 -1 H24" stroke="{LANTERN_GOLD}" stroke-width="1.6" stroke-dasharray="3 3"/>'
            # the dragon's head at the front, its tail at the back
            f'<path d="M26 -4 Q30 -16 38 -16 Q44 -15 42 -10 L36 -9 Q34 -4 30 -1 Z" fill="{color}" stroke="{town.shade(color, -0.3)}" stroke-width="1.2"/>'
            '<circle cx="37" cy="-13" r="1.6" fill="#2A211D"/><path d="M33 -16 l-2 -5 M36 -16 l1 -5" stroke="#FFC94A" stroke-width="1.6" stroke-linecap="round"/>'
            f'<path d="M-30 -4 Q-38 -10 -36 -18 Q-32 -10 -26 -6 Z" fill="{color}" stroke="{town.shade(color, -0.3)}" stroke-width="1.2"/>'
            '<circle cx="21" cy="-9" r="4" fill="#FF5E5B" stroke="#C9423F" stroke-width="1"/></g>')


def dragon_boat_festival():
    """端午節: dragon boats racing on the river and rice dumplings under the MRT."""
    return (mid(dragon_boat(122, 258, "#3FB37A"), dragon_boat(236, 276, "#FF8A3D", flip=True))
            + dragon_boat(90, 268, "#4DA8FF") + dragon_boat(690, 262, "#FF5E5B", flip=True)
            + under_viaduct(lambda x, y, i: zongzi(x, y, 0.9)))


def mid_autumn():
    """中秋節: the full moon with its rabbit, and pomelos by home."""
    if town.PHASE == "night":
        moon = (f'<g transform="translate(316 92)"><circle r="54" fill="{MOON}" opacity=".12"/><circle r="40" fill="{MOON}" opacity=".18"/>'
                f'<circle r="30" fill="{MOON}"/>' + rabbit(6, 6, "#E9D9A0") + '</g>')
    else:
        moon = '<g transform="translate(90 64)"><circle r="16" fill="#FFFFFF" opacity=".75"/></g>'
    pomelos = ('<g transform="translate(150 414)">'
               '<circle cx="0" cy="0" r="8" fill="#B5D86A" stroke="#7FA83A" stroke-width="1.2"/><path d="M0 -8 l2 -4 l4 1" stroke="#3A9A4C" stroke-width="1.4" fill="none"/>'
               '<circle cx="13" cy="3" r="7" fill="#C7E07A" stroke="#7FA83A" stroke-width="1.2"/></g>')
    return mid(moon, pomelos, '<g transform="translate(214 168)">' + rabbit(0, 0, "#FFFFFF", 1.2) + '</g>')


def rabbit(x, y, color, s=1.0):
    """A sitting rabbit, as on the moon."""
    ink = "#C9B98A" if color != "#FFFFFF" else "#C9B9C8"
    return (f'<g transform="translate({x} {y}) scale({s})">'
            f'<ellipse cx="0" cy="0" rx="8" ry="7" fill="{color}" stroke="{ink}" stroke-width="1"/>'
            f'<circle cx="6" cy="-7" r="5" fill="{color}" stroke="{ink}" stroke-width="1"/>'
            f'<ellipse cx="4" cy="-16" rx="1.8" ry="5" fill="{color}" stroke="{ink}" stroke-width="1"/>'
            f'<ellipse cx="8.5" cy="-15" rx="1.8" ry="5" fill="{color}" stroke="{ink}" stroke-width="1" transform="rotate(14 8.5 -15)"/>'
            '<circle cx="8" cy="-8" r="1" fill="#2A211D"/></g>')


def christmas():
    """聖誕節: a tree with presents by home, and lights along home's roof."""
    tree_ = ('<g transform="translate(160 432)">'
             '<ellipse cx="0" cy="1" rx="18" ry="3.5" fill="rgba(30,60,40,.18)"/>'
             '<rect x="-3" y="-8" width="6" height="8" fill="#8A6A4A"/>'
             '<path d="M0 -50 L16 -22 H8 L19 -8 H-19 L-8 -22 H-16 Z" fill="#2F9E5A" stroke="#22784A" stroke-width="1.4" stroke-linejoin="round"/>'
             f'<path d="M0 -58 l2.4 5 5.4.6-4 3.6 1.2 5.3L0 -46.6 -4.8 -43.5 -3.6 -48.8 -7.6 -52.4l5.4-.6z" fill="{LANTERN_GOLD}"/>'
             + glow(0, -52, 14, LANTERN_GOLD)
             + "".join(f'<circle cx="{bx}" cy="{by}" r="2.6" fill="{c}"/>' + glow(bx, by, 6, c)
                       for bx, by, c in [(-6, -30, LANTERN), (6, -26, LANTERN_GOLD), (-10, -14, BULB_BLUE), (10, -12, LANTERN), (0, -40, BULB_GREEN)])
             + '<rect x="-24" y="-8" width="10" height="9" rx="1.5" fill="#FF5E5B"/><path d="M-19 -8 v9 M-24 -4 h10" stroke="#FFD23F" stroke-width="1.6"/>'
             '<rect x="13" y="-7" width="11" height="8" rx="1.5" fill="#4DA8FF"/><path d="M18.5 -7 v8 M13 -3 h11" stroke="#FFFFFF" stroke-width="1.6"/></g>')
    # home's gable roof edge: from (41, 374) up to (77, 348) and down to (113, 374)
    bulbs = []
    for k in range(9):
        t = k / 8
        bx = 41 + 72 * t
        by = 374 - 26 * (1 - abs(2 * t - 1))
        c = [LANTERN, LANTERN_GOLD, BULB_GREEN, BULB_BLUE][k % 4]
        bulbs.append(glow(round(bx, 1), round(by, 1), 5, c) + f'<circle cx="{bx:.1f}" cy="{by:.1f}" r="2.2" fill="{c}"/>')
    return mid(tree_, '<path d="M41 374 L77 348 L113 374" stroke="#3A3F4B" stroke-width="1" fill="none" opacity=".6"/>', *bulbs)


def new_years_eve():
    """跨年: gold and silver bunting; the fireworks over 101 are animated in the app."""
    colors = [LANTERN_GOLD, "#FFFFFF", "#FF8FB1", "#8C6CFF"]
    return under_viaduct(lambda x, y, i: pennant(x, y, colors[i % len(colors)]), per_gap=3)


DECOR = {
    "lunarNewYear": lunar_new_year,
    "lantern": lantern_festival,
    "childrensDay": childrens_day,
    "dragonBoat": dragon_boat_festival,
    "midAutumn": mid_autumn,
    "christmas": christmas,
    "newYearsEve": new_years_eve,
}


# ---------------------------------------------------------------- icons (stamps, Gugu's letter)


def icon(name, size=64):
    """A festival's picture, 64 x 64, drawn as in daylight."""
    body = {
        "lunarNewYear": f'<g transform="translate(32 8) scale(2.6)">{lantern(0, -2, 8)}</g>',
        "lantern": f'<g transform="translate(32 34) scale(2.1)">{sky_lantern(0, 0)}</g>',
        "childrensDay": (f'{balloon(20, 24, RAINBOW[0])}{balloon(44, 22, RAINBOW[3])}{balloon(32, 14, RAINBOW[1])}'),
        "dragonBoat": f'<g transform="translate(32 8) scale(2.4)">{zongzi(0, 0)}</g>',
        "midAutumn": (f'<circle cx="32" cy="32" r="26" fill="{LANTERN_GOLD}"/><circle cx="32" cy="32" r="26" fill="{MOON}" opacity=".6"/>'
                      f'<g transform="translate(30 40) scale(1.6)">{rabbit(0, 0, "#FFFFFF")}</g>'),
        "christmas": ('<path d="M32 6 L50 34 H42 L54 52 H10 L22 34 H14 Z" fill="#2F9E5A" stroke="#22784A" stroke-width="2" stroke-linejoin="round"/>'
                      '<rect x="28" y="52" width="8" height="8" fill="#8A6A4A"/>'
                      f'<circle cx="26" cy="30" r="3" fill="{LANTERN}"/><circle cx="38" cy="40" r="3" fill="{LANTERN_GOLD}"/><circle cx="24" cy="46" r="3" fill="{BULB_BLUE}"/>'
                      f'<path d="M32 0 l2.4 5 5.4.6-4 3.6 1.2 5.3L32 11.8 27.2 14.6 28.4 9.3 24.4 5.7l5.4-.6z" fill="{LANTERN_GOLD}" stroke="#E0A21C" stroke-width="1"/>'),
        "newYearsEve": "".join(
            f'<path d="M32 32 L{32 + 24 * math.cos(a):.1f} {32 + 24 * math.sin(a):.1f}" stroke="{c}" stroke-width="4" stroke-linecap="round"/>'
            f'<circle cx="{32 + 27 * math.cos(a):.1f}" cy="{32 + 27 * math.sin(a):.1f}" r="3" fill="{c}"/>'
            for a, c in [(k * math.pi / 4, [LANTERN, LANTERN_GOLD, "#FF8FB1", BULB_BLUE][k % 4]) for k in range(8)]) + f'<circle cx="32" cy="32" r="5" fill="{LANTERN_GOLD}"/>',
    }[name]
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 64 64">{body}</svg>'


# ---------------------------------------------------------------- coloring pages

# Black lines on white, 600 x 800; every area is closed so the bucket fills it.
PAGE_W, PAGE_H = 600, 800
INK = "#222222"


def _page(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" height="{PAGE_H}" viewBox="0 0 {PAGE_W} {PAGE_H}">'
            f'<rect width="{PAGE_W}" height="{PAGE_H}" fill="#FFFFFF"/>'
            f'<g fill="#FFFFFF" stroke="{INK}" stroke-width="9" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>')


def _star(cx, cy, r):
    pts = []
    for k in range(10):
        a = -math.pi / 2 + k * math.pi / 5
        rr = r if k % 2 == 0 else r * 0.45
        pts.append(f"{cx + rr * math.cos(a):.1f},{cy + rr * math.sin(a):.1f}")
    return f'<polygon points="{" ".join(pts)}"/>'


def page_lunar_new_year():
    """A big lantern with a lucky diamond, and two mandarin oranges."""
    return _page(
        '<path d="M300 20 V96"/>'
        '<rect x="230" y="92" width="140" height="36" rx="10"/>'
        '<ellipse cx="300" cy="320" rx="190" ry="196"/>'
        '<path d="M300 126 C 210 200, 210 440, 300 514 M300 126 C 390 200, 390 440, 300 514" fill="none"/>'
        '<rect x="246" y="266" width="108" height="108" transform="rotate(45 300 320)"/>'
        '<rect x="230" y="510" width="140" height="36" rx="10"/>'
        '<path d="M276 546 V610 M300 546 V626 M324 546 V610" fill="none"/>'
        '<circle cx="120" cy="690" r="80"/><path d="M120 610 C 140 576, 190 572, 206 596 C 176 616, 146 620, 120 610 Z"/>'
        '<circle cx="480" cy="690" r="80"/><path d="M480 610 C 460 576, 410 572, 394 596 C 424 616, 454 620, 480 610 Z"/>'
        + _star(520, 130, 52) + _star(76, 150, 48))


def page_lantern():
    """A rabbit lantern on wheels, with sky lanterns and stars."""
    return _page(
        '<path d="M50 70 Q 110 180 180 380" fill="none"/><circle cx="50" cy="66" r="16"/>'
        '<ellipse cx="270" cy="470" rx="190" ry="130"/>'
        '<path d="M120 470 C 170 420, 240 420, 280 470 C 320 520, 390 520, 430 470" fill="none"/>'
        '<ellipse cx="360" cy="170" rx="34" ry="96" transform="rotate(-12 360 170)"/>'
        '<ellipse cx="450" cy="190" rx="32" ry="90" transform="rotate(16 450 190)"/>'
        '<circle cx="420" cy="330" r="110"/>'
        '<circle cx="450" cy="310" r="14" fill="#222222"/>'
        '<ellipse cx="500" cy="372" rx="26" ry="18"/>'
        '<circle cx="170" cy="640" r="56"/><circle cx="380" cy="640" r="56"/>'
        '<circle cx="170" cy="640" r="16"/><circle cx="380" cy="640" r="16"/>'
        '<path d="M70 720 H530" fill="none"/>'
        + _star(530, 80, 52) + _star(220, 130, 50))


def page_childrens_day():
    """Three balloons tied to a present."""
    return _page(
        '<path d="M150 330 C 170 420, 260 460, 300 560 M300 330 V560 M450 330 C 430 420, 340 460, 300 560" fill="none"/>'
        '<ellipse cx="150" cy="200" rx="110" ry="130"/><path d="M136 330 H164 L150 350 Z"/>'
        '<ellipse cx="450" cy="200" rx="110" ry="130"/><path d="M436 330 H464 L450 350 Z"/>'
        '<ellipse cx="300" cy="190" rx="110" ry="130"/><path d="M286 320 H314 L300 340 Z"/>'
        '<rect x="140" y="580" width="320" height="190" rx="14"/>'
        '<rect x="270" y="580" width="60" height="190"/>'
        '<path d="M300 580 C 240 520, 190 560, 230 590 Z M300 580 C 360 520, 410 560, 370 590 Z"/>')


def page_dragon_boat():
    """A dragon boat on the waves, and two rice dumplings."""
    return _page(
        '<path d="M40 460 H470 C 520 460, 540 420, 520 380 C 560 360, 590 330, 560 300 C 540 280, 500 290, 490 320 L470 400 H90 C 70 400, 50 380, 40 340 C 20 380, 20 430, 40 460 Z"/>'
        '<circle cx="540" cy="320" r="12" fill="#222222"/>'
        '<path d="M520 290 L506 240 M548 284 L556 236" fill="none"/>'
        '<circle cx="160" cy="350" r="34"/><circle cx="260" cy="350" r="34"/><circle cx="360" cy="350" r="34"/>'
        '<path d="M80 430 H460" fill="none"/>'
        '<path d="M-10 560 Q 70 500 150 560 T 300 560 T 450 560 T 610 560" fill="none"/>'
        '<path d="M-10 680 Q 70 630 150 680 T 300 680 T 450 680 T 610 680" fill="none"/>'
        '<path d="M150 40 V90 M450 40 V90" fill="none"/>'
        '<path d="M150 90 L240 240 H60 Z"/><path d="M100 180 H200" fill="none"/>'
        '<path d="M450 90 L540 240 H360 Z"/><path d="M400 180 H500" fill="none"/>')


def page_mid_autumn():
    """The full moon, a rabbit, and a mooncake."""
    return _page(
        '<circle cx="330" cy="280" r="230"/>'
        '<circle cx="250" cy="200" r="40"/><circle cx="420" cy="350" r="30"/>'
        '<ellipse cx="200" cy="610" rx="120" ry="100"/>'
        '<circle cx="290" cy="500" r="74"/>'
        '<ellipse cx="250" cy="390" rx="26" ry="70" transform="rotate(-14 250 390)"/>'
        '<ellipse cx="320" cy="390" rx="26" ry="70" transform="rotate(14 320 390)"/>'
        '<circle cx="310" cy="490" r="10" fill="#222222"/>'
        '<circle cx="470" cy="660" r="100"/><circle cx="470" cy="660" r="62"/>'
        + _star(72, 90, 52))


def page_christmas():
    """A Christmas tree with ornaments and two presents."""
    return _page(
        '<rect x="262" y="620" width="76" height="80"/>'
        '<path d="M300 100 L460 340 H390 L520 620 H80 L210 340 H140 Z"/>'
        '<path d="M190 420 C 260 460, 360 450, 420 400 M150 540 C 250 590, 380 580, 470 520" fill="none"/>'
        '<circle cx="240" cy="330" r="26"/><circle cx="360" cy="370" r="26"/><circle cx="210" cy="500" r="26"/><circle cx="400" cy="490" r="26"/>'
        + _star(300, 90, 60)
        + '<rect x="60" y="640" width="160" height="130" rx="10"/><path d="M140 640 V770 M60 700 H220" fill="none"/>'
          '<rect x="390" y="660" width="150" height="110" rx="10"/><path d="M465 660 V770" fill="none"/>')


PAGES = {
    "lunarNewYear": page_lunar_new_year,
    "lantern": page_lantern,
    "childrensDay": page_childrens_day,
    "dragonBoat": page_dragon_boat,
    "midAutumn": page_mid_autumn,
    "christmas": page_christmas,
}
