"""The zoo and the aquarium: creature coloring pages, their outlines and the scenes.

Each creature is a coloring page (black lines on white, 600 x 800, every
area closed) drawn facing right with nothing else on the page, so the app
can cut the colored creature out (everything outside its outline is the
page's outside region) and let it roam its scene.

    python3 export_art.py   # writes assets/pages/<id>.png, art/creatures/, art/scenes/
"""
import math

from festivals import PAGE_H, PAGE_W

INK = "#222222"


def page(body, defs=""):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" height="{PAGE_H}" viewBox="0 0 {PAGE_W} {PAGE_H}">'
            f'<defs>{defs}</defs><rect width="{PAGE_W}" height="{PAGE_H}" fill="#FFFFFF"/>'
            f'<g fill="#FFFFFF" stroke="{INK}" stroke-width="9" stroke-linejoin="round" stroke-linecap="round">{body}</g></svg>')


def eye(x, y, r=11):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}" stroke="none"/><circle cx="{x + r * 0.35:.1f}" cy="{y - r * 0.35:.1f}" r="{r * 0.32:.1f}" fill="#FFFFFF" stroke="none"/>'


def ribbon(points, w0, w1=None):
    """A closed band of width 2*w along a polyline (tentacles, legs, tails)."""
    w1 = w0 if w1 is None else w1
    left, right = [], []
    n = len(points)
    for i, (x, y) in enumerate(points):
        ax, ay = points[max(i - 1, 0)]
        bx, by = points[min(i + 1, n - 1)]
        dx, dy = bx - ax, by - ay
        d = math.hypot(dx, dy) or 1
        nx, ny = -dy / d, dx / d
        w = w0 + (w1 - w0) * i / (n - 1)
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    pts = left + right[::-1]
    return '<path d="M' + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts) + ' Z"/>'


def wave(x0, y0, x1, y1, amp, waves, n=40):
    out = []
    for i in range(n + 1):
        t = i / n
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        dx, dy = x1 - x0, y1 - y0
        d = math.hypot(dx, dy)
        nx, ny = -dy / d, dx / d
        off = amp * math.sin(t * waves * 2 * math.pi) * min(1, t * 3)
        out.append((x + nx * off, y + ny * off))
    return out


def legs(xs, top, bottom, w=48, r=16):
    return "".join(f'<rect x="{x}" y="{top}" width="{w}" height="{bottom - top}" rx="{r}"/>' for x in xs)


def scallop(cx, cy, r, bumps, depth):
    """A flower-like outline: a mane, a cloud."""
    pts = []
    for k in range(bumps):
        a0 = 2 * math.pi * k / bumps
        a1 = 2 * math.pi * (k + 0.5) / bumps
        pts.append((cx + r * math.cos(a0), cy + r * math.sin(a0), cx + (r + depth) * math.cos(a1), cy + (r + depth) * math.sin(a1)))
    d = f"M{pts[0][0]:.1f} {pts[0][1]:.1f}"
    for k in range(bumps):
        _, _, qx, qy = pts[k]
        nx, ny, _, _ = pts[(k + 1) % bumps]
        d += f" Q{qx:.1f} {qy:.1f} {nx:.1f} {ny:.1f}"
    return f'<path d="{d} Z"/>'


# ---------------------------------------------------------------- the zoo


def elephant():
    return page(
        ribbon(wave(130, 430, 80, 520, 8, 1), 9) + '<ellipse cx="76" cy="528" rx="16" ry="20"/>'
        + legs([150, 215, 335, 400], 500, 650, 56, 20)
        + '<ellipse cx="290" cy="450" rx="185" ry="135"/>'
        + '<ellipse cx="392" cy="362" rx="92" ry="112"/>'
        + '<path d="M506 392 C 548 470, 566 548, 522 600 C 506 616, 480 606, 488 588 C 520 546, 500 490, 462 430 Z"/>'
        + '<circle cx="452" cy="338" r="100"/>'
        + '<path d="M392 342 C 400 300, 428 286, 446 300" fill="none"/>'
        + eye(484, 318, 12)
        + '<path d="M470 404 C 482 430, 470 446, 448 450 C 460 438, 462 422, 458 408 Z"/>')


