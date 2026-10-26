"""The town map as layers, for the app and the mockups.

The world is 780 x 1060. The designed town sits in the middle column
(x 195-585, the 390 points a phone shows); wider screens see the wings.
Each place kind has its own layer (the building, or an empty lot before the
first postcard arrives), so the app can stack only what a child has built.

    python3 town.py export   # writes app/assets/art/town/*.svg and town_layout_data.dart
"""
import math
import pathlib
import re
import sys

from kit import (CORAL, box, car, cloud, duck, empty_lot, flower_patch, ROOF, shade, tower101, tree, _poly)

W, H = 780, 1060
OX = 195  # left edge of the designed column

DEFS = ('<defs>'
        '<linearGradient id="mtB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FD49D"/><stop offset="1" stop-color="#B5E5B6"/></linearGradient>'
        '<linearGradient id="mtF" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5FBF72"/><stop offset="1" stop-color="#8ED48E"/></linearGradient>'
        '<linearGradient id="river" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5CC0F5"/><stop offset="1" stop-color="#8ED8FF"/></linearGradient>'
        '<pattern id="grassdots" width="18" height="18" patternUnits="userSpaceOnUse"><circle cx="4" cy="5" r="1.4" fill="#8BD07E"/><circle cx="13" cy="13" r="1.2" fill="#B6E9A6"/></pattern>'
        '<pattern id="tiles" width="14" height="14" patternUnits="userSpaceOnUse"><rect width="14" height="14" fill="#F6E7CC"/><path d="M0 0H14M0 0V14" stroke="#EAD5B0" stroke-width="1.2"/></pattern>'
        '</defs>')

ROOF.update({"#E3F4FB": "#2C7FD6", "#FFF4E2": CORAL, "#FFE7A3": "#6F86FF", "#E3F6E8": "#3FB37A", "#FFE3EA": "#FF8FB1",
             "#E8EEFF": "#7C6CFF", "#E8836B": "#5E7290", "#F3F6FA": "#4DA8FF"})


# ---------------------------------------------------------------- time of day

PHASES = ("day", "dusk", "night")
PHASE = "day"  # the time of day being drawn; places add their lights at night

# At dusk and night every color is recolored, channel by channel, to
# c * scale + offset. Windows light up instead, and LIGHTS (lamps, the moon,
# lanterns) keep their color so they glow.
TINT = {"dusk": ((0.95, 0.82, 0.74), (14, 6, 16)), "night": ((0.27, 0.34, 0.47), (16, 24, 58))}
WINDOWS = {"#A9E0FF", "#E8F6FF"}
LIT_WINDOW = {"dusk": "#FFEDC2", "night": "#FFD86B"}
MOON = "#FFF3C2"
LANTERN, LANTERN_GOLD = "#FF4B4B", "#FFCF3F"
BULB_GREEN, BULB_BLUE = "#6BE38A", "#6FC3FF"
LIGHTS = {"#FFD86B", "#FFEDC2", MOON, LANTERN, LANTERN_GOLD, BULB_GREEN, BULB_BLUE}


def tint(svg_text, phase):
    """The drawing as it looks at [phase]."""
    if phase not in TINT:
        return svg_text
    (kr, kg, kb), (cr, cg, cb) = TINT[phase]

    def recolor(m):
        h = m.group(0).upper()
        if len(h) == 4:
            h = "#" + "".join(ch * 2 for ch in h[1:])
        if h in LIGHTS:
            return h
        if h in WINDOWS:
            return LIT_WINDOW[phase]
        r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
        return "#%02X%02X%02X" % tuple(min(255, round(v * k + c)) for v, k, c in ((r, kr, cr), (g, kg, cg), (b, kb, cb)))

    return re.sub(r"#[0-9A-Fa-f]{6}\b|#[0-9A-Fa-f]{3}\b", recolor, svg_text)


def glow(cx, cy, r=12, color=MOON):
    """A soft halo, drawn only at night."""
    if PHASE != "night":
        return ""
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{color}" opacity=".16"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 0.55:.1f}" fill="{color}" opacity=".26"/>')


def mid(*parts):
    """Content drawn in the designed column's own coordinates."""
    return f'<g transform="translate({OX} 0)">{"".join(parts)}</g>'


def dashes(x0, y, x1, dash=12, gap=12, w=2.6, color="#FFFFFF"):
    """A dashed horizontal line as separate segments (renders the same everywhere)."""
    out, x = [], x0
    while x < x1:
        out.append(f'M{x} {y} H{min(x + dash, x1)}')
        x += dash + gap
    return f'<path d="{" ".join(out)}" stroke="{color}" stroke-width="{w}" fill="none"/>'


def vdashes(x, y0, y1, dash=12, gap=12, w=2.6, color="#FFFFFF"):
    out, y = [], y0
    while y < y1:
        out.append(f'M{x} {y} V{min(y + dash, y1)}')
        y += dash + gap
    return f'<path d="{" ".join(out)}" stroke="{color}" stroke-width="{w}" fill="none"/>'


def road_h(y, w=30, x0=0, x1=W):
    return (f'<rect x="{x0}" y="{y - w / 2 - 6}" width="{x1 - x0}" height="{w + 12}" fill="#F4E4C8"/>'
            f'<rect x="{x0}" y="{y - w / 2}" width="{x1 - x0}" height="{w}" fill="#E2E7EE"/>' + dashes(x0 + 4, y, x1))


def crosswalks(cx, cy):
    s = [f'<rect x="{cx - 15}" y="{cy - 15}" width="30" height="30" fill="#E2E7EE"/>']
    for i in range(5):
        s.append(f'<rect x="{cx - 14 + i * 6}" y="{cy - 30}" width="3.4" height="13" fill="#FFFFFF"/>')
        s.append(f'<rect x="{cx - 14 + i * 6}" y="{cy + 17}" width="3.4" height="13" fill="#FFFFFF"/>')
    return "".join(s)


def house(x, y, color, w=34, h=30):
    return box(x, y, w, h, 5, color, roof="gable", roof_h=16, windows=[(w / 2 - 6, 8, 12, 10)])


