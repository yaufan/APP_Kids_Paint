"""The 70 characters of the places you can go into, in kawaii.py's
coloring-book style. Each is a function returning SVG parts in page
coordinates (600 x 800), drawn back to front: animals mostly facing you,
what moves sideways facing right. The ground is around y = 700.
"""
import re

from kawaii import (BLUE, BROWN, CREAM, DARK, DETAIL, GRAY, GREEN, INK, LEAF, ORANGE, OUTLINE, PINK, PURPLE, RED, SKY, WHITE, YELLOW,
                    cheek, circle, ellipse, eye, line, mirror, nostril, rect, scallop, shape, smile, tube)

CHARACTERS = {}


def character(fn):
    CHARACTERS[fn.__name__] = fn
    return fn


def clip(name, area, parts):
    """[parts] drawn only inside [area] (a zebra's stripes on its body)."""
    return f'<defs><clipPath id="{name}">{area}</clipPath></defs><g clip-path="url(#{name})">{"".join(parts)}</g>'


def outline(part):
    """[part]'s outline again, over what was drawn inside it."""
    return re.sub(r'fill="[^"]*"', 'fill="none"', part, count=1)


def leg(x, y, w, h, fill, toes=True):
    """A chunky leg from its top-left corner, with a foot line."""
    parts = [rect(x, y, w, h, w * 0.45, fill)]
    if toes:
        parts.append(line(f"M{x + 10} {y + h - 26} Q {x + w / 2} {y + h - 34} {x + w - 10} {y + h - 26}"))
    return "".join(parts)


# ---------------------------------------------------------------- the zoo


@character
def elephant():
    skin, ear = GRAY, "#97A5B9"
    ears = [ellipse(150, 300, 100, 122, skin, rot=-10), ellipse(156, 304, 66, 88, PINK, w=DETAIL, rot=-10)]
    return [
        rect(212, 610, 76, 92, 32, skin), rect(312, 610, 76, 92, 32, skin),
        line("M222 676 Q 250 668 278 676 M322 676 Q 350 668 378 676"),
        ellipse(300, 560, 128, 112, skin),
        ellipse(186, 560, 34, 52, ear, rot=20), ellipse(414, 560, 34, 52, ear, rot=-20),
        *ears, mirror(ears),
        circle(300, 318, 150, skin),
        tube("M300 372 C 300 440, 298 482, 342 490", 50, skin),
        line("M282 420 h 36 M284 450 h 32", w=5),
        eye(244, 296, 17), eye(356, 296, 17),
        cheek(214, 352), cheek(386, 352),
    ]


@character
def giraffe():
    coat, spot = YELLOW, "#E8A04A"
    spots = [ellipse(x, y, rx, ry, spot, w=DETAIL) for x, y, rx, ry in
             ((262, 420, 18, 14), (334, 452, 16, 13), (290, 500, 14, 12), (230, 590, 26, 20), (360, 570, 28, 20), (296, 640, 22, 16))]
    horn = [tube("M262 168 L 250 112", 18, coat), circle(248, 104, 20, BROWN)]
    ear = [ellipse(176, 210, 50, 22, coat, rot=-24)]
    return [
        rect(218, 612, 70, 92, 30, coat), rect(312, 612, 70, 92, 30, coat),
        rect(218, 676, 70, 28, 12, BROWN), rect(312, 676, 70, 28, 12, BROWN),
        ellipse(300, 572, 126, 104, coat),
        rect(250, 330, 100, 220, 40, coat),
        *spots,
        *horn, mirror(horn), *ear, mirror(ear),
        ellipse(300, 250, 128, 112, coat),
        ellipse(300, 304, 72, 48, CREAM),
        nostril(282, 300), nostril(318, 300),
        eye(248, 238, 17), eye(352, 238, 17),
        cheek(214, 286), cheek(386, 286),
        smile(300, 326, 26, 8),
    ]


@character
def lion():
    coat, mane, muzzle = "#FFC95C", "#E8923A", CREAM
    ear = [circle(214, 212, 32, coat), circle(214, 212, 16, PINK, w=DETAIL)]
    return [
        tube("M404 626 Q 486 624 474 540", 14, coat), circle(472, 526, 26, mane),
        ellipse(300, 572, 118, 112, coat),
        ellipse(300, 600, 66, 70, muzzle, w=DETAIL),
        ellipse(242, 684, 50, 26, coat), ellipse(358, 684, 50, 26, coat),
        line("M228 682 v -12 M244 684 v -14 M342 684 v -14 M358 682 v -12", w=5),
        shape(scallop(300, 300, 152, 188, 14), mane),
        *ear, mirror(ear),
        circle(300, 304, 118, coat),
        ellipse(300, 352, 58, 40, muzzle, w=DETAIL),
        ellipse(300, 334, 18, 12, BROWN, w=5),
        line("M300 346 V 360 M300 360 Q 286 374 274 366 M300 360 Q 314 374 326 366", w=5),
        eye(252, 288, 16), eye(348, 288, 16),
        cheek(222, 334), cheek(378, 334),
    ]


@character
def panda():
    black = "#3A3A46"
    return [
        ellipse(300, 520, 150, 160, WHITE),
        tube("M450 640 L 470 300", 34, GREEN),
        line("M452 560 H 466 M458 450 H 472 M463 360 H 477", w=DETAIL),
        shape("M470 330 C 520 300 545 310 560 330 C 525 350 495 348 470 330 Z", LEAF),
        shape("M466 420 C 420 395 400 400 390 418 C 420 440 450 438 466 420 Z", LEAF),
        ellipse(200, 655, 66, 52, black), ellipse(400, 655, 66, 52, black),
        ellipse(200, 662, 30, 24, PINK, w=DETAIL), ellipse(400, 662, 30, 24, PINK, w=DETAIL),
        ellipse(178, 500, 50, 90, black, rot=20),
        ellipse(425, 495, 50, 90, black, rot=-30),
        circle(208, 190, 44, black), circle(392, 190, 44, black),
        circle(300, 290, 128, WHITE),
        ellipse(252, 292, 34, 44, black, rot=28), ellipse(348, 292, 34, 44, black, rot=-28),
        circle(256, 290, 20, WHITE, w=0), circle(344, 290, 20, WHITE, w=0),
        eye(256, 290, 14), eye(344, 290, 14),
        cheek(225, 345), cheek(375, 345),
        ellipse(300, 335, 18, 12, INK, w=0),
        line("M300 346 V 360 M282 362 Q 291 372 300 360 Q 309 372 318 362"),
    ]


@character
def zebra():
    black, coat, nose = "#3A3A46", WHITE, "#B8BCC8"
    head = ellipse(300, 272, 118, 132, coat)
    body = ellipse(300, 580, 118, 106, coat)
    head_stripes = [tube(f"M{x} 140 Q {x + 8} 190 {x} 230", 18, black) for x in (250, 300, 350)]
    body_stripes = [tube(f"M{x} 470 Q {x - 16} 580 {x + 4} 690", 20, black) for x in (210, 260, 340, 390)]
    ear = [ellipse(200, 168, 26, 48, coat, rot=-30), ellipse(202, 170, 12, 28, PINK, w=DETAIL, rot=-30)]
    return [
        rect(220, 620, 66, 84, 26, coat), rect(314, 620, 66, 84, 26, coat),
        rect(220, 680, 66, 24, 10, black), rect(314, 680, 66, 24, 10, black),
        body, clip("zebra-body", body, body_stripes), outline(body),
        rect(256, 360, 88, 150, 36, coat),
        clip("zebra-neck", '<rect x="256" y="360" width="88" height="150" rx="36"/>',
             [tube(f"M256 {y} L 344 {y + 14}", 16, black) for y in (420, 466)]),
        rect(256, 360, 88, 150, 36, "none"),
        *ear, mirror(ear),
        shape(scallop(300, 128, 26, 44, 6), black),
        head, clip("zebra-head", head, head_stripes), outline(head),
        ellipse(300, 352, 84, 56, nose),
        nostril(276, 346, 6), nostril(324, 346, 6),
        eye(248, 262, 17), eye(352, 262, 17),
        cheek(212, 310), cheek(388, 310),
        smile(300, 374, 26, 8),
    ]