def giraffe():
    body = '<ellipse cx="300" cy="470" rx="170" ry="95"/>'
    clip = '<clipPath id="gb"><ellipse cx="300" cy="470" rx="170" ry="95"/></clipPath><clipPath id="gn"><path d="M372 440 L436 150 L506 166 L470 452 Z"/></clipPath>'
    spots_body = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}"/>' for x, y, rx, ry in
                         [(220, 440, 34, 26), (300, 520, 38, 26), (380, 450, 32, 26), (170, 515, 24, 22), (300, 412, 26, 20)])
    spots_neck = ''.join(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}"/>' for x, y, rx, ry in [(452, 340, 22, 28), (472, 240, 18, 24)])
    return page(
        ribbon(wave(140, 450, 100, 560, 6, 1), 8) + '<ellipse cx="96" cy="570" rx="14" ry="20"/>'
        + legs([160, 218, 340, 398], 520, 740, 42, 16)
        + body + f'<g clip-path="url(#gb)">{spots_body}</g>'
        + '<path d="M372 440 L436 150 L506 166 L470 452 Z"/>' + f'<g clip-path="url(#gn)">{spots_neck}</g>'
        + '<path d="M462 104 L452 56 M512 100 L520 52" fill="none"/><circle cx="450" cy="46" r="20"/><circle cx="522" cy="42" r="20"/>'
        + '<ellipse cx="432" cy="112" rx="34" ry="16" transform="rotate(-24 432 112)"/>'
        + '<ellipse cx="506" cy="140" rx="76" ry="48"/>'
        + eye(512, 128, 11) + f'<circle cx="566" cy="152" r="5" fill="{INK}" stroke="none"/>', clip)


def lion():
    return page(
        ribbon(wave(130, 450, 70, 360, 10, 1), 9) + '<ellipse cx="64" cy="340" rx="26" ry="32"/>'
        + legs([160, 222, 344, 406], 520, 650, 52, 18)
        + '<ellipse cx="300" cy="470" rx="175" ry="112"/>'
        + scallop(440, 320, 128, 12, 44)
        + '<circle cx="374" cy="230" r="28"/><circle cx="506" cy="230" r="28"/>'
        + '<circle cx="440" cy="320" r="98"/>'
        + '<ellipse cx="440" cy="370" rx="52" ry="38"/>'
        + f'<path d="M424 344 H456 L440 362 Z" fill="{INK}"/>'
        + '<path d="M440 362 V378 M440 378 Q 424 392 412 382 M440 378 Q 456 392 468 382" fill="none"/>'
        + eye(404, 306, 12) + eye(476, 306, 12))


def panda():
    return page(
        '<rect x="452" y="300" width="34" height="320" rx="12"/><path d="M452 400 H486 M452 500 H486" fill="none"/>'
        '<path d="M486 360 C 520 330, 548 340, 560 352 C 530 360, 506 372, 486 384 Z"/>'
        + '<ellipse cx="300" cy="520" rx="165" ry="150"/>'
        + '<ellipse cx="300" cy="555" rx="98" ry="100"/>'
        + '<ellipse cx="190" cy="665" rx="68" ry="46"/><ellipse cx="410" cy="665" rx="68" ry="46"/>'
        + '<ellipse cx="160" cy="470" rx="46" ry="82" transform="rotate(22 160 470)"/>'
        + '<ellipse cx="446" cy="440" rx="46" ry="82" transform="rotate(-30 446 440)"/>'
        + '<circle cx="196" cy="186" r="46"/><circle cx="404" cy="186" r="46"/>'
        + '<circle cx="300" cy="290" r="125"/>'
        + '<ellipse cx="252" cy="286" rx="36" ry="46" transform="rotate(24 252 286)"/>'
        + '<ellipse cx="348" cy="286" rx="36" ry="46" transform="rotate(-24 348 286)"/>'
        + eye(258, 284, 11) + eye(342, 284, 11)
        + f'<ellipse cx="300" cy="338" rx="20" ry="13" fill="{INK}"/>'
        + '<path d="M300 350 V362 M300 362 Q 286 376 274 366 M300 362 Q 314 376 326 366" fill="none"/>')