# ---------------------------------------------------------------- layers

def base():
    """Sky and land together, as the mockups draw them."""
    return sky("day") + land()


def sky(phase="day"):
    """The sky with the sun (or the moon and stars) and clouds; one per time of day."""
    stops = {
        "day": [(0, "#7CCBFF"), (1, "#D4F0FF")],
        "dusk": [(0, "#8C84D4"), (0.55, "#FF9F8A"), (1, "#FFD9A3")],
        "night": [(0, "#141E46"), (1, "#3B4C8A")],
    }[phase]
    s = ['<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'
         + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in stops) + '</linearGradient></defs>',
         f'<rect width="{W}" height="236" fill="url(#sky)"/>']
    if phase == "day":
        s.append(mid('<g transform="translate(316 92)"><circle r="34" fill="#FFE27A" opacity=".35"/><circle r="22" fill="#FFD23F"/></g>'))
    elif phase == "dusk":
        s.append(mid('<g transform="translate(300 116)"><circle r="46" fill="#FFB47A" opacity=".45"/><circle r="28" fill="#FF8A4C"/></g>'))
    else:
        for i in range(46):  # stars, scattered the same way every time
            x = (i * 137.5) % W
            y = 14 + (i * 71.3) % 176
            r = 1.1 + (i % 3) * 0.55
            s.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.2f}" fill="{MOON}" opacity="{0.55 + (i % 4) * 0.12:.2f}"/>')
        s.append(mid(f'<g transform="translate(316 92)"><circle r="40" fill="{MOON}" opacity=".12"/><circle r="28" fill="{MOON}" opacity=".16"/>'
                     f'<circle r="20" fill="{MOON}"/><circle cx="9" cy="-7" r="17" fill="#22305F"/></g>'))
    clouds = (cloud(40, 110, 0.8) + cloud(640, 70, 0.9) + cloud(700, 140, 0.6, 0.9)
              + mid(cloud(30, 86, 0.9), cloud(196, 118, 0.7, 0.9)))
    s.append(f'<g opacity="{0.55 if phase == "night" else 1}">{tint(clouds, phase)}</g>')
    return "".join(s)