@character
def monkey():
    fur, face = BROWN, "#F6D2A6"
    head = [
        circle(182, 322, 48, fur), circle(418, 322, 48, fur),
        circle(182, 322, 28, face, w=DETAIL), circle(418, 322, 28, face, w=DETAIL),
        circle(300, 315, 118, fur),
        shape("M300 262 C 252 230 196 260 206 322 C 212 382 252 414 300 418 C 348 414 388 382 394 322 C 404 260 348 230 300 262 Z", face),
        line("M285 200 Q 295 170 320 180"),
        eye(265, 318, 15), eye(335, 318, 15),
        cheek(236, 364), cheek(364, 364),
        nostril(292, 358, 4), nostril(308, 358, 4),
        smile(300, 376, 40, 12),
    ]
    return [
        tube("M380 620 C 470 640 525 560 488 500 C 462 462 422 486 442 515", 24, fur),
        ellipse(300, 545, 108, 122, fur),
        ellipse(300, 570, 66, 78, face, w=DETAIL),
        ellipse(228, 672, 52, 30, fur), ellipse(372, 672, 52, 30, fur),
        tube("M218 480 Q 178 560 222 620", 40, fur), tube("M382 480 Q 422 560 378 620", 40, fur),
        circle(226, 626, 24, face), circle(374, 626, 24, face),
        *head,
    ]


# ---------------------------------------------------------------- the aquarium


@character
def clownfish():
    body = ellipse(310, 400, 165, 112, ORANGE)
    bands = [tube("M245 280 Q 225 400 250 520", 46, WHITE), tube("M380 285 Q 360 400 385 515", 40, WHITE)]
    return [
        shape("M160 400 C 100 320 60 330 75 400 C 60 470 100 480 160 400 Z", ORANGE),
        shape("M235 305 C 265 215 370 215 400 305 Z", ORANGE),
        shape("M265 495 C 285 565 345 565 360 495 Z", ORANGE),
        body,
        clip("clownfish-body", body, bands), outline(body),
        ellipse(320, 445, 34, 18, ORANGE, w=DETAIL, rot=25),
        eye(430, 375, 18),
        cheek(452, 425),
        smile(462, 422, 22, 7),
    ]


@character
def octopus():
    color = "#B48CFF"
    arms = [
        tube("M215 400 C 150 470 130 560 175 600 C 205 625 225 590 200 570", 42, color),
        tube("M255 420 C 225 520 230 620 280 640 C 305 650 312 615 290 605", 42, color),
        tube("M345 420 C 375 520 370 620 320 640 C 295 650 288 615 310 605", 42, color),
        tube("M385 400 C 450 470 470 560 425 600 C 395 625 375 590 400 570", 42, color),
    ]
    return [
        *arms,
        ellipse(300, 300, 160, 150, color),
        circle(220, 220, 20, "#D7C2FF", w=DETAIL), circle(370, 190, 14, "#D7C2FF", w=DETAIL), circle(395, 245, 10, "#D7C2FF", w=DETAIL),
        eye(250, 330, 19), eye(350, 330, 19),
        cheek(215, 375), cheek(385, 375),
        smile(300, 375, 36, 12),
    ]


@character
def turtle():
    skin, shell, patch, rim = "#8CD47E", "#5FAF62", "#9AD58A", CREAM
    foot = [ellipse(140, 632, 52, 30, skin, rot=-20)]
    return [
        *foot, mirror(foot),
        shape("M84 590 C 84 160 516 160 516 590 Z", shell),
        ellipse(300, 330, 66, 44, patch, w=DETAIL),
        ellipse(168, 456, 42, 48, patch, w=DETAIL), ellipse(432, 456, 42, 48, patch, w=DETAIL),
        shape("M74 590 H 526 Q 518 632 484 632 H 116 Q 82 632 74 590 Z", rim),
        circle(300, 556, 122, skin),
        eye(254, 540, 16), eye(346, 540, 16),
        cheek(216, 592), cheek(384, 592),
        smile(300, 596, 36, 10),
        ellipse(226, 688, 44, 22, skin), ellipse(374, 688, 44, 22, skin),
    ]


@character
def whale():
    color = "#5DA9F5"
    body = shape("M120 390 C 150 255 400 225 500 330 C 565 395 540 485 460 505 C 360 530 200 515 120 390 Z", color)
    return [
        tube("M120 390 L 90 380", 40, color),
        shape("M95 380 C 40 310 15 345 45 385 C 15 425 40 455 95 390 Z", color),
        body,
        clip("whale-body", body, [shape("M150 455 C 280 525 450 510 545 420 L 580 600 L 100 600 Z", CREAM)]),
        outline(body),
        line("M250 478 Q 330 500 420 482", w=DETAIL), line("M290 500 Q 350 512 410 500", w=DETAIL),
        ellipse(335, 455, 52, 24, color, rot=25),
        tube("M395 250 Q 395 205 375 170", 12, SKY), tube("M405 250 Q 410 205 435 175", 12, SKY),
        circle(368, 160, 14, SKY, w=DETAIL), circle(440, 165, 14, SKY, w=DETAIL), circle(402, 140, 12, SKY, w=DETAIL),
        eye(455, 375, 17),
        cheek(483, 418),
        smile(500, 425, 24, 8),
    ]


@character
def jellyfish():
    color = "#FF9EC7"
    return [
        *[tube(f"M{x} 390 C {x - 30} 450 {x + 30} 520 {x} 580 C {x - 20} 620 {x + 10} 650 {x} 670", 18, "#FFC2DC")
          for x in (215, 260, 300, 340, 385)],
        shape("M165 365 Q 185 400 210 370 Q 232 405 255 372 Q 278 408 300 374 Q 322 408 345 372 Q 368 405 390 370 Q 415 400 435 365 Z", "#FFC2DC"),
        shape("M160 370 C 160 180 440 180 440 370 Z", color),
        ellipse(225, 255, 22, 14, WHITE, w=DETAIL, rot=-30),
        eye(258, 305, 17), eye(342, 305, 17),
        cheek(222, 342), cheek(378, 342),
        smile(300, 340, 30, 10),
    ]


@character
def crab():
    color = RED
    legs = [tube(d, 22, color) for d in (
        "M190 480 Q 120 480 100 550", "M195 520 Q 130 540 125 600", "M215 555 Q 170 590 175 640",
        "M410 480 Q 480 480 500 550", "M405 520 Q 470 540 475 600", "M385 555 Q 430 590 425 640")]
    claw = [
        tube("M210 410 Q 160 360 150 300", 32, color),
        ellipse(140, 270, 62, 52, color, rot=-20),
        shape("M95 245 C 85 200 120 175 150 190 C 135 215 125 235 118 262 Z", color),
    ]
    return [
        *legs,
        *claw,
        mirror(claw),
        tube("M262 390 L 255 315", 16, color), tube("M338 390 L 345 315", 16, color),
        ellipse(300, 470, 155, 108, color),
        circle(252, 300, 30, WHITE), circle(348, 300, 30, WHITE),
        eye(254, 303, 16), eye(346, 303, 16),
        cheek(225, 490), cheek(375, 490),
        smile(300, 490, 60, 16),
    ]


# ---------------------------------------------------------------- the dinosaur park


def teeth(x, y, gap=16):
    """Two little white teeth hanging from the top of an open mouth."""
    return "".join(shape(f"M{x + dx - 7} {y} L {x + dx} {y + 11} L {x + dx + 7} {y} Z", WHITE, w=3) for dx in (-gap, gap))


@character
def trex():
    skin, belly = "#7ED37F", CREAM
    arm = [ellipse(212, 548, 34, 17, skin, rot=-30)]
    foot = [ellipse(238, 680, 56, 28, skin), line("M216 668 v 12 M238 666 v 14 M260 668 v 12", w=5)]
    return [
        shape("M380 640 C 470 640 520 590 548 500 C 566 560 552 640 480 676 C 440 694 400 690 370 676 Z", skin),
        shape("M228 238 L 244 182 L 272 218 L 300 160 L 328 218 L 356 182 L 372 238 Z", ORANGE),
        ellipse(300, 572, 114, 112, skin),
        ellipse(300, 598, 66, 72, belly, w=DETAIL),
        *arm, mirror(arm),
        *foot, mirror(foot),
        ellipse(300, 336, 160, 130, skin),
        nostril(282, 338), nostril(318, 338),
        eye(232, 310, 17), eye(368, 310, 17),
        cheek(196, 370), cheek(404, 370),
        smile(300, 380, 50, 14), teeth(300, 378, 18),
    ]