def zebra():
    clip = '<clipPath id="zb"><ellipse cx="290" cy="460" rx="170" ry="100"/></clipPath><clipPath id="zn"><path d="M392 430 L446 236 L524 258 L470 470 Z"/></clipPath>'
    stripes = ''.join(f'<path d="M{x} 340 C {x - 18} 410, {x + 14} 480, {x - 10} 580 L {x + 26} 580 C {x + 46} 480, {x + 16} 410, {x + 32} 340 Z"/>'
                      for x in (176, 250, 322))
    neck_stripes = ''.join(f'<path d="M380 {y} L540 {y - 40} L540 {y - 14} L380 {y + 26} Z"/>' for y in (330, 400))
    return page(
        ribbon(wave(126, 440, 90, 550, 6, 1), 8) + '<ellipse cx="86" cy="560" rx="14" ry="22"/>'
        + legs([160, 214, 340, 394], 520, 720, 40, 14)
        + '<ellipse cx="290" cy="460" rx="170" ry="100"/>' + f'<g clip-path="url(#zb)">{stripes}</g>'
        + '<path d="M392 430 L446 236 L524 258 L470 470 Z"/>' + f'<g clip-path="url(#zn)">{neck_stripes}</g>'
        + '<path d="M440 250 L412 420 L390 408 L420 236 Z"/>'
        + '<ellipse cx="478" cy="186" rx="14" ry="36" transform="rotate(-18 478 186)"/>'
        + '<ellipse cx="512" cy="272" rx="50" ry="92" transform="rotate(-36 512 272)"/>'
        + '<ellipse cx="562" cy="330" rx="38" ry="30" transform="rotate(-36 562 330)"/>'
        + eye(500, 246, 10) + f'<circle cx="570" cy="324" r="5" fill="{INK}" stroke="none"/>', clip)


def monkey():
    return page(
        '<path d="M200 600 C 80 620, 40 520, 80 460 C 108 420, 160 446, 134 476" fill="none" stroke-width="16"/>'
        + '<ellipse cx="300" cy="530" rx="125" ry="135"/>'
        + '<ellipse cx="300" cy="555" rx="78" ry="88"/>'
        + '<ellipse cx="220" cy="662" rx="56" ry="36"/><ellipse cx="380" cy="662" rx="56" ry="36"/>'
        + '<ellipse cx="186" cy="520" rx="36" ry="86" transform="rotate(24 186 520)"/>'
        + '<ellipse cx="452" cy="430" rx="34" ry="84" transform="rotate(48 452 430)"/>'
        + '<path d="M478 376 C 566 384, 596 302, 560 246 C 566 320, 536 344, 484 340 Z"/>'
        + '<ellipse cx="500" cy="372" rx="26" ry="22"/>'
        + '<circle cx="178" cy="296" r="48"/><circle cx="178" cy="296" r="24"/>'
        + '<circle cx="422" cy="296" r="48"/><circle cx="422" cy="296" r="24"/>'
        + '<circle cx="300" cy="296" r="118"/>'
        + '<path d="M300 268 C 270 226, 210 240, 216 296 C 220 350, 252 392, 300 394 C 348 392, 380 350, 384 296 C 390 240, 330 226, 300 268 Z"/>'
        + eye(266, 300, 11) + eye(334, 300, 11)
        + f'<ellipse cx="300" cy="336" rx="10" ry="6" fill="{INK}"/>'
        + '<path d="M276 354 Q 300 374 324 354" fill="none"/>')


