"""Creature coloring pages for the zoo, the aquarium and the dinosaur park.

Most are Twemoji (CC BY 4.0, see twemoji.py) turned into line art, so they
look like the real animal. Where Twemoji has no full-body animal, one is put
together from Twemoji parts plus a few shapes drawn here in the same style:

  lion          the tiger without stripes, with a mane and a tail tuft
  zebra         the horse with stripes
  panda         the panda face on a sitting body holding bamboo
  clownfish     the fish with three bands
  triceratops   the hippo with a frill, three horns and a tail
  stegosaurus   the hippo's body with plates, a small head and a spiky tail
  pterosaur     the bat's wings with a crested, beaked head
  babyDino      the hatching chick as a little dinosaur in its shell

Each page is 600 x 800, facing right, with nothing else on it, so the app
can cut the colored creature out and let it roam its scene.
"""
import math

import twemoji
from twemoji import Pen

PAGE_W, PAGE_H = 600, 800
INK = twemoji.INK
GRAY = "#8C9BAD"
FIT = (50, 130, 550, 690)  # where the drawing goes on the page


def tw_page(code, *, ink=INK, px=9.0, flip=True, drop=(), black=(), white=(), under=None, between=None, over=None,
            box=None, defs=None):
    """A page from Twemoji [code]: its parts as line art, with extra shapes
    [under] all parts, [between] = {n: f} just before part n, [over] all.

    Extras are functions of the Pen, drawn in Twemoji's 36 x 36 units (before
    the flip). [box] is the area to fit on the page (default: the Twemoji's
    own bounds); lines are [px] page pixels wide whatever the scale.
    """
    x0, y0, x1, y1 = box or twemoji.bounds(code, drop)
    fx0, fy0, fx1, fy1 = FIT
    s = min((fx1 - fx0) / (x1 - x0), (fy1 - fy0) / (y1 - y0))
    pen = Pen(px / s, ink)
    pieces = twemoji.parts(code, pen, drop, black, white)
    body = [under(pen) if under else ""]
    for i, piece in enumerate(pieces):
        if between and i in between:
            body.append(between[i](pen))
        if piece:
            body.append(piece)
    body.append(over(pen) if over else "")
    w, h = (x1 - x0) * s, (y1 - y0) * s
    left, top = (fx0 + fx1 - w) / 2, (fy0 + fy1 - h) / 2
    if flip:
        transform = f"translate({left + w:.2f} {top:.2f}) scale({-s:.4f} {s:.4f}) translate({-x0:.3f} {-y0:.3f})"
    else:
        transform = f"translate({left:.2f} {top:.2f}) scale({s:.4f}) translate({-x0:.3f} {-y0:.3f})"
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" height="{PAGE_H}" viewBox="0 0 {PAGE_W} {PAGE_H}">'
            f'<defs>{defs(pen) if defs else ""}</defs><rect width="{PAGE_W}" height="{PAGE_H}" fill="#FFFFFF"/>'
            f'<g transform="{transform}">{"".join(body)}</g></svg>')


def _d(points):
    return "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in points) + " Z"


def bumpy(cx, cy, r, bumps, depth, start=0.0, sweep=2 * math.pi, closed=True):
    """A scalloped outline (a mane, a frill) around (cx, cy)."""
    d = ""
    for k in range(bumps + (0 if closed else 1)):
        a = start + sweep * k / bumps
        x, y = cx + r * math.cos(a), cy + r * math.sin(a)
        if k == 0:
            d = f"M{x:.2f} {y:.2f}"
            continue
        m = start + sweep * (k - 0.5) / bumps
        d += f" Q{cx + (r + depth) * math.cos(m):.2f} {cy + (r + depth) * math.sin(m):.2f} {x:.2f} {y:.2f}"
    if closed:
        a, m = start, start + sweep * (bumps - 0.5) / bumps
        d += f" Q{cx + (r + depth) * math.cos(m):.2f} {cy + (r + depth) * math.sin(m):.2f} {cx + r * math.cos(a):.2f} {cy + r * math.sin(a):.2f}"
    return d + " Z"