@character
def triceratops():
    skin, frill, horn = "#F4A259", "#FFC861", CREAM
    brow = [shape("M232 236 C 214 196 196 164 168 140 C 214 146 252 180 268 226 Z", horn)]
    foot = [rect(212, 612, 74, 90, 32, skin), line("M224 676 Q 249 668 274 676")]
    return [
        tube("M396 630 Q 476 640 508 584", 40, skin),
        *foot, mirror(foot),
        ellipse(300, 580, 122, 100, skin),
        ellipse(300, 604, 70, 62, "#FFD2A0", w=DETAIL),
        shape(scallop(300, 300, 170, 204, 14), frill),
        *[circle(300 + 146 * c, 300 + 146 * s, 14, "#FFE3A8", w=DETAIL) for c, s in
          ((-0.94, -0.34), (-0.6, -0.8), (0, -1), (0.6, -0.8), (0.94, -0.34))],
        *brow, mirror(brow),
        ellipse(300, 330, 138, 120, skin),
        ellipse(300, 392, 84, 50, "#FFC28A", w=DETAIL),
        shape("M284 362 C 286 338 294 320 300 306 C 306 320 314 338 316 362 Z", horn, w=DETAIL),
        nostril(276, 384), nostril(324, 384),
        eye(240, 306, 17), eye(360, 306, 17),
        cheek(196, 360), cheek(404, 360),
        smile(300, 408, 40, 11),
    ]


@character
def brachiosaurus():
    skin, back, spot = "#7CC9B5", "#69B6A2", "#A6E0D0"
    behind = [rect(170, 604, 62, 94, 28, back)]
    front = [rect(222, 612, 70, 92, 30, skin), line("M234 676 Q 257 668 280 676")]
    return [
        tube("M404 640 Q 506 650 534 578", 40, skin),
        *behind, mirror(behind),
        ellipse(300, 584, 138, 100, skin),
        circle(198, 568, 16, spot, w=DETAIL), circle(402, 568, 16, spot, w=DETAIL), circle(372, 622, 12, spot, w=DETAIL),
        *front, mirror(front),
        rect(254, 250, 92, 300, 44, skin),
        circle(284, 420, 13, spot, w=DETAIL), circle(318, 486, 11, spot, w=DETAIL),
        ellipse(300, 116, 52, 40, skin),
        ellipse(300, 206, 126, 100, skin),
        eye(248, 196, 16), eye(352, 196, 16),
        cheek(210, 242), cheek(390, 242),
        smile(300, 252, 36, 10),
    ]


@character
def stegosaurus():
    skin, plate = "#9BD37A", "#FF8A65"

    def plate_at(angle, length):
        p = shape(f"M300 {330 - 80} Q {300 + 44} {330 - 80 - length * 0.45} 300 {330 - 80 - length} "
                  f"Q {300 - 44} {330 - 80 - length * 0.45} 300 {330 - 80} Z", plate)
        return f'<g transform="rotate({angle} 300 330)">{p}</g>'

    foot = [rect(212, 612, 74, 90, 32, skin), line("M224 676 Q 249 668 274 676")]
    return [
        tube("M398 632 Q 476 640 506 582", 38, skin),
        shape("M500 572 L 486 524 L 520 562 Z", CREAM), shape("M518 594 L 566 578 L 524 610 Z", CREAM),
        *[plate_at(a, n) for a, n in ((-56, 112), (-28, 132), (0, 144), (28, 132), (56, 112))],
        *foot, mirror(foot),
        ellipse(300, 574, 122, 108, skin),
        ellipse(300, 604, 70, 62, "#D4F0B8", w=DETAIL),
        ellipse(300, 340, 140, 122, skin),
        eye(242, 322, 17), eye(358, 322, 17),
        cheek(200, 376), cheek(400, 376),
        smile(300, 390, 40, 11),
    ]


@character
def pterosaur():
    skin, wing = "#F4A259", "#FFC861"
    wings = [shape("M336 440 C 404 352 500 294 572 322 C 532 362 508 410 502 470 C 452 450 392 468 344 498 Z", wing),
             line("M350 456 Q 444 372 552 328", w=DETAIL)]
    return [
        *wings, mirror(wings),
        tube("M272 600 L 264 650 M328 600 L 336 650", 14, skin),
        ellipse(248, 660, 30, 14, skin), ellipse(352, 660, 30, 14, skin),
        ellipse(300, 532, 76, 90, skin),
        ellipse(300, 552, 44, 60, CREAM, w=DETAIL),
        shape("M292 220 C 256 182 214 152 168 138 C 196 182 230 218 258 242 Z", skin),
        circle(300, 330, 118, skin),
        shape("M254 372 Q 300 356 346 372 Q 334 432 300 462 Q 266 432 254 372 Z", CREAM),
        line("M262 388 Q 300 402 338 388", w=5),
        eye(248, 312, 16), eye(352, 312, 16),
        cheek(210, 366), cheek(390, 366),
    ]


@character
def babyDino():
    skin, shell = "#8FD694", CREAM
    return [
        shape("M255 290 L 270 245 L 288 285 L 305 240 L 322 283 L 338 248 L 350 292 Z", ORANGE),
        circle(300, 380, 112, skin),
        ellipse(232, 505, 26, 20, skin), ellipse(368, 505, 26, 20, skin),
        shape("M180 520 L 215 485 L 250 522 L 285 480 L 320 522 L 355 482 L 390 522 L 420 492 C 440 650 160 650 180 520 Z", shell),
        circle(240, 590, 16, "#FFE3A3", w=DETAIL), circle(345, 610, 12, "#FFE3A3", w=DETAIL), circle(300, 560, 10, "#FFE3A3", w=DETAIL),
        shape("M228 300 C 240 240 360 240 372 300 L 348 284 L 324 306 L 300 282 L 276 306 L 252 284 Z", shell),
        eye(262, 378, 17), eye(338, 378, 17),
        cheek(228, 420), cheek(372, 420),
        smile(300, 418, 32, 10),
    ]


# ---------------------------------------------------------------- the transport museum


def wheel(cx, cy, r=62):
    return circle(cx, cy, r, DARK) + circle(cx, cy, r * 0.42, GRAY)


@character
def fireTruck():
    return [
        rect(70, 360, 340, 34, 10, "#C9D2DE"),
        line("M110 362 V 392 M150 362 V 392 M190 362 V 392 M230 362 V 392 M270 362 V 392 M310 362 V 392 M350 362 V 392", w=DETAIL),
        rect(55, 400, 370, 190, 24, RED),
        rect(80, 425, 140, 110, 14, "#E9454A", sw=DETAIL), rect(240, 425, 160, 110, 14, "#E9454A", sw=DETAIL),
        circle(320, 480, 36, YELLOW, w=DETAIL), circle(320, 480, 13, ORANGE, w=DETAIL),
        rect(410, 300, 140, 290, 34, RED),
        rect(430, 322, 100, 86, 18, SKY),
        rect(445, 274, 72, 28, 12, BLUE),
        rect(55, 540, 495, 34, 12, YELLOW),
        circle(534, 508, 14, YELLOW, w=DETAIL),
        eye(458, 366, 13), eye(502, 366, 13),
        cheek(438, 446, 12, 8), cheek(522, 446, 12, 8),
        smile(480, 448, 32, 9),
        rect(532, 548, 34, 40, 10, "#C9D2DE"),
        wheel(170, 600), wheel(450, 600),
    ]


@character
def policeCar():
    return [
        rect(270, 290, 36, 30, 10, RED), rect(306, 290, 36, 30, 10, BLUE),
        shape("M170 440 L 225 318 H 402 L 474 440 Z", WHITE),
        shape("M205 432 L 245 340 H 300 V 432 Z", SKY), shape("M318 432 V 340 H 390 L 444 432 Z", SKY),
        rect(55, 425, 490, 140, 50, WHITE),
        rect(55, 480, 490, 30, 14, BLUE),
        line("M300 440 V 560", w=DETAIL),
        circle(240, 455, 14, YELLOW, w=DETAIL),
        circle(530, 455, 12, YELLOW, w=DETAIL),
        eye(348, 390, 12), eye(392, 390, 12),
        cheek(436, 450, 11, 7),
        smile(476, 452, 28, 7),
        wheel(170, 575, 56), wheel(430, 575, 56),
    ]


@character
def ambulance():
    cross = "M255 375 H 285 V 345 H 315 V 375 H 345 V 405 H 315 V 435 H 285 V 405 H 255 Z"
    return [
        rect(250, 300, 70, 28, 10, RED),
        rect(60, 325, 400, 250, 34, WHITE),
        shape("M440 325 H 470 Q 540 330 552 455 V 575 H 440 Z", WHITE),
        shape("M446 336 Q 534 340 544 446 H 446 Z", SKY),
        shape(cross, RED),
        rect(60, 470, 492, 30, 14, RED),
        circle(538, 495, 13, YELLOW, w=DETAIL),
        eye(472, 398, 11), eye(510, 398, 11),
        smile(494, 458, 24, 6),
        wheel(165, 580, 56), wheel(445, 580, 56),
    ]