# ---------------------------------------------------------------- the aquarium


def clownfish():
    clip = '<clipPath id="cf"><ellipse cx="320" cy="400" rx="175" ry="112"/></clipPath>'
    bands = ''.join(f'<path d="M{x} 270 C {x - 30} 340, {x + 30} 460, {x - 6} 530 L {x + 46} 530 C {x + 76} 460, {x + 20} 340, {x + 46} 270 Z"/>'
                    for x in (198, 300, 410))
    return page(
        '<path d="M160 400 L60 300 Q 34 400 60 500 Z"/>'
        '<path d="M250 300 Q 300 210 380 292 Z"/><path d="M270 500 Q 300 580 368 504 Z"/>'
        + '<ellipse cx="320" cy="400" rx="175" ry="112"/>' + f'<g clip-path="url(#cf)">{bands}</g>'
        + '<ellipse cx="340" cy="450" rx="36" ry="20" transform="rotate(24 340 450)"/>'
        + '<circle cx="452" cy="374" r="28"/>' + eye(458, 374, 13)
        + '<path d="M478 430 Q 470 444 452 442" fill="none"/>', clip)


def octopus():
    arms = []
    for k in range(8):
        x0 = 170 + k * 37
        x1 = x0 + (k - 3.5) * 34
        arms.append(ribbon(wave(x0, 430, x1, 700, 18, 1.2), 22, 12))
    return page(
        "".join(arms)
        + '<ellipse cx="300" cy="320" rx="175" ry="165"/>'
        + '<circle cx="220" cy="230" r="24"/><circle cx="372" cy="214" r="20"/><circle cx="300" cy="190" r="16"/>'
        + '<circle cx="244" cy="340" r="34"/><circle cx="356" cy="340" r="34"/>' + eye(248, 342, 15) + eye(352, 342, 15)
        + '<ellipse cx="196" cy="398" rx="24" ry="14"/><ellipse cx="404" cy="398" rx="24" ry="14"/>'
        + '<path d="M270 398 Q 300 424 330 398" fill="none"/>')


def turtle():
    clip = '<clipPath id="ts"><path d="M130 430 C 130 290, 230 240, 310 240 C 390 240, 490 290, 490 430 Z"/></clipPath>'
    plates = ('<path d="M270 300 L350 300 L380 360 L350 420 L270 420 L240 360 Z"/>'
              '<path d="M240 360 L270 420 L200 440 L150 380 L170 300 L240 300 Z" fill="none"/>'
              '<path d="M380 360 L350 420 L420 440 L470 380 L450 300 L380 300 Z" fill="none"/>'
              '<path d="M270 300 L240 240 M350 300 L380 240" fill="none"/>')
    return page(
        '<ellipse cx="400" cy="294" rx="70" ry="24" transform="rotate(-30 400 294)"/>'
        '<ellipse cx="200" cy="306" rx="50" ry="20" transform="rotate(30 200 306)"/>'
        + '<ellipse cx="520" cy="396" rx="68" ry="52"/>' + eye(544, 382, 11) + '<path d="M548 418 Q 566 424 578 410" fill="none"/>'
        + '<ellipse cx="310" cy="436" rx="190" ry="34"/>'
        + '<path d="M130 430 C 130 290, 230 240, 310 240 C 390 240, 490 290, 490 430 Z"/>' + f'<g clip-path="url(#ts)">{plates}</g>'
        + '<ellipse cx="430" cy="500" rx="88" ry="32" transform="rotate(26 430 500)"/>'
        + '<ellipse cx="180" cy="494" rx="64" ry="26" transform="rotate(-26 180 494)"/>', clip)