def horn(bx, by, tx, ty, w, bend=0.0):
    """A curved cone from a base at (bx, by), [w] wide, to its tip."""
    dx, dy = tx - bx, ty - by
    d = math.hypot(dx, dy)
    nx, ny = -dy / d, dx / d
    mx, my = bx + dx * 0.55 + nx * bend, by + dy * 0.55 + ny * bend
    return (f'M{bx + nx * w / 2:.2f} {by + ny * w / 2:.2f} Q{mx + nx * w * 0.25:.2f} {my + ny * w * 0.25:.2f} {tx:.2f} {ty:.2f} '
            f'Q{mx - nx * w * 0.25:.2f} {my - ny * w * 0.25:.2f} {bx - nx * w / 2:.2f} {by - ny * w / 2:.2f} Z')


# ---------------------------------------------------------------- the zoo

def elephant(**k):
    return tw_page("1f418", **k)


def giraffe(**k):
    return tw_page("1f992", **k)


def monkey(**k):
    return tw_page("1f412", **k)


def lion(**k):
    # The tiger faces left; its head is around (5, 18).
    # The mane is a ring over the head, around the face (an oval at (4.2, 19)).
    def mane(p):
        outer = bumpy(5.6, 18.6, 8.2, 14, 2.0, math.radians(-135), math.radians(270), closed=False)[:-2]
        fx, fy, rx, ry = 4.2, 19.2, 4.4, 5.0
        a = math.radians(135)
        return (f'<path d="{outer} L{fx + rx * math.cos(a):.2f} {fy + ry * math.sin(a):.2f} '
                f'A{rx} {ry} 0 1 0 {fx + rx * math.cos(a):.2f} {fy - ry * math.sin(a):.2f} Z" {p.area}/>')
    tuft = lambda p: f'<path d="M32.6 29.6 C 31.4 31.6, 32.4 34.4, 34.6 34.2 C 36.8 34.0, 36.6 30.6, 34.4 29.8 Z" {p.area}/>'
    return tw_page("1f405", drop=(2,), between={1: mane}, over=tuft, box=(-2.4, 8.2, 36.8, 36.0), **k)


def zebra(**k):
    # The galloping horse faces left: stripes across its body (part 5),
    # clipped to it.
    body = [twemoji.shapes("1f40e")[5]]

    def defs(p):
        return '<clipPath id="zebra">' + "".join(twemoji.element(t, a, "") for t, a, _ in body) + "</clipPath>"

    def stripes(p):
        bands = []
        for i, x in enumerate([7.6, 10.4, 13.2, 16.2, 19.2, 22.2, 25.2, 28.2]):
            lean = 1.2 if i < 3 else 0.4
            bands.append(f'<path d="M{x:.1f} 4 C {x + lean:.1f} 14, {x - 1.2:.1f} 24, {x + 0.6:.1f} 36 l1.1 0 '
                         f'C {x:.1f} 24, {x + lean + 1.1:.1f} 14, {x + 1.1:.1f} 4 Z" {p.solid}/>')
        bands.append(f'<path d="M2.4 10.6 l3.2 -1.6 l0.4 1 l-3.2 1.6 Z M3.2 12.8 l3.6 -1.6 l0.4 1 l-3.6 1.6 Z" {p.solid}/>')
        return '<g clip-path="url(#zebra)">' + "".join(bands) + "</g>"
    return tw_page("1f40e", between={6: stripes}, defs=defs, **k)


def panda(**k):
    # The panda face (1f43c) on a sitting body drawn here, holding bamboo.
    face = twemoji.shapes("1f43c")

    def body(p):
        s = [f'<path d="M27.5 24 L 31 47 L 33.4 47 L 30 24 Z" {p.area}/>',  # bamboo
             f'<path d="M27.9 30 L 30.6 30 M28.9 38 L 31.7 38" {p.line}/>',
             f'<path d="M30.6 27 q3 -3 5 -2 q-1.6 2.6 -5 2 Z" {p.area}/>',
             f'<ellipse cx="18" cy="37" rx="13" ry="11.5" {p.area}/>',  # body
             f'<ellipse cx="18" cy="39" rx="8" ry="7.4" {p.area}/>',  # belly
             f'<ellipse cx="9.2" cy="45.4" rx="5.4" ry="3.9" {p.area}/>',  # feet
             f'<ellipse cx="26.8" cy="45.4" rx="5.4" ry="3.9" {p.area}/>',
             f'<ellipse cx="9.2" cy="45.6" rx="2.4" ry="1.7" {p.area}/>',
             f'<ellipse cx="26.8" cy="45.6" rx="2.4" ry="1.7" {p.area}/>',
             f'<path d="M8.4 27.4 C 4.2 29.6, 3.4 35.6, 6.4 38.2 C 8.4 40, 11.6 39.6, 12.6 37.6 C 13.2 36, 11.8 34.6, 10.4 34.4 C 10.6 32, 10.8 29.6, 8.4 27.4 Z" {p.area}/>',  # arms
             f'<path d="M27.4 27.2 C 31.6 27.4, 33.6 30.4, 32.4 33.2 C 31.4 35.4, 28.6 35.6, 27.4 34.2 C 26.6 33, 26.8 31.6, 27.8 31 C 27.2 29.8, 26.8 28.4, 27.4 27.2 Z" {p.area}/>']
        k_ = 0.8
        head = "".join(twemoji.parts("1f43c", p.__class__(p.width / k_, p.ink)))
        s.append(f'<g transform="translate({18 - 18 * k_:.2f} 0) scale({k_})">{head}</g>')
        return "".join(s)
    return tw_page("1f43c", drop=tuple(range(len(face))), over=body, box=(2.2, 0.2, 36.2, 49.6), flip=False, **k)