def land():
    """Everything below the sky: mountains, river, roads, the MRT, scenery."""
    s = [DEFS]
    # mountains: wings first, then the designed column
    s.append('<path d="M0 176 C 50 128, 120 128, 188 196 L188 232 L0 232 Z" fill="url(#mtB)"/>')
    s.append('<path d="M592 160 C 650 116, 720 120, 780 158 L780 232 L592 232 Z" fill="url(#mtB)"/>')
    s.append('<path d="M0 204 C 60 172, 130 178, 188 214 L188 236 L0 236 Z" fill="url(#mtF)"/>')
    s.append('<path d="M592 186 C 650 166, 720 160, 780 182 L780 236 L592 236 Z" fill="url(#mtF)"/>')
    s.append(mid(
        '<path d="M-10 196 C 30 150, 60 140, 96 168 C 120 128, 168 112, 214 158 C 250 130, 300 118, 400 160 L400 230 L-10 230 Z" fill="url(#mtB)"/>',
        '<path d="M-10 214 C 40 176, 90 172, 130 196 C 170 168, 220 166, 262 192 C 300 170, 350 164, 400 186 L400 236 L-10 236 Z" fill="url(#mtF)"/>',
        '<path d="M150 182 L 286 132 L 400 120" stroke="#5E6F86" stroke-width="1.6" fill="none"/>',
        "".join(f'<path d="M{gx} {gy} v6" stroke="#5E6F86" stroke-width="1.4"/><rect x="{gx - 7}" y="{gy + 6}" width="14" height="12" rx="4" fill="{gc}" stroke="{shade(gc, -0.3)}" stroke-width="1.2"/><rect x="{gx - 4.5}" y="{gy + 8.5}" width="9" height="4.5" rx="1.5" fill="#E8F6FF"/>'
                for gx, gy, gc in [(196, 165, "#FF5E5B"), (268, 139, "#FFC94A"), (340, 126, "#4DA8FF")]),
        '<path d="M120 62 l6 4 6-4 M140 54 l5 3 5-3" stroke="#4E6D8C" stroke-width="2" fill="none" stroke-linecap="round"/>',
        '<g transform="translate(92 140)"><path d="M0 -26 C 16 -26, 18 -6, 6 4 L -6 4 C -18 -6, -16 -26, 0 -26 Z" fill="#FF8FB1" stroke="#E0668C" stroke-width="1.4"/>'
        '<path d="M0 -26 C 6 -20, 6 -4, 3 4 M0 -26 C -6 -20, -6 -4, -3 4" stroke="#FFFFFF" stroke-width="2" fill="none"/>'
        '<path d="M-5 4 L-4 10 M5 4 L4 10" stroke="#8A6A4A" stroke-width="1.2"/><rect x="-5" y="10" width="10" height="7" rx="2" fill="#C98B5E"/></g>'))
    # land
    s.append(f'<rect x="0" y="224" width="{W}" height="{H - 224}" fill="#A6DE97"/><rect x="0" y="224" width="{W}" height="{H - 224}" fill="url(#grassdots)"/>')
    # river: wings, then the designed stretch
    s.append('<path d="M0 238 C 70 226, 140 230, 190 233 L190 286 C 130 292, 60 298, 0 290 Z" fill="url(#river)"/>')
    s.append('<path d="M590 236 C 660 242, 720 226, 780 232 L780 290 C 720 294, 650 280, 590 286 Z" fill="url(#river)"/>')
    s.append(mid('<path d="M-10 232 C 80 220, 150 250, 240 238 S 340 222, 400 236 L400 286 C 330 274, 260 296, 180 288 S 60 272, -10 286 Z" fill="url(#river)"/>'))
    s.append('<path d="M0 238 C 70 226, 140 230, 185 232" stroke="#43A9E0" stroke-width="1.5" fill="none"/><path d="M595 236 C 660 242, 720 226, 780 232" stroke="#43A9E0" stroke-width="1.5" fill="none"/>')
    s.append(mid('<path d="M-10 232 C 80 220, 150 250, 240 238 S 340 222, 400 236" stroke="#43A9E0" stroke-width="1.5" fill="none"/>'
                 '<path d="M400 286 C 330 274, 260 296, 180 288 S 60 272, -10 286" stroke="#43A9E0" stroke-width="1.5" fill="none"/>'))
    s.append('<path d="M0 290 C 60 298, 130 292, 190 286" stroke="#43A9E0" stroke-width="1.5" fill="none"/><path d="M590 286 C 650 280, 720 294, 780 290" stroke="#43A9E0" stroke-width="1.5" fill="none"/>')
    for wx, wy in [(30, 262), (110, 266), (640, 258), (730, 266)]:
        s.append(f'<path d="M{wx} {wy} q6 -4 12 0 t12 0" stroke="#D8F3FF" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    s.append(mid(
        "".join(f'<path d="M{wx} {wy} q6 -4 12 0 t12 0" stroke="#D8F3FF" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                for wx, wy in [(30, 254), (120, 264), (210, 258), (300, 250), (350, 266)]),
        '<g transform="translate(286 230)"><rect x="-4" y="22" width="68" height="9" rx="3" fill="#F3E3C6" stroke="#C9A97B" stroke-width="1.2"/>'
        '<path d="M2 24 Q30 -8 58 24" stroke="#FF5E5B" stroke-width="5" fill="none" stroke-linecap="round"/>'
        + "".join(f'<path d="M{8 + i * 11} 24 V{14 - (i in (2, 3)) * 6 + (i in (0, 4)) * 4}" stroke="#FF5E5B" stroke-width="2"/>' for i in range(5)) + '</g>',
        '<g transform="translate(70 270)"><path d="M-18 -6 h36 l-6 9 h-24 z" fill="#FFFFFF" stroke="#9FB3C8" stroke-width="1.4"/>'
        '<path d="M0 -6 V-28 L 16 -10 Z" fill="#FFC94A" stroke="#D9A21C" stroke-width="1.2"/><path d="M0 -26 L-12 -10 H0" fill="#FF8FB1"/></g>',
        duck(170, 276, 0.9), duck(186, 281, 0.75)))
    # roads: three avenues across the whole world, one up the middle
    s.append(road_h(448) + road_h(652) + road_h(860))
    s.append(f'<rect x="{OX + 206 - 21}" y="296" width="42" height="{H - 296}" fill="#F4E4C8"/><rect x="{OX + 206 - 15}" y="296" width="30" height="{H - 296}" fill="#E2E7EE"/>'
             + vdashes(OX + 206, 300, H))
    s.append(mid(crosswalks(206, 448), crosswalks(206, 652), crosswalks(206, 860),
                 '<rect x="232" y="474" width="150" height="160" rx="18" fill="url(#tiles)"/>'))
    # MRT line across the world, the train and the station
    s.append(f'<rect x="-10" y="318" width="{W + 20}" height="12" rx="3" fill="#D5DEE9" stroke="#A9B6C6" stroke-width="1.4"/>')
    for px in range(14, W, 64):
        s.append(f'<rect x="{px}" y="330" width="9" height="30" fill="#C2CDDA" stroke="#A9B6C6" stroke-width="1.2"/>')

    def mrt_car(x0):
        return (f'<rect x="{x0}" y="296" width="58" height="22" rx="8" fill="#FFFFFF" stroke="#9FB3C8" stroke-width="1.4"/>'
                f'<rect x="{x0}" y="309" width="58" height="5" fill="#4DA8FF"/>'
                + "".join(f'<rect x="{x0 + 6 + i * 13}" y="300" width="9" height="7" rx="2" fill="#A9E0FF"/>' for i in range(4)))
    s.append(mid(mrt_car(38), mrt_car(98), mrt_car(158),
                 '<rect x="250" y="288" width="96" height="30" rx="6" fill="#E9F3FF" stroke="#9FB3C8" stroke-width="1.4"/>'
                 '<path d="M244 290 Q298 262 352 290 Z" fill="#7CC6FF" stroke="#4E9AD6" stroke-width="1.4"/>'
                 '<circle cx="298" cy="303" r="7" fill="#FFFFFF" stroke="#4DA8FF" stroke-width="2.2"/><path d="M294 303 h8" stroke="#4DA8FF" stroke-width="2.2"/>'))
    # trees that belong to no place, the tower, and the wings' own houses
    s.append(mid(tree(26, 414, 12), tree(178, 400, 11, "#58C46B"), tree(372, 430, 11), tower101(320, 626), tower_lights(320, 626), glow(298, 303, 18),
                 tree(30, 1030, 12), tree(200, 1040, 10, "#58C46B", "pine"), tree(380, 1030, 12)))
    s.append(wings())
    return "".join(s)


def tower_lights(tx, ty):
    """Taipei 101 lit up at night (same geometry as kit.tower101)."""
    if PHASE != "night":
        return ""
    s = []
    for i in range(6):
        yb = ty - 26 - i * 26
        s.append(f'<path d="M{tx + 6} {yb - 9} H{tx + 38}" stroke="{MOON}" stroke-width="2.4"/>')
        s.append(f'<path d="M{tx + 8} {yb - 18} H{tx + 37}" stroke="{MOON}" stroke-width="1.4" opacity=".55"/>')
    top = ty - 26 - 6 * 26
    s.append(glow(tx + 22, top - 48, 16) + f'<circle cx="{tx + 22}" cy="{top - 48}" r="4" fill="{MOON}"/>')
    return "".join(s)