def whale():
    body = 'M150 410 C 150 300, 270 236, 390 236 C 510 236, 580 326, 580 410 C 580 506, 490 566, 370 566 C 260 566, 170 506, 150 410 Z'
    clip = f'<clipPath id="wb"><path d="{body}"/></clipPath>'
    return page(
        '<path d="M166 380 C 120 340, 70 300, 40 330 C 70 356, 96 384, 120 410 C 96 430, 70 460, 40 486 C 74 516, 124 478, 166 440 Z"/>'
        + '<path d="M436 236 Q 430 200 440 172" fill="none"/>'
        + '<ellipse cx="398" cy="156" rx="20" ry="28" transform="rotate(-20 398 156)"/><ellipse cx="446" cy="126" rx="18" ry="26"/>'
        + '<ellipse cx="490" cy="156" rx="20" ry="28" transform="rotate(20 490 156)"/>'
        + f'<path d="{body}"/>'
        + f'<g clip-path="url(#wb)"><path d="M120 452 C 260 560, 470 560, 620 410 L 620 640 L 120 640 Z"/>'
        + ''.join(f'<path d="M{x} {y0} L{x + 8} {y0 + 50}" fill="none"/>' for x, y0 in [(300, 520), (360, 526), (420, 518), (480, 496)]) + '</g>'
        + '<path d="M340 512 Q 372 600 432 572 Q 400 548 392 508 Z"/>'
        + eye(486, 386, 13) + '<path d="M520 440 Q 548 452 566 432" fill="none"/>'
        + '<ellipse cx="520" cy="414" rx="18" ry="10"/>', clip)


def jellyfish():
    tentacles = "".join(ribbon(wave(x, 430, x + (x - 300) * 0.25, 720, 16, 1.5), 15, 9) for x in (190, 245, 300, 355, 410))
    bell = 'M140 430 C 140 210, 460 210, 460 430' + "".join(f" q -16 26 -32 0" for _ in range(10)) + ' Z'
    return page(
        tentacles
        + f'<path d="{bell}"/>'
        + '<circle cx="230" cy="300" r="22"/><circle cx="370" cy="290" r="18"/><circle cx="300" cy="260" r="14"/>'
        + eye(258, 370, 13) + eye(342, 370, 13)
        + '<ellipse cx="212" cy="404" rx="20" ry="11"/><ellipse cx="388" cy="404" rx="20" ry="11"/>'
        + '<path d="M282 400 Q 300 416 318 400" fill="none"/>')


def crab():
    def leg(sx, k):
        x0, y0 = 300 + sx * 140, 470 + k * 34
        return ribbon([(x0, y0), (x0 + sx * 90, y0 - 20), (x0 + sx * 130, y0 + 60)], 12, 9)
    def claw(sx):
        cx = 300 + sx * 190
        arm = ribbon([(300 + sx * 110, 420), (300 + sx * 160, 340), (cx, 300)], 16, 14)
        pincer = (f'<path d="M{cx - sx * 50} 290 C {cx - sx * 70} 220, {cx} 180, {cx + sx * 50} 210 L {cx + sx * 4} 256 L {cx + sx * 64} 252'
                  f' C {cx + sx * 60} 320, {cx - sx * 10} 340, {cx - sx * 50} 290 Z"/>')
        return arm + pincer
    return page(
        "".join(leg(sx, k) for sx in (-1, 1) for k in range(3))
        + claw(-1) + claw(1)
        + '<rect x="250" y="290" width="18" height="90" rx="8"/><rect x="332" y="290" width="18" height="90" rx="8"/>'
        + '<circle cx="259" cy="282" r="28"/><circle cx="341" cy="282" r="28"/>' + eye(262, 284, 13) + eye(344, 284, 13)
        + '<ellipse cx="300" cy="480" rx="175" ry="118"/>'
        + '<circle cx="230" cy="440" r="18"/><circle cx="372" cy="436" r="16"/><circle cx="300" cy="420" r="12"/>'
        + '<ellipse cx="214" cy="500" rx="22" ry="12"/><ellipse cx="386" cy="500" rx="22" ry="12"/>'
        + '<path d="M276 500 Q 300 520 324 500" fill="none"/>')