# ---------------------------------------------------------------- the aquarium

def whale(**k):
    return tw_page("1f40b", **k)


def turtle(**k):
    return tw_page("1f422", **k)


def octopus(**k):
    return tw_page("1f419", flip=False, **k)


def jellyfish(**k):
    return tw_page("1fabc", flip=False, **k)


def crab(**k):
    return tw_page("1f980", flip=False, **k)


def clownfish(**k):
    # The fish faces left: three white bands across its body (part 3).
    fish = twemoji.shapes("1f41f")

    def defs(p):
        t, a, _ = fish[3]
        return f'<clipPath id="clown">{twemoji.element(t, a, "")}</clipPath>'

    def bands(p):
        out = []
        for x, w in [(10.2, 2.6), (17.4, 2.8), (23.6, 2.2)]:
            out.append(f'<path d="M{x:.1f} 6 C {x - 1.6:.1f} 14, {x - 1.6:.1f} 22, {x:.1f} 31 L{x + w:.1f} 31 '
                       f'C {x + w - 1.4:.1f} 22, {x + w - 1.4:.1f} 14, {x + w:.1f} 6 Z" {p.area}/>')
        return '<g clip-path="url(#clown)">' + "".join(out) + "</g>"
    return tw_page("1f41f", between={4: bands}, defs=defs, **k)


# ---------------------------------------------------------------- the dinosaur park

def trex(**k):
    return tw_page("1f996", **k)


def brachiosaurus(**k):
    return tw_page("1f995", **k)


def triceratops(**k):
    # The hippo (facing left) without ears: a frill behind its head (part 1),
    # horns on top, and a tail.
    tail = lambda p: f'<path d="M33 21 C 37 22.5, 39.6 25.6, 41.6 30.4 C 38.4 28.4, 35.6 27.4, 33.4 27.2 Z" {p.area}/>'
    frill = lambda p: f'<path d="{bumpy(12.6, 19.2, 8.2, 12, 1.6, math.radians(150), math.radians(250), closed=False)}" {p.area}/>'
    horns = lambda p: (f'<path d="{horn(7.2, 16.4, 3.4, 8.4, 2.2, -0.8)}" {p.area}/>'
                       f'<path d="{horn(11.2, 15.6, 9.8, 7.4, 2.2, -0.8)}" {p.area}/>'
                       f'<path d="{horn(2.6, 19.4, 0.6, 15.6, 1.8, -0.4)}" {p.area}/>')
    return tw_page("1f99b", drop=(6,), under=tail, between={1: frill}, over=horns, box=(-0.4, 7.0, 41.8, 36.0), **k)