def wings():
    """Scenery left and right of the designed column, seen on wide screens."""
    s = []
    # left wing: neighbors' houses (the dinosaur park and the aquarium are their own layers)
    s.append(house(24, 420, "#E3F6E8") + house(76, 412, "#FFE3EA") + house(128, 424, "#E8EEFF"))
    s.append(tree(16, 380, 10) + tree(176, 396, 9, "#58C46B"))
    s.append(tree(30, 850, 12, "#4DB860", "pine") + tree(160, 846, 11, "#58C46B", "pine"))
    s.append(house(30, 960, "#FFE7A3") + house(100, 972, "#E3F6E8") + tree(160, 950, 11))
    # right wing: houses by the river, a windmill farm (the transport museum is its own layer)
    s.append(house(606, 418, "#FFE3EA") + house(660, 426, "#FFE7A3") + house(714, 414, "#E3F6E8"))
    s.append('<g transform="translate(720 980)"><rect x="-5" y="-60" width="10" height="60" fill="#FFF4E2" stroke="#C9A06B" stroke-width="1.4"/>'
             + "".join(f'<path d="M0 -60 L{26 * math.cos(math.radians(a)):.1f} {-60 + 26 * math.sin(math.radians(a)):.1f}" stroke="#FF8FB1" stroke-width="6" stroke-linecap="round"/>' for a in (15, 105, 195, 285))
             + '<circle cx="0" cy="-60" r="4" fill="#C98B5E"/></g>')
    s.append(tree(620, 960, 12) + tree(660, 1000, 10, "#58C46B", "pine") + tree(760, 1030, 11))
    return "".join(s)


# (x, y, color, kind, facing left, in the designed column)
CARS = [(60, 452, "#FFD23F", "car", False, True), (300, 446, CORAL, "car", True, True),
        (150, 658, "#4DA8FF", "scooter", False, True), (206, 560, "#7BD389", "bus", False, True),
        (330, 658, "#FF8FB1", "scooter", True, True), (110, 864, "#7C6CFF", "car", False, True),
        (80, 452, "#FF8A3D", "car", False, False), (700, 656, "#4DA8FF", "car", True, False),
        (640, 864, "#FFD23F", "scooter", False, False)]


def headlight(x, y, kind, flip):
    if PHASE != "night":
        return ""
    d = -1 if flip else 1
    fx = x + d * {"car": 20, "bus": 28, "scooter": 12}[kind]
    return f'<path d="M{fx} {y - 7} L{fx + d * 30} {y - 14} Q{fx + d * 36} {y - 5.5} {fx + d * 30} {y + 3} Z" fill="{MOON}" opacity=".22"/>'


def traffic():
    designed, wing = [], []
    for x, y, color, kind, flip, column in CARS:
        (designed if column else wing).append(car(x, y, color, kind, flip) + headlight(x, y, kind, flip))
    return mid(*designed) + "".join(wing)


def home():
    return mid(box(44, 420, 66, 46, 7, "#FFF4E2", roof="gable", roof_h=26, windows=[(8, 12, 13, 12), (45, 12, 13, 12)], door=(26, 15, 24, "#C98B5E")),
               '<path d="M78 368 c-3-4-9-1-6 3 l6 5 6-5 c3-4-3-7-6-3z" fill="#FFFFFF" opacity=".9" transform="translate(-1 -4)"/>',
               '<rect x="124" y="402" width="4" height="18" fill="#8A6A4A"/><rect x="116" y="390" width="20" height="14" rx="5" fill="#3FB37A" stroke="#2A8A57" stroke-width="1.2"/><rect x="134" y="386" width="3" height="8" fill="#FF5E5B"/>')


def school():
    return mid(box(236, 424, 104, 58, 8, "#FFE7A3", roof="flat",
                   windows=[(8, 14, 13, 12), (26, 14, 13, 12), (64, 14, 13, 12), (82, 14, 13, 12), (8, 34, 13, 12), (82, 34, 13, 12)],
                   door=(44, 16, 26, "#E8A24A")),
               '<rect x="273" y="344" width="30" height="24" fill="#FFE7A3" stroke="#C29A4A" stroke-width="1.4"/><path d="M268 346 L288 328 L308 346 Z" fill="#6F86FF" stroke="#4A5FC4" stroke-width="1.4"/>'
               '<circle cx="288" cy="357" r="7" fill="#FFFFFF" stroke="#C29A4A" stroke-width="1.2"/><path d="M288 357 V352 M288 357 L291 359" stroke="#4A3B47" stroke-width="1.4" stroke-linecap="round"/>',
               '<path d="M352 424 V380" stroke="#8A6A4A" stroke-width="2"/><path d="M352 380 L370 385 L352 390 Z" fill="#FF5E5B"/>')


def park():
    return mid('<rect x="10" y="470" width="180" height="164" rx="26" fill="#8CD27D"/><rect x="10" y="470" width="180" height="164" rx="26" fill="url(#grassdots)"/>',
               '<path d="M20 520 C 60 530, 90 560, 120 600" stroke="#F4E4C8" stroke-width="9" fill="none" stroke-linecap="round"/>',
               '<path d="M90 584 C 100 556, 152 552, 172 572 C 188 592, 156 616, 122 612 C 98 610, 84 602, 90 584 Z" fill="#7CCFFF" stroke="#43A9E0" stroke-width="1.5"/>',
               '<path d="M108 590 q6 -3 12 0 M140 598 q6 -3 12 0" stroke="#D8F3FF" stroke-width="2" fill="none" stroke-linecap="round"/>',
               duck(124, 584, 0.9), duck(148, 592, 0.8, True),
               '<g transform="translate(140 516)"><path d="M0 26 L8 -4 H22 L22 26" stroke="#FF8FB1" stroke-width="4" fill="none" stroke-linejoin="round"/><path d="M22 -4 Q 44 4 46 26" stroke="#FFC94A" stroke-width="7" fill="none" stroke-linecap="round"/></g>',
               tree(30, 512, 13), tree(62, 500, 11, "#58C46B"), tree(178, 640, 10, "#58C46B", "pine"), tree(28, 628, 12, "#4DB860", "palm"),
               flower_patch(40, 586), flower_patch(166, 488, ("#FFFFFF", "#FF8FB1", "#FFD166")))