@character
def bus():
    return [
        rect(45, 290, 510, 290, 42, YELLOW),
        *[rect(x, 325, 78, 85, 14, SKY, sw=DETAIL) for x in (75, 168, 261, 354)],
        shape("M455 320 H 520 Q 540 322 540 345 V 420 H 455 Z", SKY),
        rect(450, 440, 70, 120, 12, "#FFE68A", sw=DETAIL),
        line("M485 440 V 560", w=DETAIL),
        rect(45, 455, 400, 28, 12, ORANGE),
        circle(530, 490, 14, WHITE, w=DETAIL),
        eye(477, 356, 11.5), eye(517, 356, 11.5),
        smile(497, 394, 26, 7),
        wheel(160, 585, 56), wheel(420, 585, 56),
    ]


@character
def scooter():
    body = "#7CC7FF"
    return [
        tube("M430 360 L 455 560", 22, GRAY),
        shape("M100 530 C 100 430 230 420 290 470 L 400 470 L 430 520 C 420 570 150 575 100 530 Z", body),
        ellipse(205, 445, 85, 26, DARK),
        tube("M405 300 H 470", 18, DARK),
        tube("M440 305 L 425 470", 26, body),
        circle(462, 335, 18, YELLOW, w=DETAIL),
        shape("M395 520 C 410 480 500 480 512 530 Z", body),
        eye(296, 504, 12), eye(344, 504, 12),
        cheek(262, 540, 11, 7),
        smile(320, 538, 26, 7),
        wheel(160, 600, 58), wheel(455, 600, 58),
    ]


@character
def train():
    return [
        circle(470, 220, 30, WHITE), circle(510, 180, 40, WHITE), circle(455, 160, 26, WHITE),
        shape("M415 380 L 420 290 H 480 L 485 380 Z", DARK),
        rect(80, 300, 160, 250, 24, RED),
        rect(105, 325, 110, 90, 16, SKY),
        rect(220, 380, 300, 165, 70, BLUE),
        line("M300 384 V 541 M380 384 V 541", w=DETAIL),
        eye(430, 448, 12), eye(474, 448, 12),
        cheek(410, 494, 11, 8), cheek(498, 490, 11, 8),
        smile(452, 494, 30, 9),
        shape("M520 520 L 570 580 H 505 Z", GRAY),
        rect(60, 540, 470, 30, 12, DARK),
        wheel(170, 585, 58), wheel(330, 595, 46), wheel(450, 595, 46),
        line("M170 585 H 450", w=12),
    ]


@character
def airplane():
    return [
        shape("M115 350 L 85 230 H 150 L 215 345 Z", RED),
        shape("M80 385 C 80 345 120 332 160 332 H 465 C 540 332 572 372 572 400 C 572 432 540 452 465 452 H 160 C 110 452 80 425 80 385 Z", WHITE),
        *[circle(x, 380, 15, SKY, w=DETAIL) for x in (190, 245, 300, 355, 410)],
        rect(100, 412, 350, 20, 10, BLUE, sw=DETAIL),
        eye(482, 380, 11), eye(522, 380, 11),
        cheek(552, 410, 10, 7),
        smile(506, 416, 24, 7),
        shape("M245 425 H 385 L 305 575 H 230 Z", BLUE),
        ellipse(300, 470, 40, 20, GRAY, w=DETAIL),
    ]


@character
def helicopter():
    return [
        rect(120, 240, 440, 24, 12, GRAY),
        rect(320, 262, 32, 46, 8, DARK),
        tube("M200 410 L 70 380", 44, YELLOW),
        ellipse(58, 375, 14, 50, GRAY),
        shape("M180 425 C 180 335 255 305 335 305 C 445 305 500 375 500 430 C 500 490 450 520 380 520 H 260 C 210 520 180 482 180 425 Z", YELLOW),
        shape("M390 318 C 455 325 492 378 494 432 H 390 Z", SKY),
        eye(416, 382, 12), eye(458, 382, 12),
        cheek(404, 470, 11, 8), cheek(478, 466, 11, 8),
        smile(440, 466, 28, 8),
        line("M260 520 V 560 M420 520 V 560", w=10),
        tube("M200 565 H 480", 14, GRAY),
    ]


# ---------------------------------------------------------------- the botanical garden


@character
def sunflower():
    import math
    petals = []
    for k in range(14):
        a = 2 * math.pi * k / 14
        x, y = 300 + 128 * math.cos(a), 300 + 128 * math.sin(a)
        petals.append(ellipse(round(x, 1), round(y, 1), 30, 60, YELLOW, rot=round(math.degrees(a) + 90, 1)))
    return [
        tube("M300 720 C 290 620 310 520 300 420", 34, GREEN),
        shape("M300 610 C 350 560 430 550 470 580 C 430 630 350 645 300 610 Z", LEAF),
        line("M310 606 Q 390 585 455 583"),
        shape("M300 530 C 250 480 170 470 130 500 C 170 550 250 565 300 530 Z", LEAF),
        line("M290 526 Q 210 505 145 503"),
        *petals,
        circle(300, 300, 98, "#A0662F"),
        eye(268, 288, 15), eye(332, 288, 15),
        cheek(240, 326), cheek(360, 326),
        smile(300, 324, 30, 10),
    ]


@character
def tulip():
    petal = "#FF6F8E"
    return [
        tube("M300 720 C 295 640 305 560 300 470", 30, GREEN),
        shape("M298 690 C 230 650 200 560 215 470 C 270 520 300 600 298 690 Z", LEAF),
        shape("M302 670 C 370 630 395 560 385 480 C 335 525 305 595 302 670 Z", LEAF),
        shape("M190 300 C 190 230 240 210 260 260 L 300 200 L 340 260 C 360 210 410 230 410 300 C 410 420 360 470 300 470 C 240 470 190 420 190 300 Z", petal),
        line("M260 262 Q 270 330 300 372 Q 330 330 340 262", w=DETAIL),
        eye(268, 390, 13), eye(332, 390, 13),
        cheek(240, 418, 12, 8), cheek(360, 418, 12, 8),
        smile(300, 418, 24, 8),
    ]


@character
def cactus():
    skin, pot = "#7CC46E", "#E58B4D"
    return [
        tube("M248 500 H 195 V 400", 62, skin),
        tube("M352 450 H 405 V 360", 62, skin),
        tube("M300 600 V 300", 130, skin),
        shape(scallop(300, 220, 26, 38, 6), "#FF8FB1"), circle(300, 220, 12, YELLOW, w=DETAIL),
        line("M262 420 l 10 6 M330 330 l 10 -6 M325 520 l 10 6 M265 560 l 10 -6 M190 440 l 10 6 M408 400 l -10 6", w=5),
        shape("M190 600 H 410 L 385 715 H 215 Z", pot),
        rect(175, 580, 250, 48, 16, "#F2A26B"),
        eye(268, 380, 15), eye(332, 380, 15),
        cheek(242, 418, 13, 9), cheek(358, 418, 13, 9),
        smile(300, 415, 28, 9),
    ]


@character
def lotus():
    import math
    petal = "#FFA8C5"
    back = [ellipse(round(300 + 95 * math.cos(math.radians(a)), 1), round(380 + 95 * math.sin(math.radians(a)), 1), 42, 92, petal,
                    rot=a + 90) for a in (200, 240, 300, 340)]
    return [
        ellipse(300, 555, 230, 78, "#6CC070"),
        line("M300 555 L 470 510", w=DETAIL),
        *back,
        ellipse(225, 435, 44, 92, petal, rot=-45), ellipse(375, 435, 44, 92, petal, rot=45),
        ellipse(300, 300, 48, 100, petal),
        circle(300, 430, 72, YELLOW),
        eye(274, 425, 13), eye(326, 425, 13),
        cheek(250, 452, 11, 8), cheek(350, 452, 11, 8),
        smile(300, 452, 22, 7),
    ]


@character
def strawberry():
    berry, seed = "#FF5E6B", "#FFE9A8"
    seeds = [ellipse(x, y, 7, 11, seed, w=4) for x, y in
             ((220, 400), (300, 380), (380, 400), (195, 480), (405, 480), (240, 560), (360, 560), (300, 620))]
    return [
        tube("M300 260 Q 305 215 330 190", 16, GREEN),
        shape("M300 330 C 175 320 140 420 170 520 C 200 620 260 680 300 690 C 340 680 400 620 430 520 C 460 420 425 320 300 330 Z", berry),
        *seeds,
        shape("M300 255 L 340 300 L 410 290 L 360 335 L 300 350 L 240 335 L 190 290 L 260 300 Z", LEAF),
        eye(268, 470, 16), eye(332, 470, 16),
        cheek(238, 512), cheek(362, 512),
        smile(300, 510, 30, 10),
    ]


