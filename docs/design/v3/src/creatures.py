"""The places you can go into: their creatures and vehicles, and scenes.

The coloring pages are in animals.py and vehicles.py (Twemoji line art);
this file gathers them and draws the scenes they roam in.

    python3 export_art.py   # writes assets/pages/<id>.png, art/creatures/, art/scenes/
"""
import math

import twemoji
from animals import ANIMALS, GRAY, PAGE_H, PAGE_W
from vehicles import VEHICLES

# id -> (habitat, draw): every page that lives in a scene.
CREATURES = {**ANIMALS, **VEHICLES}


def outline(cid, size=96):
    """The creature in soft gray lines: a card to pick it from."""
    svg = CREATURES[cid][1](ink=GRAY, px=14)
    return svg.replace(f'width="{PAGE_W}" height="{PAGE_H}"', f'width="{size}" height="{size * PAGE_H // PAGE_W}"', 1)


# ---------------------------------------------------------------- the scenes
# 1000 x 1000, shown like a cover image anchored at the bottom: phones see
# the middle, wide screens see the lower part. Creatures roam on top of them
# (see lib/features/scene/).

SCENE = 1000


def _scene(body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SCENE}" height="{SCENE}" viewBox="0 0 {SCENE} {SCENE}">'
            f'<defs>{defs}</defs>{body}</svg>')


def _tree(x, y, r, color="#4DB860"):
    return (f'<rect x="{x - r * 0.18:.1f}" y="{y - r * 0.6:.1f}" width="{r * 0.36:.1f}" height="{r * 1.1:.1f}" rx="{r * 0.12:.1f}" fill="#A86E43"/>'
            f'<circle cx="{x}" cy="{y - r * 1.2:.1f}" r="{r}" fill="{color}"/>'
            f'<circle cx="{x - r * 0.35:.1f}" cy="{y - r * 1.5:.1f}" r="{r * 0.35:.1f}" fill="#FFFFFF" opacity=".18"/>')


def _cloud(x, y, s):
    return (f'<g transform="translate({x} {y}) scale({s})" opacity=".95">'
            '<path d="M10 40 a12 12 0 0 1 4-23 a16 16 0 0 1 30-8 a14 14 0 0 1 26 4 a13 13 0 0 1 8 27 z" fill="#FFFFFF"/></g>')


def deco(code, x, y, size, flip=False, opacity=None, recolor=None):
    """A Twemoji in its own colors (or [recolor]ed: {old: new}): its 36 x 36
    box at (x, y), [size] wide."""
    recolor = {k.upper(): v for k, v in (recolor or {}).items()}
    body = "".join(twemoji.element(t, a, f'fill="{recolor.get(f.upper(), f)}"') for t, a, f in twemoji.shapes(code))
    k = size / 36
    tr = f"translate({x + size:.1f} {y:.1f}) scale({-k:.4f} {k:.4f})" if flip else f"translate({x:.1f} {y:.1f}) scale({k:.4f})"
    op = f' opacity="{opacity}"' if opacity else ""
    return f'<g transform="{tr}"{op}>{body}</g>'


def _acacia(x, y, s=1.0, color="#7FA94A"):
    """A flat-topped savanna tree."""
    return (f'<g transform="translate({x} {y}) scale({s})">'
            '<path d="M-5 0 C -4 -30, -2 -50, -16 -70 M2 0 C 2 -30, 6 -48, 18 -64 M0 -40 C 4 -52, -2 -60, 2 -72" stroke="#8A5A36" stroke-width="7" fill="none" stroke-linecap="round"/>'
            f'<path d="M-70 -70 C -60 -96, 60 -100, 76 -72 C 50 -60, -40 -58, -70 -70 Z" fill="{color}"/>'
            f'<path d="M-40 -86 C -20 -104, 30 -104, 44 -88 C 20 -80, -20 -80, -40 -86 Z" fill="{color}"/></g>')