# id -> (habitat, drawing). The app's catalog (lib/core/creatures.dart) uses the same ids.
CREATURES = {
    "elephant": ("zoo", elephant), "giraffe": ("zoo", giraffe), "lion": ("zoo", lion),
    "panda": ("zoo", panda), "zebra": ("zoo", zebra), "monkey": ("zoo", monkey),
    "clownfish": ("aquarium", clownfish), "octopus": ("aquarium", octopus), "turtle": ("aquarium", turtle),
    "whale": ("aquarium", whale), "jellyfish": ("aquarium", jellyfish), "crab": ("aquarium", crab),
}


def outline(cid, size=96):
    """The creature in soft gray lines: a card to pick it from."""
    svg = CREATURES[cid][1]()
    svg = svg.replace(f'stroke="{INK}"', 'stroke="#8C9BAD"').replace(f'fill="{INK}"', 'fill="#8C9BAD"')
    svg = svg.replace('stroke-width="9"', 'stroke-width="14"')
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


def zoo_scene():
    """A sunny zoo field: hills, a wooden fence, a pond, trees and flowers."""
    defs = ('<linearGradient id="zsky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8ED3FF"/><stop offset="1" stop-color="#E2F5FF"/></linearGradient>'
            '<pattern id="zgrass" width="22" height="22" patternUnits="userSpaceOnUse"><circle cx="5" cy="6" r="1.8" fill="#8BD07E"/><circle cx="16" cy="16" r="1.5" fill="#B6E9A6"/></pattern>')
    s = ['<rect width="1000" height="520" fill="url(#zsky)"/>',
         '<g transform="translate(820 130)"><circle r="70" fill="#FFE27A" opacity=".35"/><circle r="44" fill="#FFD23F"/></g>',
         _cloud(80, 90, 1.8), _cloud(430, 150, 1.3), _cloud(640, 60, 1.1),
         '<path d="M0 420 C 120 320, 260 330, 380 400 C 480 330, 640 310, 760 390 C 860 340, 940 350, 1000 380 V560 H0 Z" fill="#9ED99E"/>',
         '<path d="M0 470 C 160 410, 320 430, 480 470 C 640 420, 820 420, 1000 460 V560 H0 Z" fill="#86CF86"/>']
    s += [_tree(x, 500, r, c) for x, r, c in [(60, 46, "#4DB860"), (170, 38, "#58C46B"), (300, 44, "#4DB860"), (700, 42, "#58C46B"),
                                               (820, 48, "#4DB860"), (940, 40, "#58C46B")]]
    # the field and its back fence
    s.append('<rect y="520" width="1000" height="480" fill="#A6DE97"/><rect y="520" width="1000" height="480" fill="url(#zgrass)"/>')
    s.append('<rect y="536" width="1000" height="9" fill="#D9B27D"/><rect y="566" width="1000" height="9" fill="#D9B27D"/>')
    s.append("".join(f'<rect x="{x}" y="520" width="12" height="70" rx="4" fill="#E8C79A" stroke="#B9935E" stroke-width="1.5"/>' for x in range(14, 1000, 66)))
    # a sandy path, a pond, rocks, flowers, a hay pile
    s.append('<path d="M-20 1000 C 180 860, 360 800, 520 790 C 700 780, 860 720, 1020 690 L1020 760 C 860 790, 720 850, 540 860 C 380 870, 240 930, 120 1000 Z" fill="#F3E1BD"/>')
    s.append('<ellipse cx="800" cy="640" rx="150" ry="48" fill="#7CCFFF" stroke="#43A9E0" stroke-width="3"/>'
             '<path d="M720 636 q10 -6 20 0 M830 650 q10 -6 20 0" stroke="#D8F3FF" stroke-width="4" fill="none" stroke-linecap="round"/>')
    s.append('<ellipse cx="170" cy="640" rx="60" ry="30" fill="#B9C3CF"/><ellipse cx="220" cy="650" rx="40" ry="22" fill="#A5B1C0"/>')
    s.append('<ellipse cx="470" cy="610" rx="56" ry="26" fill="#F7D36B"/><path d="M430 604 l14 -12 M460 600 l10 -14 M492 604 l12 -12" stroke="#E0A21C" stroke-width="3"/>')
    for fx, fy, c in [(90, 760, "#FF8FB1"), (120, 780, "#FFD166"), (920, 860, "#FFFFFF"), (880, 900, "#FF8FB1"), (360, 960, "#FFD166"), (620, 940, "#FF8FB1")]:
        s.append(f'<circle cx="{fx}" cy="{fy}" r="9" fill="{c}"/><circle cx="{fx}" cy="{fy}" r="3.5" fill="#FFB020"/>')
    s.append(_tree(30, 990, 70, "#4DB860") + _tree(985, 980, 64, "#58C46B"))
    return _scene("".join(s), defs)


