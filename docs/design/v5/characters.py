"""The 46 characters of the places you can go into, in kawaii.py's
coloring-book style. Each is a function returning SVG parts in page
coordinates (600 x 800), drawn back to front, facing right; the ground is
around y = 700.
"""
import re

from kawaii import (BLUE, BROWN, CREAM, DARK, DETAIL, GRAY, GREEN, INK, LEAF, ORANGE, PINK, PURPLE, RED, SKY, WHITE, YELLOW,
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
    body = GRAY
    return [
        line("M110 430 Q 80 470 94 520", w=10),
        ellipse(94, 530, 14, 20, "#7D8798"),
        leg(195, 500, 64, 170, "#97A5B9"),
        leg(345, 500, 64, 170, "#97A5B9"),
        ellipse(255, 455, 165, 125, body),
        leg(145, 520, 72, 185, body),
        leg(295, 520, 72, 185, body),
        tube("M440 390 C 500 405 522 450 510 505 Q 503 540 535 542", 56, body),
        circle(395, 315, 125, body),
        ellipse(322, 330, 80, 104, body, rot=-8),
        ellipse(327, 335, 50, 72, PINK, w=DETAIL, rot=-8),
        eye(432, 300, 18),
        cheek(460, 352),
        smile(420, 398, 26, 9),
        line("M474 455 Q 489 462 504 455"),
        line("M480 485 Q 495 492 510 485"),
    ]


@character
def giraffe():
    coat, spot = YELLOW, "#E8A048"
    return [
        line("M135 440 Q 110 500 112 560", w=10),
        ellipse(112, 570, 12, 20, BROWN),
        leg(205, 480, 40, 215, "#F2C53D", toes=False),
        leg(330, 480, 40, 215, "#F2C53D", toes=False),
        tube("M335 440 L 410 215", 78, coat),
        ellipse(260, 465, 140, 88, coat),
        leg(175, 495, 42, 210, coat, toes=False),
        leg(300, 495, 42, 210, coat, toes=False),
        rect(173, 672, 46, 33, 12, BROWN), rect(298, 672, 46, 33, 12, BROWN),
        rect(203, 662, 44, 33, 12, "#8E5E36"), rect(328, 662, 44, 33, 12, "#8E5E36"),
        ellipse(200, 455, 38, 30, spot, w=DETAIL), ellipse(290, 430, 34, 26, spot, w=DETAIL),
        ellipse(275, 505, 30, 22, spot, w=DETAIL), ellipse(355, 470, 26, 22, spot, w=DETAIL),
        ellipse(375, 330, 20, 26, spot, w=DETAIL, rot=18), ellipse(352, 400, 18, 22, spot, w=DETAIL, rot=18),
        tube("M392 142 L 386 98", 16, "#F2C53D"), tube("M440 140 L 446 96", 16, "#F2C53D"),
        circle(385, 92, 15, BROWN), circle(447, 90, 15, BROWN),
        ellipse(368, 165, 34, 15, coat, rot=-25),
        ellipse(425, 195, 78, 66, coat),
        ellipse(480, 225, 48, 36, CREAM),
        nostril(468, 218), nostril(492, 218),
        eye(433, 180, 15),
        cheek(412, 222, 13, 9),
        smile(480, 245, 20, 6),
    ]


@character
def lion():
    fur = "#FFC861"
    return [
        line("M110 440 Q 60 420 62 360", w=10),
        ellipse(62, 345, 18, 24, "#D98A33"),
        leg(170, 500, 62, 165, "#F2B64E"),
        leg(320, 500, 62, 165, "#F2B64E"),
        ellipse(250, 470, 160, 105, fur),
        leg(130, 520, 70, 180, fur),
        leg(290, 520, 70, 180, fur),
        shape(scallop(405, 320, 140, 178, 14), "#D98A33"),
        circle(345, 228, 30, fur), circle(470, 222, 30, fur),
        circle(345, 228, 14, "#F2B64E", w=DETAIL), circle(470, 222, 14, "#F2B64E", w=DETAIL),
        circle(410, 325, 102, fur),
        ellipse(430, 372, 55, 38, CREAM),
        eye(375, 312, 16), eye(445, 310, 16),
        cheek(348, 352), cheek(488, 350),
        ellipse(430, 352, 15, 11, "#8E5E36", w=DETAIL),
        line("M430 363 L 430 378 M412 380 Q 421 392 430 378 Q 439 392 448 380"),
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
    black = "#3A3A46"
    body = ellipse(255, 460, 150, 90, WHITE)
    neck = ("M345 430 L 410 280", 82)
    stripes = [tube(f"M{x} 360 Q {x - 22} 460 {x + 6} 560", 22, black) for x in (165, 225, 285, 345)]
    neck_stripes = [tube(f"M{x} {y} L {x + 70} {y + 22}", 18, black) for x, y in ((340, 300), (325, 350), (310, 400))]
    return [
        line("M110 430 Q 90 490 95 545", w=10),
        ellipse(95, 556, 13, 22, black),
        leg(190, 480, 44, 215, "#E8EAF0", toes=False),
        leg(320, 480, 44, 215, "#E8EAF0", toes=False),
        tube("M318 415 L 385 245", 30, black),
        tube("M%s" % neck[0][1:], neck[1], WHITE),
        body,
        leg(160, 495, 46, 210, WHITE, toes=False),
        leg(290, 495, 46, 210, WHITE, toes=False),
        rect(158, 672, 50, 33, 12, black), rect(288, 672, 50, 33, 12, black),
        rect(188, 662, 48, 33, 12, black), rect(318, 662, 48, 33, 12, black),
        clip("zebra-body", body, stripes), outline(body),
        clip("zebra-neck", f'<path d="M318 450 L 360 425 L 430 270 L 380 250 Z"/>', neck_stripes),
        ellipse(395, 205, 16, 32, WHITE, rot=-15),
        ellipse(440, 255, 72, 60, WHITE),
        ellipse(495, 282, 46, 36, "#9AA0AE"),
        nostril(485, 276), nostril(507, 276),
        eye(445, 240, 15),
        cheek(420, 282, 13, 9),
        smile(492, 300, 20, 6),
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
    skin, shell, patch = "#8CD47E", "#5FAF62", "#9AD58A"
    return [
        ellipse(175, 470, 52, 26, skin, rot=30),
        ellipse(420, 375, 72, 30, skin, rot=-35),
        tube("M430 420 L 480 390", 52, skin),
        circle(500, 378, 58, skin),
        shape("M120 440 C 120 285 455 265 470 440 Z", shell),
        ellipse(295, 372, 62, 46, patch, w=DETAIL),
        ellipse(185, 405, 40, 32, patch, w=DETAIL), ellipse(405, 405, 40, 32, patch, w=DETAIL),
        shape("M110 440 H 480 Q 472 474 440 474 H 150 Q 115 474 110 440 Z", CREAM),
        ellipse(395, 500, 78, 30, skin, rot=-30),
        eye(518, 362, 14),
        cheek(535, 398, 12, 8),
        smile(525, 402, 20, 7),
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


@character
def trex():
    skin, belly = "#7ED37F", CREAM
    return [
        shape("M220 395 C 130 415 70 490 45 575 Q 60 602 92 578 C 140 535 190 522 248 528 Z", skin),
        leg(285, 520, 60, 160, "#6CC06E"),
        shape("M250 330 L 270 290 L 292 322 L 318 280 L 338 318 L 362 285 L 375 330 Z", ORANGE),
        ellipse(290, 455, 130, 122, skin),
        ellipse(325, 485, 66, 84, belly, w=DETAIL, rot=-15),
        ellipse(245, 560, 62, 72, skin),
        rect(205, 628, 100, 64, 28, skin),
        line("M220 666 Q 232 656 244 666 M250 666 Q 262 656 274 666"),
        tube("M392 420 Q 420 432 440 452", 24, skin),
        ellipse(420, 285, 125, 98, skin),
        nostril(512, 262, 5),
        eye(430, 258, 18),
        cheek(470, 310),
        line("M375 335 Q 450 372 530 318"),
        shape("M455 345 L 463 362 L 471 341 Z", WHITE, w=4),
    ]


@character
def triceratops():
    skin, frill, horn = "#F4A259", "#FFC861", CREAM
    return [
        tube("M110 460 Q 70 490 52 525", 44, skin),
        leg(190, 500, 64, 170, "#E59448"), leg(340, 500, 64, 170, "#E59448"),
        ellipse(250, 460, 160, 108, skin),
        leg(140, 520, 72, 180, skin), leg(300, 520, 72, 180, skin),
        shape(scallop(385, 325, 108, 130, 11), frill),
        circle(385, 325, 70, "#FFDA8A", w=DETAIL),
        ellipse(435, 365, 92, 74, skin),
        shape("M405 305 C 405 260 418 225 438 205 C 440 240 442 275 440 306 Z", horn),
        shape("M455 310 C 465 268 485 238 512 225 C 505 262 492 290 480 318 Z", horn),
        shape("M505 355 C 515 335 525 322 540 315 C 540 335 535 352 522 365 Z", horn),
        eye(450, 350, 16),
        cheek(480, 395),
        smile(492, 405, 22, 7),
    ]


@character
def brachiosaurus():
    skin = "#7CC9B5"
    return [
        tube("M100 490 C 65 510 45 545 32 570", 42, skin),
        leg(185, 520, 56, 160, "#69B6A2", toes=False), leg(310, 520, 56, 160, "#69B6A2", toes=False),
        tube("M330 450 C 380 370 400 260 420 175", 72, skin),
        ellipse(230, 490, 150, 96, skin),
        leg(140, 535, 64, 165, skin, toes=False), leg(270, 535, 64, 165, skin, toes=False),
        circle(180, 470, 18, "#A6E0D0", w=DETAIL), circle(240, 445, 14, "#A6E0D0", w=DETAIL), circle(290, 480, 16, "#A6E0D0", w=DETAIL),
        ellipse(455, 150, 66, 46, skin),
        nostril(505, 140, 4),
        eye(458, 135, 14),
        cheek(480, 168, 12, 8),
        smile(498, 172, 18, 6),
    ]


@character
def stegosaurus():
    skin, plate = "#9BD37A", "#FF8A65"
    plates = [shape(f"M{x} {y - h} Q {x + 32} {y - h * 0.4} {x + 26} {y} L {x - 26} {y} Q {x - 32} {y - h * 0.4} {x} {y - h} Z", plate)
              for x, y, h in ((140, 420, 70), (210, 380, 95), (290, 368, 105), (370, 385, 90), (435, 425, 65))]
    return [
        tube("M110 470 Q 70 470 40 440", 40, skin),
        shape("M50 430 L 22 392 L 62 418 Z", CREAM), shape("M48 452 L 18 470 L 60 465 Z", CREAM),
        *plates,
        leg(190, 510, 62, 160, "#88C268"), leg(345, 510, 62, 160, "#88C268"),
        ellipse(270, 475, 170, 100, skin),
        leg(140, 525, 70, 175, skin), leg(300, 525, 70, 175, skin),
        ellipse(470, 495, 62, 50, skin),
        eye(478, 482, 14),
        cheek(500, 512, 12, 8),
        smile(512, 518, 18, 6),
    ]


@character
def pterosaur():
    skin, wing = "#F4A259", "#FFC861"
    wings = [shape("M320 390 C 400 300 500 250 565 285 C 520 320 490 370 480 430 C 430 410 380 420 330 445 Z", wing),
             line("M335 405 Q 430 330 545 292", w=DETAIL)]
    return [
        *wings, mirror(wings),
        tube("M280 500 L 270 545 M320 500 L 330 545", 14, skin),
        ellipse(300, 430, 58, 82, skin),
        shape("M290 268 L 205 238 L 270 305 Z", skin),
        shape("M345 290 L 470 312 L 348 330 Z", CREAM),
        circle(312, 300, 52, skin),
        eye(320, 292, 14),
        cheek(298, 325, 11, 8),
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
        circle(532, 470, 16, YELLOW, w=DETAIL),
        rect(532, 548, 34, 40, 10, "#C9D2DE"),
        wheel(170, 600), wheel(450, 600),
    ]


@character
def policeCar():
    return [
        rect(270, 300, 36, 30, 10, RED), rect(306, 300, 36, 30, 10, BLUE),
        shape("M170 440 L 225 330 H 395 L 460 440 Z", WHITE),
        shape("M205 432 L 245 350 H 300 V 432 Z", SKY), shape("M318 432 V 350 H 382 L 425 432 Z", SKY),
        rect(55, 425, 490, 140, 50, WHITE),
        rect(55, 480, 490, 30, 14, BLUE),
        line("M300 440 V 560", w=DETAIL),
        circle(240, 455, 14, YELLOW, w=DETAIL),
        circle(525, 455, 14, YELLOW, w=DETAIL),
        wheel(170, 575, 56), wheel(430, 575, 56),
    ]


@character
def ambulance():
    cross = "M255 375 H 285 V 345 H 315 V 375 H 345 V 405 H 315 V 435 H 285 V 405 H 255 Z"
    return [
        rect(250, 300, 70, 28, 10, RED),
        rect(60, 325, 400, 250, 34, WHITE),
        shape("M440 325 H 470 Q 540 330 552 455 V 575 H 440 Z", WHITE),
        shape("M462 345 Q 520 350 532 440 H 462 Z", SKY),
        shape(cross, RED),
        rect(60, 470, 492, 30, 14, RED),
        circle(538, 495, 13, YELLOW, w=DETAIL),
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
        circle(505, 450, 18, YELLOW, w=DETAIL),
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
        shape("M488 345 C 525 350 548 368 556 388 H 488 Z", SKY),
        *[circle(x, 380, 15, SKY, w=DETAIL) for x in (190, 245, 300, 355, 410)],
        rect(100, 412, 400, 20, 10, BLUE, sw=DETAIL),
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
        circle(270, 250, 19, WHITE, w=0), circle(330, 250, 19, WHITE, w=0),
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
    shell, horn = "#9A6A44", "#7A5236"
    return [
        tube("M210 545 L 180 620 M290 555 L 290 630 M370 545 L 400 620", 16, "#5A3E2B"),
        tube("M470 410 C 525 380 545 320 520 260", 36, horn),
        tube("M520 260 L 545 230 M520 262 L 492 236", 18, horn),
        ellipse(280, 455, 175, 112, shell),
        line("M140 440 Q 280 400 430 430", w=DETAIL),
        ellipse(230, 400, 40, 18, "#C99A6E", w=DETAIL, rot=-10),
        circle(440, 440, 70, horn),
        eye(450, 430, 15),
        cheek(475, 468, 12, 8),
        smile(462, 470, 20, 7),
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
        eye(266, 218, 17), eye(334, 218, 17),
        cheek(258, 258, 11, 8), cheek(342, 258, 11, 8),
        smile(300, 262, 20, 7),
    ]


@character
def mantis():
    skin = "#8ED36B"
    return [
        tube("M250 470 L 210 600 M300 460 L 330 600 M200 480 L 140 590", 14, "#6FBF50"),
        ellipse(215, 455, 125, 52, skin, rot=-12),
        tube("M330 430 L 395 330", 40, skin),
        tube("M392 360 L 455 410 L 425 470", 26, skin),
        line("M420 255 Q 440 180 480 160"), line("M440 262 Q 480 205 525 200"),
        ellipse(420, 300, 58, 48, skin),
        eye(400, 290, 15), eye(448, 290, 15),
        cheek(388, 325, 11, 8),
        smile(430, 325, 20, 7),
    ]


# ---------------------------------------------------------------- the shop


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