@character
def rose():
    petal = "#FF5E7A"
    return [
        tube("M300 720 C 290 640 310 560 300 450", 26, GREEN),
        shape("M300 600 C 350 560 420 555 450 585 C 410 625 345 635 300 600 Z", LEAF),
        shape("M300 530 C 250 490 180 485 150 515 C 190 555 255 565 300 530 Z", LEAF),
        shape("M295 650 L 280 640 L 297 632 Z", GREEN, w=5), shape("M305 560 L 322 552 L 305 544 Z", GREEN, w=5),
        shape(scallop(300, 340, 118, 140, 8), petal),
        shape("M200 300 C 210 215 390 215 400 300 C 360 270 240 270 200 300 Z", "#FF8096"),
        line("M262 262 Q 300 238 338 262 Q 315 285 290 270", w=DETAIL),
        eye(268, 352, 15), eye(332, 352, 15),
        cheek(238, 392), cheek(362, 392),
        smile(300, 390, 28, 9),
    ]


# ---------------------------------------------------------------- the insect museum


@character
def butterfly():
    wing = [
        shape("M305 380 C 350 210 520 160 552 255 C 575 340 480 410 305 412 Z", "#FFB347"),
        circle(470, 285, 40, YELLOW, w=DETAIL), circle(390, 355, 22, YELLOW, w=DETAIL),
        shape("M305 418 C 420 425 505 470 478 560 C 450 640 345 610 305 470 Z", "#FF8FB1"),
        circle(420, 520, 30, WHITE, w=DETAIL),
    ]
    return [
        line("M285 250 Q 250 170 215 150"), line("M315 250 Q 350 170 385 150"),
        circle(212, 146, 14, PURPLE, w=DETAIL), circle(388, 146, 14, PURPLE, w=DETAIL),
        *wing,
        mirror(wing),
        ellipse(300, 470, 34, 140, PURPLE),
        line("M272 430 Q 300 442 328 430 M270 480 Q 300 492 330 480 M276 530 Q 300 540 324 530"),
        circle(300, 300, 58, PURPLE),
        eye(278, 292, 13), eye(322, 292, 13),
        cheek(258, 322, 11, 8), cheek(342, 322, 11, 8),
        smile(300, 318, 20, 7),
    ]


@character
def ladybug():
    shell, black = RED, "#3A3A46"
    legs = [tube(d, 16, black) for d in ("M170 380 L 100 340", "M150 460 L 80 470", "M175 545 L 110 600",
                                         "M430 380 L 500 340", "M450 460 L 520 470", "M425 545 L 490 600")]
    body = circle(300, 455, 170, shell)
    spots = [circle(x, y, r, black, w=DETAIL) for x, y, r in ((225, 390, 32), (375, 390, 32), (205, 510, 28), (395, 510, 28), (255, 590, 22), (345, 590, 22))]
    return [
        *legs,
        line("M265 220 Q 240 150 205 130"), line("M335 220 Q 360 150 395 130"),
        circle(203, 127, 13, black, w=DETAIL), circle(397, 127, 13, black, w=DETAIL),
        circle(300, 265, 82, black),
        body,
        *spots,
        line("M300 290 V 622"),
        circle(270, 250, 28, WHITE, w=0), circle(330, 250, 28, WHITE, w=0),
        eye(270, 250, 13), eye(330, 250, 13),
        smile(300, 282, 22, 7),
    ]


@character
def bee():
    stripe = "#3A3A46"
    body = ellipse(265, 460, 160, 115, YELLOW)
    return [
        shape("M108 460 L 70 448 L 108 436 Z", stripe),
        ellipse(225, 300, 62, 92, "#E3F4FF", rot=-25), ellipse(320, 290, 62, 92, "#E3F4FF", rot=20),
        tube("M200 570 L 190 610 M280 575 L 280 615", 14, stripe),
        body,
        clip("bee-body", body, [tube(f"M{x} 330 Q {x - 15} 460 {x} 590", 34, stripe) for x in (175, 255)]),
        outline(body),
        line("M405 320 Q 420 250 450 230"), line("M440 335 Q 475 280 505 270"),
        circle(452, 226, 12, stripe, w=DETAIL), circle(508, 266, 12, stripe, w=DETAIL),
        circle(420, 410, 92, YELLOW),
        eye(395, 400, 16), eye(455, 398, 16),
        cheek(372, 440), cheek(480, 436),
        smile(425, 440, 30, 10),
    ]


@character
def beetle():
    shell, head, leg = "#7A5236", "#9A6A44", "#5A3E2B"
    legs = [tube(d, 16, leg) for d in ("M196 480 L 118 440 L 96 478", "M184 566 L 104 584 L 96 634", "M222 650 L 176 694")]
    return [
        *legs, mirror(legs),
        ellipse(300, 556, 150, 140, shell),
        line("M300 432 V 694"),
        ellipse(232, 520, 22, 48, "#B88A60", w=DETAIL, rot=14),
        tube("M300 250 C 300 190 282 156 300 118", 40, head),
        tube("M300 126 L 268 92 M300 126 L 332 92", 22, head),
        circle(300, 342, 116, head),
        circle(254, 334, 36, WHITE, w=0), circle(346, 334, 36, WHITE, w=0),
        eye(254, 334, 16), eye(346, 334, 16),
        cheek(212, 392), cheek(388, 392),
        smile(300, 392, 34, 10),
    ]


@character
def dragonfly():
    body, wing = "#4FC3C9", "#D9F1FF"
    wings = [ellipse(410, 330, 150, 42, wing, rot=-12), ellipse(400, 410, 135, 38, wing, rot=14)]
    return [
        *wings, mirror(wings),
        tube("M300 330 L 300 650", 36, body),
        line("M284 420 H 316 M284 480 H 316 M284 540 H 316 M284 600 H 316", w=DETAIL),
        circle(300, 230, 64, body),
        circle(266, 215, 26, WHITE), circle(334, 215, 26, WHITE),
        eye(266, 218, 13), eye(334, 218, 13),
        cheek(258, 258, 11, 8), cheek(342, 258, 11, 8),
        smile(300, 262, 20, 7),
    ]


@character
def mantis():
    skin, dark = "#8ED36B", "#6FBF50"
    legs = [tube("M262 590 L 196 640 L 184 700", 14, dark), tube("M270 630 L 240 700", 14, dark)]
    arm = [tube("M266 450 L 196 414 L 238 540", 28, skin),
           line("M206 444 L 196 456 M214 474 L 204 486 M222 504 L 212 516", w=5)]
    bump = [circle(206, 250, 50, skin)]
    return [
        *legs, mirror(legs),
        ellipse(300, 600, 78, 108, skin),
        line("M240 590 Q 300 604 360 590 M248 640 Q 300 654 352 640", w=DETAIL),
        tube("M300 400 L 300 500", 54, skin),
        line("M270 222 Q 240 132 196 106"), line("M330 222 Q 360 132 404 106"),
        *bump, mirror(bump),
        shape("M168 268 C 168 196 432 196 432 268 C 432 340 352 402 300 412 C 248 402 168 340 168 268 Z", skin),
        *arm, mirror(arm),
        eye(206, 250, 17), eye(394, 250, 17),
        cheek(232, 320, 13, 9), cheek(368, 320, 13, 9),
        smile(300, 334, 32, 9),
    ]


@character
def milk():
    carton, side, top = WHITE, "#D8E9FF", SKY
    return [
        shape("M410 330 L 470 290 L 470 660 L 410 700 Z", side),
        shape("M410 330 L 300 240 L 360 200 L 470 290 Z", "#5AAEF5"),
        shape("M292 236 L 352 196 L 352 168 L 292 208 Z", carton),
        rect(190, 330, 220, 370, 18, carton),
        shape("M190 330 L 300 240 L 410 330 Z", top),
        shape("M190 590 H 410 V 682 Q 410 700 392 700 H 208 Q 190 700 190 682 Z", top),
        shape("M300 612 C 330 650 330 676 300 676 C 270 676 270 650 300 612 Z", carton, w=DETAIL),
        eye(262, 440, 16), eye(338, 440, 16),
        cheek(232, 482), cheek(368, 482),
        smile(300, 480, 30, 10),
    ]


@character
def carrot():
    root = "#FF9442"
    return [
        ellipse(255, 245, 30, 72, LEAF, rot=-28), ellipse(345, 245, 30, 72, LEAF, rot=28), ellipse(300, 222, 32, 84, LEAF),
        shape("M190 330 Q 300 280 410 330 Q 400 520 300 720 Q 200 520 190 330 Z", root),
        line("M228 540 h 34 M338 580 h 32 M276 650 h 26"),
        eye(262, 400, 16), eye(338, 400, 16),
        cheek(232, 442), cheek(368, 442),
        smile(300, 440, 30, 10),
    ]