def shop():
    return mid(box(240, 600, 66, 36, 6, "#E8EEFF", roof="flat", windows=[(6, 14, 24, 16)], door=(38, 18, 24, "#9FB3C8")),
               '<rect x="240" y="566" width="66" height="7" fill="#FF8A3D"/><rect x="240" y="573" width="66" height="5" fill="#3FB37A"/>')


def food():
    s = ['<path d="M14 684 Q 94 704 180 684" stroke="#8A6A4A" stroke-width="1.5" fill="none"/>']
    for i, lx in enumerate([30, 58, 86, 114, 142, 168]):
        ly = 684 + 16 * math.sin(math.pi * (lx - 14) / 166) - 4
        c = "#FF5E5B" if i % 2 == 0 else "#FFC94A"
        s.append(f'<ellipse cx="{lx}" cy="{ly + 6}" rx="6" ry="7" fill="{c}" stroke="{shade(c, -0.3)}" stroke-width="1.2"/><rect x="{lx - 3}" y="{ly - 2}" width="6" height="3" fill="#8A6A4A"/>')
        if PHASE == "night":
            s.append(glow(lx, ly + 6, 14, LANTERN_GOLD) + f'<ellipse cx="{lx}" cy="{ly + 6}" rx="6" ry="7" fill="{LANTERN if i % 2 == 0 else LANTERN_GOLD}"/>')
    for i, (sx, aw) in enumerate([(14, "#FF5E5B"), (70, "#FFC94A"), (126, "#3FB37A")]):
        s.append(box(sx, 754, 48, 26, 5, "#FFF4E2"))
        s.append(f'<rect x="{sx - 4}" y="722" width="56" height="12" rx="4" fill="{aw}" stroke="{shade(aw, -0.3)}" stroke-width="1.2"/>')
        s.append("".join(f'<rect x="{sx + 2 + k * 13}" y="722" width="6" height="12" fill="#FFFFFF" opacity=".75"/>' for k in range(4)))
        s.append("".join(f'<circle cx="{sx + k * 9.3}" cy="735" r="4.6" fill="{aw}"/>' for k in range(7)))
        foods = [("#FFB347", "#A0673F"), ("#FF8FB1", "#FFFFFF"), ("#7BD389", "#FFD166")][i]
        s.append(f'<circle cx="{sx + 15}" cy="746" r="5" fill="{foods[0]}"/><circle cx="{sx + 31}" cy="746" r="5" fill="{foods[1]}" stroke="#E5D3B3"/>')
    return mid(*s)


def temple():
    tx0 = 230
    return mid(box(tx0 + 10, 800, 96, 34, 6, "#FFE3C4", door=(36, 24, 26, "#C9452E")),
               f'<path d="M{tx0} 760 Q {tx0 + 12} 766 {tx0 + 22} 752 L{tx0 + 96} 752 Q {tx0 + 106} 766 {tx0 + 118} 760 L {tx0 + 108} 770 L {tx0 + 10} 770 Z" fill="#F0583E" stroke="#B83A26" stroke-width="1.4"/>'
               f'<path d="M{tx0 + 16} 752 Q {tx0 + 59} 732 {tx0 + 102} 752 Z" fill="#FF7A54" stroke="#B83A26" stroke-width="1.4"/>'
               f'<path d="M{tx0 + 4} 758 q-6 -8 -2 -12 M{tx0 + 114} 758 q6 -8 2 -12" stroke="#FFC94A" stroke-width="3" fill="none" stroke-linecap="round"/>'
               f'<circle cx="{tx0 + 59}" cy="728" r="5" fill="#FFC94A" stroke="#D9A21C"/>'
               f'<circle cx="{tx0 + 30}" cy="782" r="5" fill="#FF5E5B" stroke="#B83A26"/><circle cx="{tx0 + 88}" cy="782" r="5" fill="#FF5E5B" stroke="#B83A26"/>',
               "".join(glow(tx0 + lx, 782, 14, LANTERN_GOLD) + (f'<circle cx="{tx0 + lx}" cy="782" r="5" fill="{LANTERN}"/>' if PHASE == "night" else "")
                       for lx in (30, 88)))


def zoo():
    # in the right wing, next to the temple
    x0 = 600
    fence = "".join(f'<rect x="{x0 + k * 14}" y="772" width="6" height="28" rx="2" fill="#E8C79A" stroke="#B9935E" stroke-width="1"/>' for k in range(12))
    return ('<rect x="596" y="690" width="172" height="120" rx="20" fill="#C9E7A1"/>'
            f'<g transform="translate({x0 + 20} 700)">'
            '<path d="M26 88 V20 q0 -14 10 -16" stroke="#F7C35C" stroke-width="12" stroke-linecap="round" fill="none"/>'
            '<circle cx="31" cy="44" r="3" fill="#C98536"/><circle cx="27" cy="62" r="3.4" fill="#C98536"/><circle cx="32" cy="28" r="2.6" fill="#C98536"/>'
            '<ellipse cx="42" cy="6" rx="12" ry="8" fill="#F7C35C" stroke="#C98536" stroke-width="1.4"/>'
            '<path d="M36 -2 v-7 M44 -2 v-7" stroke="#C98536" stroke-width="2.4" stroke-linecap="round"/><circle cx="45" cy="4" r="1.8" fill="#2A211D"/></g>'
            # an elephant
            '<g transform="translate(700 760)"><ellipse cx="0" cy="0" rx="26" ry="18" fill="#B8C3D6" stroke="#8C99B0" stroke-width="1.4"/>'
            '<circle cx="-24" cy="-8" r="13" fill="#B8C3D6" stroke="#8C99B0" stroke-width="1.4"/><ellipse cx="-14" cy="-10" rx="8" ry="10" fill="#A5B1C7"/>'
            '<path d="M-34 -4 q-8 10 -2 20" stroke="#B8C3D6" stroke-width="6" fill="none" stroke-linecap="round"/><circle cx="-28" cy="-11" r="1.8" fill="#2A211D"/>'
            '<rect x="-16" y="12" width="8" height="12" rx="3" fill="#B8C3D6"/><rect x="8" y="12" width="8" height="12" rx="3" fill="#B8C3D6"/></g>'
            + tree(752, 724, 11) + fence + f'<rect x="{x0 - 2}" y="778" width="{12 * 14}" height="5" fill="#D9B27D"/>'
            + zoo_gate(x0 + 4, 806))