def _bamboo(x, y, h, lean=0.0):
    """A bamboo stalk with joints and a few leaves."""
    out = [f'<path d="M{x} {y} L{x + lean:.1f} {y - h}" stroke="#6CB64A" stroke-width="13" stroke-linecap="round"/>']
    for k in range(1, int(h // 46) + 1):
        t = k * 46 / h
        jx, jy = x + lean * t, y - h * t
        out.append(f'<path d="M{jx - 8:.1f} {jy:.1f} h16" stroke="#3F8F3A" stroke-width="3" stroke-linecap="round"/>')
        if k % 2 == 0:
            side = 1 if k % 4 == 0 else -1
            out.append(f'<path d="M{jx:.1f} {jy:.1f} q{side * 22} -22 {side * 50} -18 q{-side * 18} 16 {-side * 50} 18 Z" fill="#4FA83E"/>'
                       f'<path d="M{jx:.1f} {jy:.1f} q{side * 26} -2 {side * 44} 12 q{-side * 24} 4 {-side * 44} -12 Z" fill="#5DBB4A"/>')
    return "".join(out)


def zoo_scene():
    """The zoo: savanna with acacia trees and a lion rock, a pool with a
    waterfall, a bamboo grove for the panda, hay and a wooden fence."""
    defs = ('<linearGradient id="zsky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8ED3FF"/><stop offset="1" stop-color="#E8F7FF"/></linearGradient>'
            '<linearGradient id="zfall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#BFEAFF"/><stop offset="1" stop-color="#7CCFFF"/></linearGradient>'
            '<pattern id="zgrass" width="26" height="22" patternUnits="userSpaceOnUse"><path d="M5 14 l2 -6 l2 6 M17 20 l2 -5 l2 5" stroke="#9CC56A" stroke-width="1.6" fill="none"/></pattern>')
    s = ['<rect width="1000" height="560" fill="url(#zsky)"/>',
         '<g transform="translate(830 120)"><circle r="70" fill="#FFE27A" opacity=".35"/><circle r="44" fill="#FFD23F"/></g>',
         _cloud(70, 90, 1.8), _cloud(420, 150, 1.3), _cloud(640, 60, 1.1),
         # far savanna hills with acacias
         '<path d="M0 430 C 140 360, 300 370, 420 420 C 540 370, 700 350, 820 410 C 900 380, 960 390, 1000 400 V560 H0 Z" fill="#C9DE8F"/>',
         _acacia(150, 430, 0.8, "#8DB65A"), _acacia(560, 420, 0.7, "#8DB65A"), _acacia(900, 420, 0.85, "#8DB65A"),
         '<path d="M0 480 C 160 430, 340 450, 500 486 C 660 444, 840 444, 1000 476 V600 H0 Z" fill="#B5D57E"/>']
    # the field
    s.append('<rect y="600" width="1000" height="400" fill="#BFE08C"/><rect y="600" width="1000" height="400" fill="url(#zgrass)"/>')
    # the lion rock (left) with a waterfall into the pool
    s.append('<path d="M30 650 C 40 566, 110 500, 190 492 C 240 470, 300 486, 330 530 C 370 540, 400 590, 390 650 Z" fill="#B59A7A"/>'
             '<path d="M120 520 C 170 500, 240 500, 300 530 C 260 540, 200 546, 150 560 Z" fill="#CDB394"/>'
             '<path d="M70 600 C 110 580, 170 586, 200 610" stroke="#9C7F60" stroke-width="5" fill="none" stroke-linecap="round"/>'
             '<path d="M300 556 C 316 590, 314 630, 318 676 L 350 676 C 344 630, 342 590, 330 548 Z" fill="url(#zfall)"/>'
             '<path d="M312 580 v40 M326 572 v56 M338 590 v40" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" opacity=".8"/>')
    s.append(deco("1faa8", 10, 580, 110) + deco("1faa8", 352, 600, 80, flip=True))
    # bamboo grove (right) for the panda
    s += [_bamboo(x, 640, h, lean) for x, h, lean in [(760, 300, -10), (800, 360, 6), (842, 280, -4), (884, 340, 10), (930, 300, -6), (972, 360, 4)]]
    # the pool in front of the rock
    s.append('<path d="M200 664 C 260 630, 420 628, 500 652 C 540 670, 500 700, 400 704 C 300 708, 190 696, 200 664 Z" fill="#7CCFFF" stroke="#43A9E0" stroke-width="3"/>'
             '<path d="M260 668 q12 -6 24 0 M390 678 q12 -6 24 0" stroke="#DDF4FF" stroke-width="4" fill="none" stroke-linecap="round"/>')
    # the back fence: posts and two rails
    s.append('<rect x="520" y="606" width="480" height="8" fill="#C79A63"/><rect x="520" y="628" width="480" height="8" fill="#C79A63"/>')
    s.append("".join(f'<rect x="{x}" y="596" width="12" height="52" rx="4" fill="#E2BC88" stroke="#A77D4C" stroke-width="1.5"/>' for x in range(530, 1000, 56)))
    # hay, a feeding trough, a log
    s.append(deco("1f33e", 560, 640, 70) + deco("1f33e", 600, 636, 60, flip=True))
    s.append('<g transform="translate(690 700)"><path d="M-60 0 L 60 0 L 48 26 L -48 26 Z" fill="#B98552" stroke="#8A5A36" stroke-width="3"/>'
             '<path d="M-54 2 q20 -16 40 -2 q20 -14 40 -2 q16 -10 30 2" fill="#E9C46A" stroke="#C99A3A" stroke-width="2"/>'
             '<rect x="-44" y="26" width="8" height="18" fill="#8A5A36"/><rect x="36" y="26" width="8" height="18" fill="#8A5A36"/></g>')
    s.append(deco("1fab5", 860, 700, 80))
    # the visitors' path and flowers
    s.append('<path d="M-20 1000 C 180 880, 360 830, 520 822 C 700 814, 860 760, 1020 730 L1020 790 C 860 816, 720 872, 540 882 C 380 892, 240 950, 140 1000 Z" fill="#F3E1BD"/>')
    for code, x, y, size in [("1f33c", 80, 760, 34), ("1f337", 130, 790, 36), ("1f33c", 930, 880, 34), ("1f337", 880, 920, 36),
                             ("1f33c", 380, 960, 30), ("1f337", 640, 950, 32)]:
        s.append(deco(code, x, y, size))
    s.append(deco("1f43e", 470, 900, 34, opacity=".35") + deco("1f43e", 530, 870, 30, opacity=".35"))
    s.append(_tree(30, 990, 70, "#4DB860") + _tree(985, 980, 64, "#58C46B"))
    return _scene("".join(s), defs)


def _fish_school(x, y, n, s, color, flip=False):
    """Far-away little fish, swimming together."""
    out = []
    for k in range(n):
        fx, fy = x + (k % 4) * 34 * s + (k // 4) * 14 * s, y + (k // 4) * 22 * s + (k % 2) * 8 * s
        d = -1 if flip else 1
        out.append(f'<path d="M{fx:.1f} {fy:.1f} q{10 * s * d:.1f} -8 {20 * s * d:.1f} 0 q{-10 * s * d:.1f} 8 {-20 * s * d:.1f} 0 Z '
                   f'M{fx:.1f} {fy:.1f} l{-8 * s * d:.1f} -6 l0 12 Z" fill="{color}"/>')
    return "".join(out)


def aquarium_scene():
    """Inside the aquarium's undersea tunnel: glass arches overhead, light
    from the surface, a coral reef on the sand, rocks, shells and fish far off."""
    defs = ('<linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FE3FF"/><stop offset=".5" stop-color="#3FA8E8"/>'
            '<stop offset="1" stop-color="#1D5FAE"/></linearGradient>'
            '<radialGradient id="glow" cx=".5" cy="0" r=".7"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".45"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>'
            '<pattern id="sand" width="20" height="20" patternUnits="userSpaceOnUse"><circle cx="5" cy="6" r="1.6" fill="#E9C77E"/><circle cx="15" cy="15" r="1.3" fill="#FFF1C9"/></pattern>')
    s = ['<rect width="1000" height="1000" fill="url(#water)"/>', '<rect width="1000" height="600" fill="url(#glow)"/>']
    # light from the surface
    s += [f'<path d="M{x} 0 L{x + w} 0 L{x + w + 160} 900 L{x + 120} 900 Z" fill="#FFFFFF" opacity=".08"/>' for x, w in [(80, 60), (330, 90), (620, 70), (860, 50)]]
    # far reef and fish
    s.append('<path d="M0 800 C 90 700, 180 720, 240 780 C 300 720, 380 700, 440 770 L440 900 H0 Z" fill="#2A6FB8" opacity=".6"/>'
             '<path d="M560 790 C 660 680, 800 700, 860 760 C 910 730, 970 730, 1000 750 V900 H560 Z" fill="#2A6FB8" opacity=".6"/>')
    s.append(_fish_school(140, 330, 8, 1.0, "#2F7FCB") + _fish_school(700, 520, 7, 0.8, "#2F7FCB", flip=True)
             + _fish_school(420, 160, 6, 0.7, "#5BB6EE"))
    # the sand
    s.append('<path d="M0 880 C 160 850, 340 870, 500 880 C 660 890, 840 850, 1000 870 V1000 H0 Z" fill="#F6DDA0"/>'
             '<path d="M0 880 C 160 850, 340 870, 500 880 C 660 890, 840 850, 1000 870 V1000 H0 Z" fill="url(#sand)"/>')

    def weed(x, h, color):
        pts = []
        for i in range(21):
            t = i / 20
            pts.append((x + 14 * math.sin(t * 3 * math.pi), 900 - h * t))
        left = [(px - 9 * (1 - t * 0.7), py) for (px, py), t in zip(pts, [i / 20 for i in range(21)])]
        right = [(px + 9 * (1 - t * 0.7), py) for (px, py), t in zip(pts, [i / 20 for i in range(21)])]
        return '<path d="M' + " L".join(f"{a:.1f} {b:.1f}" for a, b in left + right[::-1]) + f' Z" fill="{color}"/>'
    s += [weed(x, h, c) for x, h, c in [(40, 300, "#3FB37A"), (80, 220, "#5FCB79"), (130, 260, "#3FB37A"), (470, 180, "#5FCB79"),
                                         (880, 280, "#3FB37A"), (930, 220, "#5FCB79"), (965, 320, "#3FB37A")]]
    # the reef: rocks, corals, shells, a starfish
    s.append(deco("1faa8", 150, 790, 150) + deco("1faa8", 690, 800, 130, flip=True))
    pink = {"#FA743E": "#FF6FA5", "#FBBEA9": "#FFC2DA"}
    purple = {"#FA743E": "#9B7CFF", "#FBBEA9": "#D4C8FF"}
    s.append(deco("1fab8", 250, 740, 150) + deco("1fab8", 600, 760, 130, flip=True, recolor=pink) + deco("1fab8", 880, 800, 100, recolor=purple)
             + deco("1fab8", 40, 800, 96, recolor=purple) + deco("1fab8", 450, 820, 80, flip=True, recolor=pink))
    s.append(deco("1f41a", 520, 900, 54) + deco("1f41a", 80, 920, 44, flip=True))
    s.append('<g transform="translate(400 950)"><path d="M0 0 l8 -22 l8 22 l22 0 l-18 13 l7 22 l-19 -13 l-19 13 l7 -22 l-18 -13 z" fill="#FF8A3D" stroke="#D9692A" stroke-width="2"/></g>')
    # the tunnel: glass arches overhead, nearer ones bigger and brighter
    for r, w, op in [(720, 46, ".30"), (720, 6, ".55"), (610, 22, ".18"), (530, 14, ".12")]:
        s.append(f'<path d="M{500 - r} 1000 L{500 - r} {1000 - r * 0.9:.0f} A{r} {r * 0.95:.0f} 0 0 1 {500 + r} {1000 - r * 0.9:.0f} L{500 + r} 1000" '
                 f'fill="none" stroke="#E8F7FF" stroke-width="{w}" opacity="{op}"/>')
    s.append('<path d="M120 120 L 220 60 M150 170 L 300 80 M760 80 L 880 150" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round" opacity=".18"/>')
    s += [f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#FFFFFF" stroke-width="3" opacity=".6"/>'
          for x, y, r in [(180, 600, 10), (196, 560, 6), (170, 520, 8), (720, 420, 12), (740, 380, 7), (520, 260, 9), (536, 226, 5), (880, 640, 8)]]
    return _scene("".join(s), defs)


SCENES = {"zoo": zoo_scene, "aquarium": aquarium_scene}


# ---------------------------------------------------------------- the dinosaur park


def dino_scene():
    """A warm prehistoric valley: a smoking volcano, pterosaurs far off,
    palms and giant ferns, a swamp, a nest of eggs and old bones."""
    defs = ('<linearGradient id="dsky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFB877"/><stop offset="1" stop-color="#FFF1D6"/></linearGradient>'
            '<pattern id="dgrass" width="26" height="22" patternUnits="userSpaceOnUse"><path d="M5 14 l2 -6 l2 6 M17 20 l2 -5 l2 5" stroke="#8DB85A" stroke-width="1.6" fill="none"/></pattern>')
    s = ['<rect width="1000" height="580" fill="url(#dsky)"/>',
         '<g transform="translate(150 130)"><circle r="60" fill="#FFE27A" opacity=".4"/><circle r="38" fill="#FFD23F"/></g>']
    # far mountains, the volcano, pterosaurs gliding
    s.append('<path d="M0 470 L 120 360 L 210 430 L 320 330 L 430 440 L 520 400 L 640 480 V560 H0 Z" fill="#D9A07A" opacity=".55"/>')
    s.append(deco("1f30b", 470, 170, 400))
    for x, y, k in [(300, 210, 1.0), (380, 250, 0.7), (820, 160, 0.8)]:
        s.append(f'<path d="M{x} {y} q{-26 * k:.1f} {-18 * k:.1f} {-52 * k:.1f} {-6 * k:.1f} q{24 * k:.1f} {2 * k:.1f} {40 * k:.1f} {14 * k:.1f} '
                 f'q{16 * k:.1f} {-12 * k:.1f} {40 * k:.1f} {-14 * k:.1f} q{-26 * k:.1f} {-12 * k:.1f} {-52 * k:.1f} {6 * k:.1f} Z" fill="#8A5A44" opacity=".75"/>')
    s.append('<path d="M0 500 C 150 420, 300 440, 430 480 C 560 440, 760 440, 1000 480 V600 H0 Z" fill="#8CC26A"/>'
             '<path d="M0 540 C 200 500, 380 510, 560 540 C 740 504, 880 504, 1000 530 V620 H0 Z" fill="#78B85A"/>')
    # jungle: palms behind the valley floor
    s += [deco("1f334", x, y, size, flip=f) for x, y, size, f in [(-40, 330, 260, False), (180, 400, 170, True), (760, 380, 220, True), (880, 330, 240, False)]]
    s.append('<rect y="580" width="1000" height="420" fill="#B9D88A"/><rect y="580" width="1000" height="420" fill="url(#dgrass)"/>')
    # the swamp, rocks, a nest of eggs, old bones, footprints
    s.append('<path d="M60 690 C 120 650, 320 650, 380 690 C 400 720, 300 740, 200 738 C 100 736, 40 720, 60 690 Z" fill="#7FB8A0" stroke="#5E9A82" stroke-width="3"/>'
             '<path d="M140 690 q10 -6 20 0 M260 704 q10 -6 20 0" stroke="#D8F3E8" stroke-width="4" fill="none" stroke-linecap="round"/>')
    s.append(deco("1faa8", 480, 600, 110) + deco("1faa8", 570, 630, 70, flip=True))
    # a nest of three spotted dinosaur eggs
    nest = ['<ellipse cx="820" cy="760" rx="100" ry="30" fill="#A9794A"/>']
    for x, y, rot, color in [(770, 700, -12, "#FFF4E2"), (822, 690, 4, "#E8F6EC"), (872, 704, 14, "#FFE9EF")]:
        nest.append(f'<g transform="rotate({rot} {x} {y})"><ellipse cx="{x}" cy="{y}" rx="30" ry="40" fill="{color}" stroke="#D8C3A0" stroke-width="3"/>'
                    f'<circle cx="{x - 10}" cy="{y - 12}" r="5" fill="#C9B48E"/><circle cx="{x + 8}" cy="{y + 4}" r="6" fill="#C9B48E"/>'
                    f'<circle cx="{x - 4}" cy="{y + 20}" r="4" fill="#C9B48E"/></g>')
    nest.append('<path d="M720 752 C 760 790, 880 790, 920 752 C 900 780, 860 794, 820 794 C 780 794, 740 780, 720 752 Z" fill="#8A5A36"/>'
                '<path d="M736 766 l30 6 M790 784 l40 -4 M860 774 l36 -10" stroke="#C9965C" stroke-width="4" stroke-linecap="round"/>')
    s.append("".join(nest))
    s.append(deco("1f9b4", 380, 860, 90) + deco("1f9b4", 440, 890, 70, flip=True))
    s += [f'<ellipse cx="{x}" cy="{y}" rx="18" ry="10" fill="#8A7A5B" opacity=".4"/><circle cx="{x - 12}" cy="{y - 12}" r="5" fill="#8A7A5B" opacity=".4"/>'
          f'<circle cx="{x}" cy="{y - 16}" r="5" fill="#8A7A5B" opacity=".4"/><circle cx="{x + 12}" cy="{y - 12}" r="5" fill="#8A7A5B" opacity=".4"/>'
          for x, y in [(600, 900), (660, 860), (720, 900), (780, 860)]]

    s += [deco("1f33f", x, y, size, flip=f) for x, y, size, f in [(-40, 820, 210, False), (830, 810, 210, True), (420, 560, 80, False), (660, 590, 70, True)]]
    s.append(deco("1f344", 900, 840, 50) + deco("1f344", 70, 820, 40, flip=True))
    return _scene("".join(s), defs)


SCENES["dinoPark"] = dino_scene


# ---------------------------------------------------------------- the transport museum


def transport_scene():
    """The transport museum (交通車館): sky to fly in, the museum hall with
    its glass front, a railway track for the trains, and a road with lanes."""
    defs = ('<linearGradient id="tsky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#86CFFF"/><stop offset="1" stop-color="#E6F6FF"/></linearGradient>'
            '<pattern id="tgrass" width="26" height="22" patternUnits="userSpaceOnUse"><path d="M5 14 l2 -6 l2 6 M17 20 l2 -5 l2 5" stroke="#8FC56A" stroke-width="1.6" fill="none"/></pattern>')
    s = ['<rect width="1000" height="600" fill="url(#tsky)"/>',
         '<g transform="translate(850 120)"><circle r="66" fill="#FFE27A" opacity=".35"/><circle r="42" fill="#FFD23F"/></g>',
         _cloud(60, 100, 1.7), _cloud(420, 70, 1.2), _cloud(660, 190, 1.0), _cloud(220, 260, 0.9)]
    # the museum hall: an arched glass roof, big windows, flags
    hall = ['<path d="M220 560 V 400 Q 500 250 780 400 V 560 Z" fill="#E9EEF5" stroke="#9AA9BC" stroke-width="5"/>',
            '<path d="M260 400 Q 500 290 740 400" fill="none" stroke="#BFD9F2" stroke-width="26"/>',
            '<path d="M300 380 L 300 340 M380 352 L 380 310 M460 334 L 460 296 M540 334 L 540 296 M620 352 L 620 310 M700 380 L 700 340" stroke="#9AA9BC" stroke-width="4"/>']
    for x in range(250, 760, 72):
        hall.append(f'<rect x="{x}" y="430" width="56" height="86" rx="6" fill="#A9DCFF" stroke="#6E8FB0" stroke-width="3"/>'
                    f'<path d="M{x + 8} {442} l18 -0 M{x + 8} {452} l10 0" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" opacity=".8"/>')
    hall.append('<rect x="440" y="470" width="120" height="90" rx="8" fill="#5C7DA6"/><rect x="452" y="482" width="44" height="78" fill="#86B6E8"/><rect x="504" y="482" width="44" height="78" fill="#86B6E8"/>')
    hall.append('<rect x="200" y="552" width="600" height="14" rx="4" fill="#C5CFDC"/>')
    hall.append(deco("1f6a9", 214, 290, 70) + deco("1f6a9", 722, 290, 70))
    # a sign over the door with a little train and plane
    hall.append('<rect x="400" y="380" width="200" height="56" rx="14" fill="#FF6B6B" stroke="#D94B4B" stroke-width="4"/>')
    hall.append(deco("1f682", 414, 384, 48) + deco("2708", 476, 384, 48) + deco("1f68c", 538, 384, 48, flip=True))
    s += hall
    s += [deco("1f333", x, 470, size) for x, size in [(110, 110), (790, 120), (900, 100)]]
    # grass, then the railway
    s.append('<rect y="560" width="1000" height="440" fill="#BDE38F"/><rect y="560" width="1000" height="440" fill="url(#tgrass)"/>')
    s.append('<rect y="616" width="1000" height="40" fill="#C9B79C"/>')
    s.append("".join(f'<rect x="{x}" y="620" width="20" height="34" rx="3" fill="#8A6A4A"/>' for x in range(-10, 1010, 44)))
    s.append('<rect y="626" width="1000" height="7" fill="#7D8794"/><rect y="642" width="1000" height="7" fill="#7D8794"/>')
    # the road: two lanes, a dashed middle line, a sidewalk and a crossing
    s.append('<rect y="740" width="1000" height="210" fill="#5D6470"/>'
             '<rect y="728" width="1000" height="14" fill="#D7DCE3"/><rect y="948" width="1000" height="16" fill="#D7DCE3"/>')
    s.append("".join(f'<rect x="{x}" y="841" width="56" height="8" rx="3" fill="#FFFFFF"/>' for x in range(10, 1000, 100) if not 380 < x < 600))
    s.append("".join(f'<rect x="440" y="{y}" width="120" height="16" rx="3" fill="#FFFFFF" opacity=".9"/>' for y in range(752, 940, 30)))
    s.append('<rect y="964" width="1000" height="36" fill="#BDE38F"/>')
    # a traffic light, a bus stop sign, flowers
    s.append('<rect x="160" y="700" width="10" height="40" fill="#5D6878"/>' + deco("1f6a6", 120, 622, 90))
    s.append('<rect x="868" y="664" width="10" height="76" fill="#5D6878"/><rect x="826" y="660" width="52" height="9" rx="4" fill="#5D6878"/>' + deco("1f6a5", 772, 616, 90))
    s.append('<rect x="684" y="600" width="8" height="128" fill="#8A97A8"/><circle cx="688" cy="600" r="26" fill="#FFFFFF" stroke="#2F80D1" stroke-width="7"/>')
    s.append(deco("1f68c", 670, 582, 36, flip=True))
    for code, x, y, size in [("1f337", 40, 960, 34), ("1f33c", 300, 964, 30), ("1f337", 620, 962, 32), ("1f33c", 930, 960, 32)]:
        s.append(deco(code, x, y, size))
    return _scene("".join(s), defs)


SCENES["transport"] = transport_scene