@character
def apple():
    skin = "#FF5E5B"
    return [
        tube("M300 330 Q 298 280 318 248", 14, BROWN),
        shape("M300 330 C 230 280 150 320 150 450 C 150 600 240 700 300 690 C 360 700 450 600 450 450 C 450 320 370 280 300 330 Z", skin),
        shape("M322 286 Q 372 232 428 258 Q 376 306 322 286 Z", LEAF),
        line("M210 400 Q 220 370 245 355", w=DETAIL),
        eye(262, 480, 16), eye(338, 480, 16),
        cheek(230, 522), cheek(370, 522),
        smile(300, 520, 30, 10),
    ]


@character
def banana():
    peel = "#FFE15A"
    return [
        tube("M150 368 L 142 318", 30, "#A9C94F"),
        shape("M115 370 C 125 680 430 740 505 455 L 470 440 C 400 520 230 520 185 365 Z", peel),
        ellipse(490, 448, 16, 12, BROWN, w=DETAIL, rot=-20),
        eye(272, 560, 15), eye(336, 556, 15),
        cheek(244, 596, 13, 9), cheek(364, 590, 13, 9),
        smile(304, 594, 26, 9),
    ]


@character
def bread():
    crust, crumb = "#D9965A", "#FFE3B3"
    return [
        shape("M170 700 V 400 C 115 380 118 262 200 250 C 240 196 360 196 400 250 C 482 262 485 380 430 400 V 700 Z", crust),
        shape("M200 672 V 388 C 158 368 165 288 222 282 C 256 238 344 238 378 282 C 435 288 442 368 400 388 V 672 Z", crumb, w=DETAIL),
        eye(262, 470, 16), eye(338, 470, 16),
        cheek(232, 512), cheek(368, 512),
        smile(300, 510, 30, 10),
    ]


@character
def iceCream():
    cone, scoop = "#F2B56B", "#FFB3C7"
    cone_d = "M205 440 L 395 440 L 300 720 Z"
    return [
        shape(cone_d, cone),
        clip("waffle", f'<path d="{cone_d}"/>', [line("M210 470 L 370 630 M250 450 L 395 595 M390 470 L 230 630 M350 450 L 205 595", w=5)]),
        outline(shape(cone_d, cone)),
        shape("M185 450 C 150 330 220 250 300 250 C 380 250 450 330 415 450 Q 398 482 375 456 Q 352 494 330 458 Q 305 494 282 458 "
              "Q 258 492 238 456 Q 214 484 185 450 Z", scoop),
        tube("M300 222 Q 302 190 322 172", 8, BROWN),
        circle(300, 236, 26, RED),
        eye(262, 360, 15), eye(338, 360, 15),
        cheek(234, 398, 13, 9), cheek(366, 398, 13, 9),
        smile(300, 396, 28, 9),
    ]


@character
def bubbleTea():
    tea, pearl = "#E9C29C", "#7A4E36"
    pearls = [circle(x, y, 17, pearl, w=5) for x, y in
              ((242, 662), (286, 670), (330, 666), (370, 652), (262, 626), (308, 632), (350, 620))]
    return [
        tube("M330 280 L 378 118", 30, PINK),
        shape("M190 336 L 410 336 L 384 700 L 216 700 Z", tea),
        *pearls,
        shape("M180 330 Q 300 205 420 330 Z", "#F4FBFF"),
        rect(170, 318, 260, 32, 15, WHITE),
        eye(262, 450, 16), eye(338, 450, 16),
        cheek(232, 492), cheek(368, 492),
        smile(300, 490, 30, 10),
    ]


@character
def pudding():
    custard, caramel, plate = "#FFE07A", "#C2733A", "#BFE3FF"
    return [
        ellipse(300, 672, 200, 40, plate),
        shape("M212 350 C 212 322 388 322 388 350 L 432 648 C 432 694 168 694 168 648 Z", custard),
        shape("M206 358 C 216 320 384 320 394 358 L 401 404 Q 386 432 364 410 Q 342 438 319 412 Q 296 438 274 412 "
              "Q 251 436 230 410 Q 211 430 199 404 Z", caramel),
        eye(262, 530, 17), eye(338, 530, 17),
        cheek(228, 574), cheek(372, 574),
        smile(300, 572, 32, 10),
    ]


# ---------------------------------------------------------------- space (0.13)


@character
def rocket():
    body, red, glass = "#F2F5FA", "#FF5E5B", "#A9E0FF"
    fin = [shape("M212 400 C 150 430, 128 500, 140 590 L 214 530 Z", red)]
    return [
        shape("M250 560 Q 300 715 350 560 Z", ORANGE), shape("M276 560 Q 300 650 324 560 Z", YELLOW, w=DETAIL),
        *fin, mirror(fin),
        rect(240, 518, 120, 46, 12, GRAY),
        shape("M300 110 C 382 175, 412 300, 402 525 L 198 525 C 188 300, 218 175, 300 110 Z", body),
        shape("M300 110 C 350 148, 378 196, 392 250 L 208 250 C 222 196, 250 148, 300 110 Z", red),
        circle(300, 345, 74, GRAY), circle(300, 345, 58, glass, w=DETAIL),
        eye(276, 338, 14), eye(324, 338, 14),
        cheek(260, 370, 11, 7), cheek(340, 370, 11, 7),
        smile(300, 368, 22, 7),
        line("M300 430 V 500"),
    ]


@character
def astronaut():
    suit, skin = WHITE, "#FFE2CC"
    return [
        rect(168, 300, 264, 250, 44, GRAY),
        tube("M218 455 Q 160 505 168 565", 52, suit), circle(170, 580, 30, SKY),
        tube("M382 455 Q 452 425 460 360", 52, suit), circle(462, 345, 30, SKY),
        rect(212, 590, 74, 112, 30, suit), rect(314, 590, 74, 112, 30, suit),
        line("M222 672 H 276 M324 672 H 378"),
        shape("M208 440 C 208 405, 392 405, 392 440 L 402 600 C 402 632, 198 632, 198 600 Z", suit),
        rect(254, 468, 92, 62, 14, SKY, sw=DETAIL), circle(280, 499, 10, RED, w=5), circle(320, 499, 10, YELLOW, w=5),
        tube("M392 196 L 424 148", 10, GRAY), circle(428, 140, 15, RED),
        circle(300, 292, 132, suit),
        ellipse(300, 300, 94, 80, skin),
        line("M232 262 Q 246 236 272 228", w=5),
        eye(266, 298, 15), eye(334, 298, 15),
        cheek(244, 330, 12, 8), cheek(356, 330, 12, 8),
        smile(300, 330, 26, 8),
    ]


@character
def alien():
    skin = "#8ED36B"
    antenna = [tube("M262 228 Q 238 168 212 136", 12, skin), circle(208, 128, 22, PINK)]
    return [
        *antenna, mirror(antenna),
        tube("M218 540 Q 160 560 150 615", 36, skin), tube("M382 540 Q 440 520 455 465", 36, skin),
        rect(236, 630, 54, 76, 26, skin), rect(310, 630, 54, 76, 26, skin),
        ellipse(300, 560, 102, 112, skin),
        ellipse(300, 572, 52, 62, "#C5EDB0", w=DETAIL),
        ellipse(300, 330, 152, 128, skin),
        eye(238, 345, 27), eye(362, 345, 27), eye(300, 282, 18),
        cheek(210, 392, 14, 9), cheek(390, 392, 14, 9),
        smile(300, 400, 46, 13),
    ]


@character
def ufo():
    saucer, dome, beam = "#B8C2D6", "#BFE3FF", "#FFF3B0"
    lights = [circle(x, y, 15, YELLOW, w=DETAIL) for x, y in ((150, 404), (224, 426), (300, 434), (376, 426), (450, 404))]
    return [
        shape("M232 450 L 368 450 L 448 700 L 152 700 Z", beam, w=DETAIL),
        ellipse(300, 440, 150, 42, "#8E9AB2"),
        ellipse(300, 400, 222, 70, saucer),
        *lights,
        shape("M186 372 C 186 222, 414 222, 414 372 Z", dome),
        line("M216 312 Q 228 272 262 254", w=5),
        eye(266, 322, 16), eye(334, 322, 16),
        cheek(246, 352, 12, 8), cheek(354, 352, 12, 8),
        smile(300, 350, 24, 8),
    ]