def aquarium_scene():
    """Inside the big tank: light from above, sand, seaweed, coral, bubbles."""
    defs = ('<linearGradient id="water" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#9BE6FF"/><stop offset=".45" stop-color="#3FA8E8"/>'
            '<stop offset="1" stop-color="#1F64B4"/></linearGradient>'
            '<pattern id="sand" width="20" height="20" patternUnits="userSpaceOnUse"><circle cx="5" cy="6" r="1.6" fill="#E9C77E"/><circle cx="15" cy="15" r="1.3" fill="#FFF1C9"/></pattern>')
    s = ['<rect width="1000" height="1000" fill="url(#water)"/>']
    s += [f'<path d="M{x} 0 L{x + w} 0 L{x + w + 160} 900 L{x + 120} 900 Z" fill="#FFFFFF" opacity=".08"/>' for x, w in [(80, 60), (330, 90), (620, 70), (860, 50)]]
    s.append('<path d="M0 800 C 90 720, 180 740, 240 790 C 300 740, 380 720, 440 780 L440 900 H0 Z" fill="#2C79C2" opacity=".55"/>'
             '<path d="M600 790 C 680 700, 800 720, 860 770 C 910 740, 970 740, 1000 760 V900 H600 Z" fill="#2C79C2" opacity=".55"/>')
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

    def coral(x, y, color, s=1.0):
        branches = [(0, 0, 0, -80), (0, -40, -36, -86), (0, -50, 34, -98), (-36, -86, -50, -118), (34, -98, 46, -130)]
        return f'<g transform="translate({x} {y}) scale({s})">' + "".join(
            f'<path d="M{a} {b} L{c} {d}" stroke="{color}" stroke-width="18" stroke-linecap="round"/>' for a, b, c, d in branches) + '</g>'
    s.append(coral(270, 900, "#FF8FB1") + coral(740, 900, "#FF9447", 1.2) + coral(600, 905, "#B79CFF", 0.8))
    s.append('<g transform="translate(400 940)"><path d="M0 0 l8 -22 l8 22 l22 0 l-18 13 l7 22 l-19 -13 l-19 13 l7 -22 l-18 -13 z" fill="#FF8A3D" stroke="#D9692A" stroke-width="2"/></g>')
    s.append('<g transform="translate(840 950)"><path d="M-22 0 a22 22 0 0 1 44 0 z" fill="#FFF4E2" stroke="#E6D3B3" stroke-width="2"/>'
             '<path d="M0 0 V-20 M-12 0 L-8 -17 M12 0 L8 -17" stroke="#E6D3B3" stroke-width="2"/></g>')
    s += [f'<circle cx="{x}" cy="{y}" r="{r}" fill="none" stroke="#FFFFFF" stroke-width="3" opacity=".6"/>'
          for x, y, r in [(180, 600, 10), (196, 560, 6), (170, 520, 8), (720, 420, 12), (740, 380, 7), (520, 260, 9), (536, 226, 5), (880, 640, 8)]]
    return _scene("".join(s), defs)


SCENES = {"zoo": zoo_scene, "aquarium": aquarium_scene}