def zoo_gate(x, y):
    """The zoo's entrance: two posts and a giraffe-spotted arch."""
    spots = "".join(f'<circle cx="{x + dx}" cy="{y - 50 + dy}" r="2.6" fill="#C98536"/>' for dx, dy in [(8, 4), (20, 1), (32, 4), (44, 2)])
    return (f'<rect x="{x - 4}" y="{y - 54}" width="9" height="54" rx="3" fill="#E8C79A" stroke="#B9935E" stroke-width="1.2"/>'
            f'<rect x="{x + 47}" y="{y - 54}" width="9" height="54" rx="3" fill="#E8C79A" stroke="#B9935E" stroke-width="1.2"/>'
            f'<path d="M{x - 8} {y - 46} Q {x + 26} {y - 72} {x + 60} {y - 46} L {x + 60} {y - 36} Q {x + 26} {y - 60} {x - 8} {y - 36} Z" fill="#F7C35C" stroke="#C98536" stroke-width="1.4"/>'
            + spots)


def aquarium():
    """The aquarium in the left wing: a glass dome with a whale on top."""
    x0, base = 22, 806
    portholes = "".join(f'<circle cx="{x0 + dx}" cy="{base - 22}" r="8" fill="#A9E0FF" stroke="#2C7FD6" stroke-width="2"/>' for dx in (20, 46, 104, 130))
    whale_top = (f'<g transform="translate({x0 + 74} 716)">'
                 '<path d="M-18 0 q6 -14 22 -12 q14 2 14 12 q-3 10 -20 10 q-12 0 -16 -10z" fill="#4DA8FF" stroke="#2C7FD6" stroke-width="1.2"/>'
                 '<path d="M-17 0 l-10 -7 v14z" fill="#4DA8FF" stroke="#2C7FD6" stroke-width="1.2"/><circle cx="8" cy="-1" r="1.8" fill="#2A211D"/>'
                 '<path d="M2 -12 q0 -8 -4 -12 M2 -12 q2 -8 7 -10" stroke="#7CCFFF" stroke-width="2" fill="none" stroke-linecap="round"/></g>')
    return ('<rect x="12" y="694" width="178" height="124" rx="20" fill="#CFEFF7"/>'
            + f'<path d="M{x0 + 16} 764 Q {x0 + 75} 694 {x0 + 134} 764 Z" fill="#7CCFFF" stroke="#43A9E0" stroke-width="1.6"/>'
            + f'<path d="M{x0 + 34} 752 Q {x0 + 54} 722 {x0 + 80} 716" stroke="#FFFFFF" stroke-width="3" fill="none" stroke-linecap="round" opacity=".8"/>'
            + box(x0, base, 150, 42, 6, "#E3F4FB", roof="flat", door=(62, 26, 30, "#4DA8FF"))
            + portholes
            + f'<path d="M{x0} {base - 6} q9 -6 18 0 t18 0 t18 0 t18 0 t18 0 t18 0 t18 0 t18 0 t6 0 V{base} H{x0} Z" fill="#4DA8FF"/>'
            + whale_top + duck(170, 806, 0.7, True))


def dino_park():
    """The dinosaur park in the left wing: a smoking volcano, a long neck over the fence."""
    fence = "".join(f'<rect x="{18 + k * 14}" y="604" width="7" height="30" rx="2" fill="#C9A06B" stroke="#8A6A4A" stroke-width="1"/>' for k in range(12))
    neck = ('<path d="M120 606 C 124 560, 140 520, 152 500 L 166 506 C 154 530, 142 566, 140 608 Z" fill="#7BD389" stroke="#3FA052" stroke-width="1.4"/>'
            '<ellipse cx="166" cy="498" rx="17" ry="11" fill="#7BD389" stroke="#3FA052" stroke-width="1.4"/><circle cx="170" cy="495" r="1.8" fill="#2A211D"/>'
            '<circle cx="134" cy="560" r="3" fill="#3FA052"/><circle cx="142" cy="530" r="2.6" fill="#3FA052"/>')
    volcano = ('<path d="M30 600 L 74 520 L 96 520 L 140 600 Z" fill="#A47A4F" stroke="#7A5A3A" stroke-width="1.4"/>'
               '<path d="M68 532 L 74 520 L 96 520 L 102 532 Q 85 540 68 532 Z" fill="#FF8A3D"/>'
               + "".join(f'<circle cx="{x}" cy="{y}" r="{r}" fill="#FFFFFF" opacity=".8"/>' for x, y, r in [(86, 508, 7), (92, 494, 9), (86, 478, 11)]))
    eggs = ('<ellipse cx="60" cy="626" rx="26" ry="8" fill="#C9A06B"/>'
            '<ellipse cx="50" cy="618" rx="7" ry="9" fill="#FFF4E2" stroke="#E6D3B3"/><ellipse cx="62" cy="616" rx="7" ry="9" fill="#E3F6E8" stroke="#B6D9BF"/><ellipse cx="74" cy="618" rx="7" ry="9" fill="#FFE3EA" stroke="#E8B9C6"/>')
    gate = ('<rect x="150" y="590" width="8" height="46" rx="3" fill="#A86E43"/><rect x="184" y="590" width="8" height="46" rx="3" fill="#A86E43"/>'
            '<rect x="144" y="580" width="54" height="16" rx="7" fill="#FFF4E2" stroke="#C9A06B" stroke-width="1.4"/>'
            '<path d="M158 588 h26 M156 584 a3 3 0 1 0 0 8 M186 584 a3 3 0 1 1 0 8" stroke="#C9A06B" stroke-width="3" fill="none" stroke-linecap="round"/>')
    return ('<rect x="12" y="476" width="178" height="170" rx="20" fill="#C9E19A"/>'
            + volcano + tree(176, 560, 12, "#3FB37A", "palm") + neck + fence
            + '<rect x="16" y="610" width="168" height="5" fill="#A86E43"/>' + eggs + gate)