def stegosaurus(**k):
    # The hippo's body (part 0, facing left) with plates on its back, a
    # small head on a neck, and a tail with spikes.
    def under(p):
        plates = "".join(f'<path d="M{x - 3.2:.1f} {y + 4:.1f} Q{x - 3.2:.1f} {y - 3:.1f} {x:.1f} {y - 6.4:.1f} '
                         f'Q{x + 3.2:.1f} {y - 3:.1f} {x + 3.2:.1f} {y + 4:.1f} Z" {p.area}/>'
                         for x, y in [(13.8, 15.4), (19.2, 12.8), (25, 12.6), (30.4, 14.2), (34.4, 17.4)])
        tail = (f'<path d="M33.6 20 C 38 20.4, 41.6 18.4, 44.4 14.2 C 43.6 19.6, 40 24.4, 34.6 26.6 Z" {p.area}/>'
                f'<path d="{horn(42.4, 17.2, 44.6, 11.8, 1.6)}" {p.area}/><path d="{horn(43.4, 15.6, 47.6, 13.0, 1.6)}" {p.area}/>')
        neck = f'<path d="M12.6 17.6 C 8 18.6, 5.6 21.6, 4.2 23.2 L 6.6 27.4 C 9 25.6, 11 25, 13.6 25.4 Z" {p.area}/>'
        return plates + tail + neck

    def over(p):
        return (f'<ellipse cx="4" cy="25.2" rx="4.2" ry="3" {p.area}/>'
                f'<circle cx="3.2" cy="24.2" r="0.8" {p.solid}/><path d="M0.6 26.4 q1.6 0.8 3.2 0.2" {p.line}/>')
    return tw_page("1f99b", drop=(1, 2, 3, 4, 5, 6), under=under, over=over, box=(-0.4, 5.6, 48.4, 36.0), **k)


def pterosaur(**k):
    # The bat's wings and body, with a crested, beaked head instead of its own.
    def head(p):
        return (f'<path d="M15.6 7.8 L 9.2 3.4 L 14.2 9.8 Z" {p.area}/>'
                f'<path d="M14.8 6.6 C 16.4 4.6, 20 4.6, 21.4 6.4 L 31.4 9.2 L 21.4 10.6 C 19.6 12.6, 15.8 12.4, 14.6 10.2 C 14 9, 14.1 7.6, 14.8 6.6 Z" {p.area}/>'
                f'<circle cx="18.6" cy="7.6" r="1" {p.solid}/><path d="M21.4 9.2 L 28.6 9.4" {p.line}/>')
    return tw_page("1f987", drop=(1, 2, 3, 5, 6, 7, 10), over=head, flip=False, box=(0.0, 2.6, 36.0, 34.0), **k)


def baby_dino(**k):
    # The hatching chick (part 1) as a little dinosaur: no beak, spikes on
    # its head, a smile, and hands on the shell.
    spikes = lambda p: "".join(f'<path d="M{x - 2.2:.1f} {y + 2.4:.1f} Q{x - 0.8:.1f} {y - 2.2:.1f} {x:.1f} {y - 5.0:.1f} Q{x + 0.8:.1f} {y - 2.2:.1f} {x + 2.2:.1f} {y + 2.4:.1f} Z" {p.area}/>'
                               for x, y in [(12.4, 4.6), (18, 2.6), (23.6, 4.6)])

    def face(p):
        return (f'<path d="M14.6 15.6 Q18 18.6 21.4 15.6" {p.line}/>'
                f'<circle cx="16.8" cy="13.4" r="0.45" {p.solid}/><circle cx="19.2" cy="13.4" r="0.45" {p.solid}/>'
                f'<ellipse cx="11.6" cy="15" rx="1.6" ry="1" {p.area}/><ellipse cx="24.4" cy="15" rx="1.6" ry="1" {p.area}/>')
    hands = lambda p: (f'<ellipse cx="8.4" cy="22.6" rx="2.6" ry="1.7" transform="rotate(-35 8.4 22.6)" {p.area}/>'
                       f'<ellipse cx="27.6" cy="22.6" rx="2.6" ry="1.7" transform="rotate(35 27.6 22.6)" {p.area}/>')
    return tw_page("1f423", drop=(2,), between={1: spikes, 5: face}, over=hands, flip=False, box=(0.6, -2.8, 35.4, 36.0), **k)


ANIMALS = {
    "elephant": ("zoo", elephant), "giraffe": ("zoo", giraffe), "lion": ("zoo", lion),
    "panda": ("zoo", panda), "zebra": ("zoo", zebra), "monkey": ("zoo", monkey),
    "clownfish": ("aquarium", clownfish), "octopus": ("aquarium", octopus), "turtle": ("aquarium", turtle),
    "whale": ("aquarium", whale), "jellyfish": ("aquarium", jellyfish), "crab": ("aquarium", crab),
    "trex": ("dinoPark", trex), "triceratops": ("dinoPark", triceratops), "brachiosaurus": ("dinoPark", brachiosaurus),
    "stegosaurus": ("dinoPark", stegosaurus), "pterosaur": ("dinoPark", pterosaur), "babyDino": ("dinoPark", baby_dino),
}