@character
def moon():
    gold = "#FFE27A"
    craters = [circle(x, y, r, "#F4C85A", w=DETAIL) for x, y, r in ((150, 520, 24), (232, 604, 16), (118, 258, 15))]
    return [
        shape("M342 143 A 260 260 0 1 0 488 580 A 230 230 0 0 1 342 143 Z", gold),
        *craters,
        eye(112, 378, 15), eye(162, 372, 15),
        cheek(96, 414, 12, 8), cheek(180, 404, 12, 8),
        smile(138, 418, 24, 8),
    ]


@character
def star():
    import math
    pts = []
    for k in range(10):
        a = math.radians(-90 + k * 36)
        r = 250 if k % 2 == 0 else 112
        pts.append(f"{300 + r * math.cos(a):.0f} {440 + r * math.sin(a):.0f}")
    little = []
    for k in range(10):
        a = math.radians(-90 + k * 36)
        r = 62 if k % 2 == 0 else 28
        little.append(f"{500 + r * math.cos(a):.0f} {150 + r * math.sin(a):.0f}")
    return [
        shape("M" + " L".join(little) + " Z", "#FFF1A8"),
        shape("M" + " L".join(pts) + " Z", YELLOW),
        eye(262, 432, 17), eye(338, 432, 17),
        cheek(242, 470, 13, 9), cheek(358, 470, 13, 9),
        smile(300, 468, 30, 10),
    ]


@character
def saturn():
    planet, ring = "#FF9F45", "#FFD07A"
    band = '<path d="M30 452 a 270 72 0 1 0 540 0 a 270 72 0 1 0 -540 0 Z M110 452 a 190 40 0 1 0 380 0 a 190 40 0 1 0 -380 0 Z" fill-rule="evenodd" '
    band_svg = (band + f'fill="{ring}" stroke="{INK}" stroke-width="{OUTLINE}" stroke-linejoin="round"/>')
    return [
        band_svg,
        circle(300, 400, 160, planet),
        line("M190 290 Q 300 266 410 290", w=DETAIL),
        clip("ringfront", '<rect x="0" y="452" width="600" height="348"/>', [band_svg]),
        eye(258, 352, 17), eye(342, 352, 17),
        cheek(234, 390, 13, 9), cheek(366, 390, 13, 9),
        smile(300, 388, 28, 9),
    ]


@character
def spaceCat():
    fur, suit, glass = "#FFB35C", WHITE, "#DFF3FF"
    ear = [shape("M214 300 L 222 200 L 286 262 Z", fur), shape("M228 278 L 232 226 L 266 258 Z", PINK, w=DETAIL)]
    return [
        tube("M396 612 Q 486 604 474 512", 34, fur),
        shape("M200 512 C 200 490, 400 490, 400 512 L 410 652 C 410 690, 190 690, 190 652 Z", suit),
        ellipse(240, 690, 46, 22, suit), ellipse(360, 690, 46, 22, suit),
        circle(300, 330, 172, glass),
        *ear, mirror(ear),
        ellipse(300, 352, 120, 104, fur),
        eye(260, 348, 16), eye(340, 348, 16),
        shape("M290 382 L 310 382 L 300 394 Z", PINK, w=4),
        line("M300 394 Q 288 410 276 402 M300 394 Q 312 410 324 402", w=5),
        line("M196 372 L 236 380 M196 396 L 236 392 M404 372 L 364 380 M404 396 L 364 392", w=4),
        line("M178 280 Q 188 222 232 190", w=5),
        rect(170, 474, 260, 44, 22, GRAY),
    ]


# ---------------------------------------------------------------- the night market (0.13)


@character
def friedChicken():
    import math
    bag, band, crust = "#F2DDB0", "#FF5E5B", "#E8A64C"
    # a big bumpy cutlet, wider than its paper bag
    pts = []
    for k in range(18):
        a = 2 * math.pi * k / 18
        r = 1 + 0.05 * math.sin(5 * a) + (0.05 if k % 2 else -0.02)
        pts.append((300 + 205 * r * math.cos(a), 250 + 150 * r * math.sin(a)))
    mids = [((x0 + x1) / 2, (y0 + y1) / 2) for (x0, y0), (x1, y1) in zip(pts, pts[1:] + pts[:1])]
    cutlet = f"M{mids[-1][0]:.0f} {mids[-1][1]:.0f} " + " ".join(
        f"Q {x:.0f} {y:.0f} {mx:.0f} {my:.0f}" for (x, y), (mx, my) in zip(pts, mids)) + " Z"
    return [
        shape(cutlet, crust),
        line("M200 220 l 14 10 M262 180 l 12 12 M352 176 l 10 14 M412 232 l -12 12 M190 290 l 12 -10 M420 300 l -14 -6", w=5),
        shape("M175 330 L 425 330 L 400 700 L 200 700 Z", bag),
        shape("M175 330 L 425 330 L 420 380 L 180 380 Z", band, w=DETAIL),
        eye(262, 510, 16), eye(338, 510, 16),
        cheek(232, 552), cheek(368, 552),
        smile(300, 550, 30, 10),
    ]


@character
def sausage():
    meat, stick = "#E85A4F", "#D9B07A"
    return [
        tube("M300 110 L 300 720", 18, stick),
        shape("M250 180 C 250 130, 350 130, 350 180 C 372 300, 372 420, 350 540 C 350 590, 250 590, 250 540 C 228 420, 228 300, 250 180 Z", meat),
        line("M262 250 L 338 228 M258 330 L 342 306 M260 410 L 340 386", w=DETAIL),
        eye(278, 470, 14), eye(322, 470, 14),
        cheek(258, 502, 10, 7), cheek(342, 502, 10, 7),
        smile(300, 500, 20, 7),
    ]


@character
def tanghulu():
    fruit, shine, stick = "#FF4D6A", "#FFFFFF", "#D9B07A"
    balls = [circle(300, y, 70, fruit) for y in (170, 300, 430)]
    return [
        tube("M300 120 L 300 720", 16, stick),
        *balls,
        circle(300, 560, 70, fruit),
        line("M262 132 Q 270 116 288 112 M262 262 Q 270 246 288 242 M262 392 Q 270 376 288 372", w=5),
        eye(274, 300, 14), eye(326, 300, 14),
        cheek(254, 332, 11, 7), cheek(346, 332, 11, 7),
        smile(300, 330, 22, 8),
    ]


@character
def cottonCandy():
    fluff, stick = "#FFB3D9", "#F2F5FA"
    return [
        shape("M282 430 L 318 430 L 306 720 L 294 720 Z", stick),
        shape(scallop(300, 310, 150, 190, 11), fluff),
        eye(262, 300, 17), eye(338, 300, 17),
        cheek(238, 342, 13, 9), cheek(362, 342, 13, 9),
        smile(300, 340, 30, 10),
    ]


@character
def sweetPotatoBalls():
    cup, ball, stick = "#FFF4DD", "#FFC46B", "#D9B07A"
    balls = [circle(x, y, 46, ball) for x, y in ((220, 330), (300, 300), (380, 330), (260, 250), (340, 250))]
    return [
        tube("M380 300 L 470 150", 10, stick),
        *balls,
        shape("M160 350 L 440 350 L 410 700 L 190 700 Z", cup),
        line("M176 400 H 424", w=DETAIL),
        eye(262, 520, 16), eye(338, 520, 16),
        cheek(232, 562), cheek(368, 562),
        smile(300, 560, 30, 10),
    ]


@character
def shavedIce():
    bowl, ice, syrup, mango = "#BFE3FF", WHITE, "#FF8FB1", "#FFC94A"
    cubes = [rect(x, y, 44, 38, 8, mango, sw=DETAIL) for x, y in ((232, 262), (300, 232), (350, 276))]
    return [
        rect(250, 640, 100, 50, 12, bowl),
        shape("M120 520 L 480 520 C 470 620, 400 660, 300 660 C 200 660, 130 620, 120 520 Z", bowl),
        shape("M132 520 C 150 400, 230 250, 300 232 C 370 250, 450 400, 468 520 Z", ice),
        shape("M206 350 C 236 270, 364 270, 394 350 Q 378 380 356 356 Q 334 392 312 360 Q 290 394 268 360 Q 246 390 226 358 Q 214 376 206 350 Z", syrup, w=DETAIL),
        *cubes,
        eye(262, 440, 16), eye(338, 440, 16),
        cheek(232, 480), cheek(368, 480),
        smile(300, 478, 30, 10),
    ]


@character
def takoyaki():
    tray, ball = "#E8B987", "#E8A64C"
    return [
        shape("M90 520 L 510 520 L 470 640 L 130 640 Z", tray),
        circle(180, 470, 70, ball), circle(420, 470, 70, ball),
        circle(300, 440, 92, ball),
        line("M130 452 l 28 -16 l 28 16 l 28 -16 M372 452 l 28 -16 l 28 16 l 28 -16", w=5),
        line("M226 360 q 18 -18 36 0 t 36 0 t 36 0", w=5),
        eye(268, 440, 16), eye(332, 440, 16),
        cheek(244, 480, 12, 8), cheek(356, 480, 12, 8),
        smile(300, 478, 28, 9),
        tube("M450 400 L 520 230", 10, "#D9B07A"),
    ]