def transport():
    """The transport museum in the right wing: a hall with an arched glass
    roof, a steam engine on display out front and a little plane on top."""
    windows = "".join(f'<rect x="{x}" y="548" width="20" height="30" rx="3" fill="#A9DCFF" stroke="#6E8FB0" stroke-width="1.2"/>' for x in (618, 646, 718, 746))
    rails = ('<rect x="602" y="622" width="160" height="6" rx="2" fill="#8A6A4A"/>'
             + "".join(f'<rect x="{x}" y="619" width="5" height="11" rx="1" fill="#6E5338"/>' for x in range(606, 760, 12)))
    engine = ('<g transform="translate(640 592)">'
              '<rect x="0" y="12" width="56" height="16" rx="4" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.4"/>'
              '<rect x="40" y="-4" width="22" height="32" rx="3" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.4"/><rect x="45" y="1" width="12" height="10" rx="2" fill="#A9E0FF"/>'
              '<rect x="10" y="-2" width="10" height="16" fill="#5A6472"/><path d="M6 -6 h18 l-3 6 h-12 z" fill="#5A6472"/>'
              '<circle cx="12" cy="30" r="6" fill="#2F3540"/><circle cx="28" cy="30" r="6" fill="#2F3540"/><circle cx="50" cy="30" r="6" fill="#2F3540"/>'
              '<circle cx="12" cy="30" r="2" fill="#C5CFDC"/><circle cx="28" cy="30" r="2" fill="#C5CFDC"/><circle cx="50" cy="30" r="2" fill="#C5CFDC"/>'
              '<path d="M-2 28 L -10 28 L 0 16 Z" fill="#FFD23F" stroke="#C99A1A" stroke-width="1.2"/>'
              '<circle cx="15" cy="-12" r="4" fill="#FFFFFF" opacity=".85"/><circle cx="10" cy="-20" r="5" fill="#FFFFFF" opacity=".85"/></g>')
    plane = ('<g transform="translate(682 500)"><path d="M-22 4 C -10 0, 14 -2, 22 2 C 14 6, -10 8, -22 4 Z" fill="#4DA8FF" stroke="#2C7FD6" stroke-width="1.2"/>'
             '<path d="M-2 3 L -12 -10 L -6 -10 L 6 3 Z M-2 5 L -10 16 L -4 16 L 6 5 Z" fill="#7CC4FF" stroke="#2C7FD6" stroke-width="1"/>'
             '<path d="M-20 3 L -24 -5 L -19 -5 L -15 3 Z" fill="#7CC4FF" stroke="#2C7FD6" stroke-width="1"/></g>')
    return ('<rect x="596" y="476" width="172" height="170" rx="20" fill="#D6E9C4"/>'
            '<path d="M606 590 V 540 Q 682 486 758 540 V 590 Z" fill="#E9EEF5" stroke="#9AA9BC" stroke-width="1.6"/>'
            '<path d="M616 540 Q 682 500 748 540" fill="none" stroke="#BFD9F2" stroke-width="7"/>'
            + windows + '<rect x="670" y="552" width="24" height="38" rx="3" fill="#5C7DA6"/>'
            + '<rect x="602" y="588" width="160" height="5" rx="2" fill="#C5CFDC"/>'
            + plane + rails + engine
            + '<path d="M612 518 v-24" stroke="#8A97A8" stroke-width="2"/><path d="M612 494 l14 5 l-14 5 z" fill="#FF5E5B"/>'
            + tree(752, 616, 10))


def grandma():
    return mid(box(36, 960, 96, 52, 8, "#E8836B", roof="gable", roof_h=24, windows=[(10, 14, 16, 14), (70, 14, 16, 14)], door=(40, 16, 30, "#7A4A2A")),
               '<path d="M58 990 c-2-3-6-1-4 2 l4 3 4-3 c2-3-2-5-4-2z M118 990 c-2-3-6-1-4 2 l4 3 4-3 c2-3-2-5-4-2z" fill="#FF8FB1"/>',
               '<rect x="140" y="978" width="40" height="30" rx="6" fill="#C9A06B"/>'
               + "".join(f'<circle cx="{148 + k * 12}" cy="986" r="4" fill="#5FCB79"/><circle cx="{148 + k * 12}" cy="1000" r="4" fill="#FF8A3D"/>' for k in range(3)),
               tree(20, 940, 10, "#58C46B"))


def travel():
    return mid(box(240, 970, 118, 46, 8, "#F3F6FA", roof="flat", windows=[(10, 12, 20, 14), (88, 12, 20, 14)], door=(48, 22, 28, "#9FB3C8")),
               '<rect x="282" y="900" width="34" height="26" rx="3" fill="#F3F6FA" stroke="#9FB3C8" stroke-width="1.4"/><circle cx="299" cy="913" r="8" fill="#FFFFFF" stroke="#9FB3C8" stroke-width="1.4"/>'
               '<path d="M299 913 V908 M299 913 L302 915" stroke="#4A3B47" stroke-width="1.4" stroke-linecap="round"/>',
               '<rect x="236" y="1022" width="160" height="6" fill="#B9A58C"/>'
               '<rect x="252" y="1004" width="70" height="18" rx="7" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.4"/>'
               + "".join(f'<rect x="{258 + k * 14}" y="1008" width="9" height="6" rx="1.5" fill="#FFFFFF"/>' for k in range(4))
               + '<rect x="326" y="1004" width="54" height="18" rx="5" fill="#FF8A3D" stroke="#C9692A" stroke-width="1.4"/>')