@character
def goldfish():
    body, fin = "#FF8A3D", "#FFB35C"
    return [
        shape("M210 400 C 120 300, 60 330, 70 400 C 60 470, 120 500, 210 400 Z", fin),
        line("M80 370 L 180 400 M80 430 L 180 404", w=5),
        shape("M300 260 C 330 200, 380 200, 380 250 Z", fin),
        ellipse(330, 400, 150, 112, body),
        shape("M300 500 C 300 560, 260 580, 240 560 C 260 540, 270 520, 270 500 Z", fin),
        line("M290 320 Q 270 400 290 480", w=DETAIL),
        eye(400, 380, 18),
        cheek(424, 424, 13, 9),
        smile(440, 438, 22, 8),
        circle(510, 300, 16, WHITE, w=5), circle(540, 250, 11, WHITE, w=5),
    ]


# ---------------------------------------------------------------- the polar sea (0.13)


@character
def penguin():
    coat, beak = "#3D4A66", ORANGE
    flipper = [ellipse(168, 480, 42, 104, coat, rot=18)]
    return [
        ellipse(248, 690, 52, 22, beak), ellipse(352, 690, 52, 22, beak),
        *flipper, mirror(flipper),
        ellipse(300, 460, 150, 222, coat),
        ellipse(300, 530, 102, 152, WHITE),
        ellipse(300, 350, 106, 82, WHITE),
        eye(262, 346, 16), eye(338, 346, 16),
        shape("M282 378 L 318 378 L 300 404 Z", beak, w=6),
        cheek(234, 382, 13, 9), cheek(366, 382, 13, 9),
    ]


@character
def polarBear():
    fur, scarf = WHITE, SKY
    ear = [circle(196, 222, 40, fur), circle(196, 222, 20, PINK, w=DETAIL)]
    return [
        rect(194, 590, 82, 112, 36, fur), rect(324, 590, 82, 112, 36, fur),
        line("M206 672 Q 235 664 264 672 M336 672 Q 365 664 394 672"),
        ellipse(300, 548, 160, 128, fur),
        *ear, mirror(ear),
        circle(300, 330, 140, fur),
        shape("M190 432 C 240 466, 360 466, 410 432 L 404 472 C 360 500, 240 500, 196 472 Z", scarf),
        rect(338, 470, 46, 92, 16, scarf),
        ellipse(300, 380, 62, 46, CREAM, w=DETAIL),
        ellipse(300, 362, 22, 15, INK, w=4),
        line("M300 377 V 396 M300 396 Q 286 410 274 402 M300 396 Q 314 410 326 402", w=5),
        eye(246, 318, 15), eye(354, 318, 15),
        cheek(224, 360, 13, 9), cheek(376, 360, 13, 9),
    ]


@character
def seal():
    skin, belly = "#B8C6D8", "#DCE6F2"
    flipper = [ellipse(170, 566, 38, 70, skin, rot=36)]
    tail = [ellipse(236, 688, 60, 24, skin, rot=-10)]
    return [
        *tail, mirror(tail),
        ellipse(300, 566, 138, 132, skin),
        ellipse(300, 592, 84, 92, belly, w=DETAIL),
        *flipper, mirror(flipper),
        circle(300, 318, 140, skin),
        ellipse(300, 374, 72, 46, belly, w=DETAIL),
        ellipse(300, 354, 20, 13, INK, w=4),
        line("M300 367 V 378", w=5),
        smile(300, 384, 32, 9),
        line("M228 368 L 184 360 M228 386 L 186 392 M372 368 L 416 360 M372 386 L 414 392", w=4),
        eye(240, 300, 17), eye(360, 300, 17),
        cheek(200, 356), cheek(400, 356),
    ]


@character
def snowman():
    snow, hat, scarf, carrot = WHITE, RED, GREEN, ORANGE
    return [
        tube("M178 500 L 96 430 M96 430 L 80 396 M96 430 L 62 432", 10, BROWN),
        tube("M422 500 L 504 430 M504 430 L 520 396 M504 430 L 538 432", 10, BROWN),
        circle(300, 562, 142, snow),
        circle(300, 330, 106, snow),
        rect(208, 214, 184, 24, 10, hat),
        rect(236, 112, 128, 112, 16, hat),
        rect(236, 186, 128, 22, 0, YELLOW, sw=DETAIL),
        shape("M206 418 C 250 446, 350 446, 394 418 L 392 456 C 350 482, 250 482, 208 456 Z", scarf),
        rect(330, 452, 44, 96, 14, scarf),
        shape("M300 336 L 370 352 L 300 364 Z", carrot, w=6),
        eye(262, 312, 15), eye(330, 310, 15),
        cheek(244, 350, 12, 8), cheek(352, 352, 12, 8),
        smile(296, 378, 26, 8),
        circle(300, 540, 13, DARK, w=5), circle(300, 600, 13, DARK, w=5),
    ]


@character
def arcticFox():
    fur, ear_in = "#F2F7FC", PINK
    ear = [shape("M206 300 L 200 156 L 290 246 Z", fur), shape("M218 280 L 214 196 L 268 250 Z", ear_in, w=DETAIL)]
    return [
        shape("M388 640 C 560 650, 610 430, 486 350 C 470 420, 500 500, 440 540 C 418 556, 398 580, 388 600 Z", fur),
        shape("M520 420 C 560 470, 556 520, 530 560 C 540 510, 536 460, 520 420 Z", WHITE, w=DETAIL),
        ellipse(300, 566, 122, 132, fur),
        rect(220, 640, 64, 64, 28, fur), rect(316, 640, 64, 64, 28, fur),
        *ear, mirror(ear),
        shape("M180 330 C 180 240, 420 240, 420 330 C 420 400, 360 440, 300 450 C 240 440, 180 400, 180 330 Z", fur),
        eye(256, 330, 15), eye(344, 330, 15),
        ellipse(300, 392, 18, 12, INK, w=4),
        line("M300 404 Q 290 418 280 410 M300 404 Q 310 418 320 410", w=5),
        cheek(232, 372, 12, 8), cheek(368, 372, 12, 8),
    ]


@character
def orca():
    dark = "#2F3540"
    return [
        shape("M96 420 L 30 356 L 40 430 L 30 504 Z", dark),
        shape("M276 312 L 300 196 L 352 306 Z", dark),
        ellipse(300, 432, 232, 132, dark),
        shape("M110 470 C 200 566, 420 566, 506 466 C 420 516, 200 516, 110 470 Z", WHITE),
        ellipse(398, 392, 50, 32, WHITE, rot=-10),
        ellipse(310, 524, 52, 24, dark, rot=30),
        eye(394, 398, 15),
        cheek(452, 440, 13, 9),
        smile(470, 466, 22, 8),
    ]


@character
def sled():
    wood, runner, gift, ribbon = BROWN, RED, GREEN, YELLOW
    return [
        tube("M110 610 L 470 610 Q 530 610 530 548", 16, runner),
        rect(166, 496, 26, 120, 8, wood), rect(287, 496, 26, 120, 8, wood), rect(408, 496, 26, 120, 8, wood),
        rect(120, 430, 380, 76, 18, "#D69B66"),
        line("M140 468 H 480", w=DETAIL),
        rect(214, 250, 172, 182, 18, gift),
        rect(284, 250, 32, 182, 0, ribbon, sw=DETAIL),
        shape("M300 250 C 250 190, 220 230, 300 250 C 380 230, 350 190, 300 250 Z", ribbon, w=6),
        eye(260, 336, 15), eye(340, 336, 15),
        cheek(240, 372, 12, 8), cheek(360, 372, 12, 8),
        smile(300, 370, 24, 8),
    ]


@character
def igloo():
    ice, door = "#EAF5FF", "#5C7DA6"
    return [
        ellipse(300, 640, 240, 34, "#DCEEFB"),
        shape("M100 630 C 100 330, 500 330, 500 630 Z", ice),
        line("M112 528 Q 300 508 488 528", w=DETAIL),
        line("M182 446 V 520 M418 446 V 520 M172 530 V 628 M428 530 V 628", w=DETAIL),
        shape("M240 630 C 240 530, 360 530, 360 630 Z", door),
        eye(262, 458, 15), eye(338, 458, 15),
        cheek(240, 490, 12, 8), cheek(360, 490, 12, 8),
        smile(300, 486, 24, 8),
    ]