# kind -> (building layer, lot rect in world coords, pin anchor in world coords)
SLOTS = {
    "home": (home, None, (OX + 78, 344)),
    "school": (school, (OX + 234, 342, 130, 86), (OX + 288, 330)),
    "park": (park, (OX + 14, 478, 172, 150), (OX + 74, 566)),
    "shop": (shop, (OX + 238, 556, 72, 62), (OX + 272, 560)),
    "food": (food, (OX + 12, 680, 172, 120), (OX + 96, 688)),
    "temple": (temple, (OX + 232, 704, 124, 100), (OX + 289, 730)),
    "zoo": (zoo, None, (668, 700)),
    "aquarium": (aquarium, None, (100, 700)),
    "dinoPark": (dino_park, None, (96, 500)),
    "transport": (transport, None, (682, 520)),
    "grandma": (grandma, (OX + 24, 892, 164, 124), (OX + 84, 932)),
    "travel": (travel, (OX + 232, 892, 158, 136), (OX + 299, 896)),
    # scenery that is always there: only a pin anchor
    "water": (None, None, (OX + 150, 300)),
    "mountain": (None, None, (OX + 60, 200)),
    "station": (None, None, (OX + 298, 286)),
}
ORDER = ["home", "school", "park", "shop", "food", "temple", "zoo", "aquarium", "dinoPark", "transport", "grandma", "travel"]
# Places you can go into (scenes in the app), always built: kind -> tap area.
ATTRACTIONS = {"zoo": (596, 690, 172, 124), "aquarium": (12, 690, 178, 128), "dinoPark": (12, 476, 178, 170),
               "transport": (596, 476, 172, 170)}


def lot(kind):
    x, y, w, h = SLOTS[kind][1]
    return empty_lot(x, y, w, h, kind)


def svg(content, view=f"0 0 {W} {H}", width=W, height=H, extra=""):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{view}" {extra}>{content}</svg>'


def town_map(dim=False, built=None):
    """The phone-sized crop (390 x 844) used by the mockups."""
    parts = [base()]
    for kind in ORDER:
        parts.append(SLOTS[kind][0]() if built is None or kind in built or SLOTS[kind][1] is None else lot(kind))
    parts.append(traffic())
    if dim:
        parts.append(f'<rect width="{W}" height="{H}" fill="rgba(25,45,35,.38)"/>')
    return svg("".join(parts), view=f"{OX} 0 390 844", width=390, height=844, extra='class="abs" style="left:0;top:0" aria-hidden="true"')


def world(phase="day", built=None, festival=None):
    """The whole world at [phase], as the app stacks it (for previews)."""
    import festivals
    global PHASE
    PHASE = phase
    parts = [sky(phase), tint(land(), phase)]
    for kind in ORDER:
        layer = SLOTS[kind][0]() if built is None or kind in built or SLOTS[kind][1] is None else lot(kind)
        parts.append(tint(layer, phase))
    parts.append(tint(traffic(), phase))
    if festival:
        parts.append(tint(festivals.DECOR[festival](), phase))
    PHASE = "day"
    return svg("".join(parts))


def export(app_dir):
    """Every layer at every time of day: <layer>_<phase>.svg."""
    import festivals
    global PHASE
    out = pathlib.Path(app_dir) / "assets" / "art" / "town"
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("*.svg"):
        old.unlink()
    for phase in PHASES:
        PHASE = phase

        def put(name, content):
            (out / f"{name}_{phase}.svg").write_text(tint(svg(content), phase))

        (out / f"sky_{phase}.svg").write_text(svg(sky(phase)))
        put("land", land())
        put("traffic", traffic())
        for kind in ORDER:
            put(kind, DEFS + SLOTS[kind][0]())
            if SLOTS[kind][1]:
                put(f"{kind}_lot", lot(kind))
        for name, decor in festivals.DECOR.items():
            put(f"festival_{name}", DEFS + decor())
    PHASE = "day"
    lines = ["// Generated by docs/design/v3/src/town.py; do not edit.", "", "import 'dart:ui';", "",
             f"const townSize = Size({W}, {H});", "", "/// Left edge of the column a phone shows first.",
             f"const townColumnLeft = {OX}.0;", "",
             "/// Where each kind of place sits: its pin, and the empty lot before it is built.",
             "const townSlots = <String, ({Offset pin, Rect? lot, bool building})>{"]
    for kind, (layer, lotr, pin) in SLOTS.items():
        lr = f"Rect.fromLTWH({lotr[0]}, {lotr[1]}, {lotr[2]}, {lotr[3]})" if lotr else "null"
        lines.append(f"  '{kind}': (pin: Offset({pin[0]}, {pin[1]}), lot: {lr}, building: {'true' if layer else 'false'}),")
    lines += ["};", "", "/// Back to front.", "const townLayerOrder = [" + ", ".join(f"'{k}'" for k in ORDER) + "];", "",
              "/// Festivals with a decoration layer (`festival_<name>_<phase>.svg`).",
              "const townFestivalLayers = {" + ", ".join(f"'{k}'" for k in festivals.DECOR) + "};", "",
              "/// Places you can go into (the zoo, the aquarium, the dinosaur park, the transport museum): always built; tapping opens their scene.",
              "const townAttractions = <String, Rect>{",
              *[f"  '{k}': Rect.fromLTWH({x}, {y}, {w}, {h})," for k, (x, y, w, h) in ATTRACTIONS.items()],
              "};", "",
              "/// The tip of Taipei 101, where the New Year's Eve fireworks go up.",
              f"const townTowerTop = Offset({OX + 342}, 396);", ""]
    dart = pathlib.Path(app_dir) / "lib" / "features" / "town" / "town_layout_data.dart"
    dart.parent.mkdir(parents=True, exist_ok=True)
    dart.write_text("\n".join(lines))
    print("wrote", out, dart)


if __name__ == "__main__":
    import town  # the same module festivals.py sees, so PHASE is shared

    if sys.argv[1:] == ["export"]:
        town.export(pathlib.Path(__file__).resolve().parents[4] / "app")
    elif sys.argv[1:2] == ["preview"]:
        # python3 town.py preview night [festival]  -> world_preview.svg
        phase = sys.argv[2] if len(sys.argv) > 2 else "day"
        fest = sys.argv[3] if len(sys.argv) > 3 else None
        pathlib.Path(sys.argv[0]).with_name("world_preview.svg").write_text(town.world(phase, festival=fest))
