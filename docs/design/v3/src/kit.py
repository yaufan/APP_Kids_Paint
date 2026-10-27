"""Building blocks for the v3 "畫畫小鎮" mockups: colors, icons, characters,
postcards, pins and the town map. Every function returns an HTML/SVG string.
"""
import colorsys
import math

FONT = "../../../../app/assets/fonts/jf-openhuninn-2.1.ttf"
A = "../assets/"

# Brand palette.
INK = "#34413A"
INK_SOFT = "#6B7A70"
PAPER = "#FFF8EC"
CORAL = "#FF5E5B"
CORAL_DARK = "#D9423F"
SUN = "#FFC94A"
SUN_DARK = "#E0A21C"
SKY = "#4DA8FF"
SKY_DARK = "#2C7FD6"
GRASS = "#6BCB77"
GRASS_DARK = "#3FA052"
TEAL = "#2EC4B6"
GRAPE = "#8C6CFF"
PINK = "#FF8FB1"


def shade(hex_color, amount):
    """Darken (amount < 0) or lighten (amount > 0) a color in HLS space."""
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    hh, ll, ss = colorsys.rgb_to_hls(r, g, b)
    ll = max(0, min(1, ll + amount))
    r, g, b = colorsys.hls_to_rgb(hh, ll, ss)
    return "#%02X%02X%02X" % (round(r * 255), round(g * 255), round(b * 255))


def page(title, body, css="", bg="#FFFFFF"):
    return f"""<!doctype html>
<html lang="zh-Hant-TW"><head><meta charset="utf-8"><title>{title}</title>
<style>
@font-face{{font-family:Huninn;src:url({FONT})}}
*{{box-sizing:border-box}}
body{{margin:0;font-family:Huninn,'Noto Sans TC',sans-serif;color:{INK};background:{bg}}}
.screen{{width:390px;height:844px;position:relative;overflow:hidden;background:{bg}}}
.abs{{position:absolute}}
button{{font-family:inherit;border:0;padding:0;background:none;cursor:pointer;color:inherit}}
.center{{display:flex;align-items:center;justify-content:center}}
{css}
</style></head><body><div class="screen">{body}</div></body></html>"""


# ---------------------------------------------------------------- icons

ICONS = {
    "camera": '<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.8"/>',
    "album": '<rect x="3" y="7" width="14" height="14" rx="2.5"/><path d="M7 3.5h11a2.5 2.5 0 0 1 2.5 2.5v11"/><path d="M3.5 17.5l4-4 3 3 2.5-3 3.5 4"/>',
    "book": '<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21.5z"/><path d="M4 21.5v-16"/><path d="M9 8h7M9 12h5"/>',
    "lock": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
    "undo": '<path d="M9 14L4 9l5-5"/><path d="M4 9h10a6 6 0 0 1 0 12h-3"/>',
    "home": '<path d="M3 11l9-8 9 8"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/>',
    "map": '<path d="M9 4L3 6v14l6-2 6 2 6-2V4l-6 2z"/><path d="M9 4v14"/><path d="M15 6v14"/>',
    "pin": '<path d="M12 21s-7-6.5-7-12a7 7 0 0 1 14 0c0 5.5-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/>',
    "bucket": '<path d="M5 9l7-6 8 8-7 7a2 2 0 0 1-2.8 0L5 12.8a2.7 2.7 0 0 1 0-3.8z"/><path d="M5 9h11"/><path d="M20 15c1.2 1.6 1.8 2.8 1.8 3.6a1.8 1.8 0 0 1-3.6 0c0-.8.6-2 1.8-3.6z"/>',
    "crayon": '<path d="M15 4l5 5-9.5 9.5H5.5v-5z"/><path d="M12.5 6.5l5 5"/><path d="M5.5 18.5L3 21"/>',
    "wand": '<path d="M4 20l10-10"/><path d="M13 9l2 2"/><path d="M17 3l.8 2.2L20 6l-2.2.8L17 9l-.8-2.2L14 6l2.2-.8z"/><path d="M20 12l.5 1.4 1.5.6-1.5.6-.5 1.4-.5-1.4-1.5-.6 1.5-.6z"/>',
    "star": '<path d="M12 3l2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.4 2.9 1-6.1L3.2 9.5l6.1-.9z"/>',
    "heart": '<path d="M12 20s-7-4.5-7-10a4 4 0 0 1 7-2.5A4 4 0 0 1 19 10c0 5.5-7 10-7 10z"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7"/>',
    "close": '<path d="M6 6l12 12M18 6L6 18"/>',
    "back": '<path d="M15 5l-7 7 7 7"/>',
    "share": '<path d="M12 3v12"/><path d="M7 8l5-5 5 5"/><path d="M5 13v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/>',
    "download": '<path d="M12 4v11"/><path d="M7 10l5 5 5-5"/><path d="M5 20h14"/>',
    "printer": '<path d="M7 9V3h10v6"/><rect x="3" y="9" width="18" height="8" rx="2"/><path d="M7 14h10v7H7z"/>',
    "sound": '<path d="M4 9v6h4l5 4V5L8 9z"/><path d="M16 9a4 4 0 0 1 0 6"/><path d="M19 6a8 8 0 0 1 0 12"/>',
    "flip": '<path d="M4 9a8 8 0 0 1 14-3l2 2"/><path d="M20 4v4h-4"/><path d="M20 15a8 8 0 0 1-14 3l-2-2"/><path d="M4 20v-4h4"/>',
    "flash": '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "clock": '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
    "shield": '<path d="M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z"/><path d="M9 12l2 2 4-4"/>',
    "trash": '<path d="M4 7h16"/><path d="M9 7V4h6v3"/><path d="M6 7l1 13h10l1-13"/>',
    "info": '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5"/><path d="M12 8h.01"/>',
    "chevron": '<path d="M9 5l7 7-7 7"/>',
    "users": '<circle cx="9" cy="8" r="3.5"/><path d="M3 20a6 6 0 0 1 12 0"/><circle cx="17" cy="9" r="2.5"/><path d="M16 14a5 5 0 0 1 5 5"/>',
    "pattern": '<rect x="3" y="3" width="18" height="18" rx="4"/><circle cx="8" cy="8" r="1.3"/><circle cx="16" cy="8" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="8" cy="16" r="1.3"/><circle cx="16" cy="16" r="1.3"/>',
    "glitter": '<path d="M7 9h10v10a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2z"/><path d="M8 5h8v4H8z"/><path d="M10 14h.01M14 13h.01M12 17h.01"/>',
    "mail": '<rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M4 7l8 6 8-6"/>',
    "sparkle": '<path d="M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z"/>',
}


def icon(name, size=24, color=INK, sw=2.2, fill="none", label=None):
    aria = f'role="img" aria-label="{label}"' if label else 'aria-hidden="true"'
    stroke = f'stroke="{color}" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round"' if fill == "none" else ""
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="{fill}" {stroke} {aria}>'
            f'{ICONS[name]}</svg>')


def solid(name, size=24, color=INK):
    return icon(name, size, color, fill=color)


# ---------------------------------------------------------------- characters

def _face(eye_y=33, eye_dx=8.5, eye_r=3.1, muzzle=None, nose="#3B2A22", blush="#FF9AA8", mouth="#3B2A22"):
    out = []
    if muzzle:
        out.append(f'<ellipse cx="32" cy="44" rx="11" ry="8.5" fill="{muzzle}"/>')
    for sx in (-1, 1):
        cx = 32 + sx * eye_dx
        out.append(f'<circle cx="{cx}" cy="{eye_y}" r="{eye_r}" fill="#2A211D"/>')
        out.append(f'<circle cx="{cx + 1}" cy="{eye_y - 1.1}" r="1" fill="#FFFFFF"/>')
        out.append(f'<ellipse cx="{32 + sx * 15}" cy="42" rx="4" ry="2.6" fill="{blush}" opacity="0.75"/>')
    if nose:
        out.append(f'<ellipse cx="32" cy="40.5" rx="3.6" ry="2.6" fill="{nose}"/>')
    out.append(f'<path d="M28.5 45.5q3.5 3 7 0" stroke="{mouth}" stroke-width="1.9" fill="none" stroke-linecap="round"/>')
    return "".join(out)


def animal(kind="bear", size=64, label=None):
    """A round, friendly animal head (the child's avatar)."""
    b = []
    if kind == "bear":
        b += ['<circle cx="15" cy="17" r="10" fill="#B07548"/><circle cx="49" cy="17" r="10" fill="#B07548"/>',
              '<circle cx="15" cy="17" r="5" fill="#F3C9A0"/><circle cx="49" cy="17" r="5" fill="#F3C9A0"/>',
              '<circle cx="32" cy="36" r="24" fill="#C98B5E"/>', _face(muzzle="#F6DCC0")]
    elif kind == "rabbit":
        b += ['<ellipse cx="22" cy="14" rx="7" ry="16" fill="#F3EEF6"/><ellipse cx="42" cy="14" rx="7" ry="16" fill="#F3EEF6"/>',
              '<ellipse cx="22" cy="15" rx="3.4" ry="11" fill="#FFB3C7"/><ellipse cx="42" cy="15" rx="3.4" ry="11" fill="#FFB3C7"/>',
              '<circle cx="32" cy="38" r="22" fill="#F3EEF6"/>', _face(eye_y=36, muzzle=None, nose="#FF7FA3")]
    elif kind == "cat":
        b += ['<path d="M10 28 L14 6 L28 18 Z" fill="#F59A3E"/><path d="M54 28 L50 6 L36 18 Z" fill="#F59A3E"/>',
              '<path d="M14 22 L16 12 L23 18 Z" fill="#FFD2A8"/><path d="M50 22 L48 12 L41 18 Z" fill="#FFD2A8"/>',
              '<circle cx="32" cy="36" r="23" fill="#FFAE5C"/>',
              '<path d="M27 15 l2 7 M32 14 v8 M37 15 l-2 7" stroke="#E07B22" stroke-width="2.4" stroke-linecap="round"/>',
              _face(muzzle="#FFF1DE", nose="#FF7FA3"),
              '<path d="M10 40 h9 M10 45 h9 M45 40 h9 M45 45 h9" stroke="#E07B22" stroke-width="1.4" stroke-linecap="round"/>']
    elif kind == "dog":
        b += ['<circle cx="32" cy="36" r="23" fill="#EDC08D"/>',
              '<ellipse cx="11" cy="30" rx="8" ry="15" fill="#8D5A3B" transform="rotate(14 11 30)"/>',
              '<ellipse cx="53" cy="30" rx="8" ry="15" fill="#8D5A3B" transform="rotate(-14 53 30)"/>',
              '<ellipse cx="41" cy="28" rx="7" ry="6" fill="#D9A06A"/>', _face(muzzle="#FFF4E4", nose="#3B2A22")]
    elif kind == "panda":
        b += ['<circle cx="15" cy="17" r="9" fill="#2F2F38"/><circle cx="49" cy="17" r="9" fill="#2F2F38"/>',
              '<circle cx="32" cy="36" r="24" fill="#FFFFFF"/>',
              '<ellipse cx="23" cy="34" rx="6.5" ry="8" fill="#2F2F38" transform="rotate(25 23 34)"/>',
              '<ellipse cx="41" cy="34" rx="6.5" ry="8" fill="#2F2F38" transform="rotate(-25 41 34)"/>',
              '<circle cx="23.5" cy="33" r="2.6" fill="#FFFFFF"/><circle cx="40.5" cy="33" r="2.6" fill="#FFFFFF"/>',
              '<circle cx="24" cy="33.4" r="1.4" fill="#2A211D"/><circle cx="41" cy="33.4" r="1.4" fill="#2A211D"/>',
              '<ellipse cx="17" cy="43" rx="4" ry="2.6" fill="#FF9AA8" opacity="0.7"/><ellipse cx="47" cy="43" rx="4" ry="2.6" fill="#FF9AA8" opacity="0.7"/>',
              '<ellipse cx="32" cy="41" rx="3.6" ry="2.6" fill="#2F2F38"/>',
              '<path d="M28.5 46q3.5 3 7 0" stroke="#2F2F38" stroke-width="1.9" fill="none" stroke-linecap="round"/>']
    elif kind == "fox":
        b += ['<path d="M8 30 L12 4 L28 18 Z" fill="#FF8A3D"/><path d="M56 30 L52 4 L36 18 Z" fill="#FF8A3D"/>',
              '<path d="M13 22 L14 10 L23 18 Z" fill="#FFF1DE"/><path d="M51 22 L50 10 L41 18 Z" fill="#FFF1DE"/>',
              '<circle cx="32" cy="36" r="23" fill="#FF9447"/>',
              '<path d="M10 40 Q20 34 32 46 Q44 34 54 40 Q50 58 32 59 Q14 58 10 40 Z" fill="#FFF4E6"/>',
              _face(muzzle=None, nose="#3B2A22")]
    elif kind == "frog":
        b += ['<ellipse cx="32" cy="40" rx="26" ry="20" fill="#7BD389"/>',
              '<circle cx="20" cy="22" r="10" fill="#7BD389"/><circle cx="44" cy="22" r="10" fill="#7BD389"/>',
              '<circle cx="20" cy="22" r="6.5" fill="#FFFFFF"/><circle cx="44" cy="22" r="6.5" fill="#FFFFFF"/>',
              '<circle cx="21" cy="23" r="3.4" fill="#2A211D"/><circle cx="45" cy="23" r="3.4" fill="#2A211D"/>',
              '<circle cx="22" cy="21.6" r="1.1" fill="#FFFFFF"/><circle cx="46" cy="21.6" r="1.1" fill="#FFFFFF"/>',
              '<ellipse cx="15" cy="42" rx="4.5" ry="2.8" fill="#FF9AA8" opacity="0.8"/><ellipse cx="49" cy="42" rx="4.5" ry="2.8" fill="#FF9AA8" opacity="0.8"/>',
              '<path d="M20 44 Q32 54 44 44" stroke="#2F7A44" stroke-width="2.4" fill="none" stroke-linecap="round"/>']
    elif kind == "penguin":
        b += ['<circle cx="32" cy="35" r="25" fill="#3A4A6B"/>',
              '<path d="M32 22 C 22 14, 10 24, 14 38 C 17 50, 26 56, 32 56 C 38 56, 47 50, 50 38 C 54 24, 42 14, 32 22 Z" fill="#FFFFFF"/>',
              _face(eye_y=34, nose=None, blush="#FF9AA8"),
              '<path d="M28 40 L36 40 L32 46 Z" fill="#FFB020"/>']
    aria = f'role="img" aria-label="{label}"' if label else 'aria-hidden="true"'
    return f'<svg width="{size}" height="{size}" viewBox="0 0 64 64" {aria}>{"".join(b)}</svg>'


ANIMALS = ["bear", "rabbit", "cat", "dog", "panda", "fox", "frog", "penguin"]
ANIMAL_NAMES = {"bear": "小熊", "rabbit": "小兔", "cat": "小貓", "dog": "小狗", "panda": "貓熊",
                "fox": "狐狸", "frog": "青蛙", "penguin": "企鵝"}


def pigeon(size=100, letter=True, flying=False, label="郵差鴿咕咕", asleep=False):
    """Gugu, the town's mail pigeon who carries finished postcards to the map."""
    wing = ('<path d="M48 54 C 38 36, 24 24, 4 22 C 9 28, 8 31, 13 34 C 8 37, 9 41, 17 43 C 13 46, 17 51, 26 52 C 24 56, 32 60, 40 60 Z" fill="#9AB0DE" stroke="#7F96C9" stroke-width="1.5" stroke-linejoin="round"/>'
            if flying else '<ellipse cx="40" cy="62" rx="17" ry="11" fill="#9AB0DE" transform="rotate(-18 40 62)"/>')
    env = ('<g transform="rotate(-10 66 76)"><rect x="54" y="68" width="26" height="18" rx="3" fill="#FFFFFF" stroke="#E6D3B3" stroke-width="1.5"/>'
           '<path d="M55 70 L67 79 L79 70" stroke="#FF5E5B" stroke-width="2" fill="none"/></g>') if letter else ""
    eye = ('<path d="M58 36.5 Q62 40.5 66 36.5" stroke="#2A211D" stroke-width="2.4" fill="none" stroke-linecap="round"/>' if asleep
           else '<circle cx="62" cy="37" r="3.4" fill="#2A211D"/><circle cx="63.2" cy="35.8" r="1.1" fill="#FFFFFF"/>')
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 100 100" role="img" aria-label="{label}">
<ellipse cx="50" cy="94" rx="22" ry="4" fill="#000" opacity="{0 if flying else 0.12}"/>
<path d="M42 88 l-3 6 M48 88 l1 6 M58 88 l-1 6 M64 88 l3 6" stroke="#FF8FA8" stroke-width="3" stroke-linecap="round" opacity="{0 if flying else 1}"/>
<ellipse cx="52" cy="66" rx="28" ry="24" fill="#B9C9EC"/>
<ellipse cx="58" cy="72" rx="16" ry="14" fill="#EEF2FB"/>
{wing}
<path d="M50 44 C 44 50, 44 56, 50 60 C 60 58, 66 52, 64 44 Z" fill="#7FD1C7" opacity="0.9"/>
<path d="M50 44 C 46 50, 47 54, 52 58" stroke="#B79CFF" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.9"/>
<circle cx="56" cy="34" r="17" fill="#B9C9EC"/>
<path d="M38 26 C 40 14, 70 12, 74 24 L 76 28 L 38 30 Z" fill="#FF5E5B"/>
<rect x="37" y="27" width="40" height="5" rx="2.5" fill="#D9423F"/>
<circle cx="57" cy="20" r="3" fill="#FFC94A"/>
{eye}
<path d="M71 39 L82 42 L71 45 Z" fill="#FFB020"/>
<ellipse cx="60" cy="45" rx="4" ry="2.4" fill="#FF9AA8" opacity="0.8"/>
<path d="M34 56 L74 78" stroke="#FFC94A" stroke-width="5" stroke-linecap="round"/>
{env}
</svg>'''


# ---------------------------------------------------------------- postcard parts

def scallop_path(x, y, w, h, r=3.2, step=8.0):
    """Outline of a stamp with semicircle notches along every edge."""
    pts = []
    nx = max(2, round(w / step)); ny = max(2, round(h / step))
    sx = w / nx; sy = h / ny
    d = f"M{x},{y} "
    for i in range(nx):
        cx = x + sx * (i + 0.5)
        d += f"L{cx - r},{y} A{r},{r} 0 0 0 {cx + r},{y} "
    d += f"L{x + w},{y} "
    for i in range(ny):
        cy = y + sy * (i + 0.5)
        d += f"L{x + w},{cy - r} A{r},{r} 0 0 0 {x + w},{cy + r} "
    d += f"L{x + w},{y + h} "
    for i in range(nx):
        cx = x + w - sx * (i + 0.5)
        d += f"L{cx + r},{y + h} A{r},{r} 0 0 0 {cx - r},{y + h} "
    d += f"L{x},{y + h} "
    for i in range(ny):
        cy = y + h - sy * (i + 0.5)
        d += f"L{x},{cy + r} A{r},{r} 0 0 0 {x},{cy - r} "
    return d + "Z"


_uid = [0]


def stamp(img, w=74, h=86, tilt=6, label="原本的照片"):
    _uid[0] += 1
    cid = f"st{_uid[0]}"
    p = scallop_path(1, 1, w - 2, h - 2)
    return f'''<svg width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" aria-label="{label}" style="transform:rotate({tilt}deg);filter:drop-shadow(0 6px 8px rgba(40,60,50,.28))">
<defs><clipPath id="{cid}"><rect x="7" y="7" width="{w - 14}" height="{h - 14}" rx="2"/></clipPath></defs>
<path d="{p}" fill="#FFFFFF"/>
<image href="{img}" x="7" y="7" width="{w - 14}" height="{h - 14}" preserveAspectRatio="xMidYMid slice" clip-path="url(#{cid})"/>
<rect x="7" y="7" width="{w - 14}" height="{h - 14}" rx="2" fill="none" stroke="rgba(0,0,0,.08)"/>
</svg>'''


def postmark(text="10.24", size=70, color="rgba(176,86,28,.62)", tilt=-14):
    s = size
    waves = "".join(f'<path d="M{s * 0.72} {s * (0.36 + 0.14 * i)} q8 -5 16 0 t16 0 t16 0" stroke="{color}" stroke-width="2.2" fill="none"/>' for i in range(3))
    return f'''<svg width="{s * 1.6}" height="{s}" viewBox="0 0 {s * 1.6} {s}" aria-hidden="true" style="transform:rotate({tilt}deg)">
<circle cx="{s / 2}" cy="{s / 2}" r="{s / 2 - 2}" fill="none" stroke="{color}" stroke-width="2.4"/>
<circle cx="{s / 2}" cy="{s / 2}" r="{s / 2 - 8}" fill="none" stroke="{color}" stroke-width="1.4"/>
<text x="{s / 2}" y="{s / 2 + 5}" text-anchor="middle" font-family="Huninn" font-size="{s * 0.2}" fill="{color}" font-weight="700">{text}</text>
{waves}</svg>'''


# ---------------------------------------------------------------- pins

def art_pin(x, y, img, size=60, label="作品", count=None, ring="#FFFFFF", today=False, bob=0):
    """An artwork pinned to the map; (x, y) is where its point touches the ground."""
    pad = 5 if not today else 6
    badge = ""
    if count:
        badge = f'<span class="abs center" style="right:-9px;top:-9px;min-width:26px;height:26px;border-radius:13px;background:{CORAL};color:#fff;font-size:14px;font-weight:700;border:3px solid #fff;padding:0 5px">{count}</span>'
    if today:
        badge = f'<span class="abs center" style="right:-11px;top:-11px;width:32px;height:32px;border-radius:50%;background:{CORAL};border:3px solid #fff">{solid("star", 17, "#FFFFFF")}</span>'
    pulse = ""
    if today:
        pulse = (f'<span class="abs" style="left:{x - 26}px;top:{y - 14}px;width:52px;height:28px;border-radius:50%;border:4px solid {SUN};opacity:.7"></span>'
                 f'<span class="abs" style="left:{x - 40}px;top:{y - 21}px;width:80px;height:42px;border-radius:50%;border:3px solid {SUN};opacity:.35"></span>')
    tip = 12
    left = x - size / 2
    top = y - size - tip - bob
    return f'''{pulse}<span class="abs" style="left:{x - 12}px;top:{y - 5}px;width:24px;height:9px;border-radius:50%;background:rgba(30,60,40,.22)"></span>
<button aria-label="{label}" class="abs" style="left:{left}px;top:{top}px;width:{size}px;height:{size + tip}px">
<span class="abs" style="left:0;top:0;width:{size}px;height:{size}px;border-radius:{size * 0.3}px;background:{ring};padding:{pad}px;box-shadow:0 8px 16px rgba(30,60,40,.28)"><img src="{img}" alt="" style="display:block;width:100%;height:100%;border-radius:{size * 0.3 - pad}px;object-fit:cover"></span>
<span class="abs" style="left:{size / 2 - 9}px;top:{size - 1}px;width:0;height:0;border-left:9px solid transparent;border-right:9px solid transparent;border-top:{tip + 1}px solid {ring}"></span>
{badge}</button>'''


def empty_pin(x, y, label="還沒畫過的地方"):
    return f'''<span class="abs" style="left:{x - 10}px;top:{y - 4}px;width:20px;height:8px;border-radius:50%;background:rgba(30,60,40,.18)"></span>
<button aria-label="{label}" class="abs center" style="left:{x - 21}px;top:{y - 52}px;width:42px;height:42px;border-radius:50%;background:rgba(255,255,255,.72);border:3px dashed #FFFFFF;box-shadow:0 4px 10px rgba(30,60,40,.18)">{icon("plus", 20, "#5E8F6B", 3)}</button>
<span class="abs" style="left:{x - 1.5}px;top:{y - 12}px;width:3px;height:10px;background:#FFFFFF;border-radius:2px"></span>'''


# ---------------------------------------------------------------- town map

def _poly(points, fill, stroke=None, sw=1.4, extra=""):
    pts = " ".join(f"{px:.1f},{py:.1f}" for px, py in points)
    st = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round"' if stroke else ""
    return f'<polygon points="{pts}" fill="{fill}"{st} {extra}/>'


DX, DY = 0.32, -0.26  # oblique depth direction (per unit of depth)


def box(x, y, w, h, dep, color, roof=None, roof_h=0, windows=None, door=None, outline=True, top_color=None):
    """A building block seen from the front-right: front wall, right wall and roof.

    (x, y) is the front wall's bottom-left corner on the ground.
    """
    dx, dy = dep * DX * 3, dep * DY * 3
    o = shade(color, -0.32) if outline else None
    side = shade(color, -0.1)
    top = top_color or shade(color, 0.06)
    s = []
    # ground shadow
    s.append(_poly([(x + 4, y + 2), (x + w + dx + 8, y + dy + 2), (x + w + dx + 14, y + dy + 8), (x + 10, y + 8)], "rgba(30,60,40,.16)"))
    s.append(_poly([(x + w, y), (x + w + dx, y + dy), (x + w + dx, y - h + dy), (x + w, y - h)], side, o))
    if roof == "gable":
        r = roof_h
        rc, rs = roof_color = (shade(ROOF.get(color, CORAL), 0), shade(ROOF.get(color, CORAL), -0.12))
        ro = shade(rc, -0.3)
        # back slope, front slope, then the front gable wall
        s.append(_poly([(x - 3, y - h), (x + w / 2, y - h - r), (x + w / 2 + dx, y - h - r + dy), (x - 3 + dx, y - h + dy)], rs, ro))
        s.append(_poly([(x + w / 2, y - h - r), (x + w + 3, y - h), (x + w + 3 + dx, y - h + dy), (x + w / 2 + dx, y - h - r + dy)], rc, ro))
        s.append(_poly([(x, y), (x + w, y), (x + w, y - h), (x + w / 2, y - h - r * 0.86), (x, y - h)], color, o))
    else:
        s.append(_poly([(x, y - h), (x + w, y - h), (x + w + dx, y - h + dy), (x + dx, y - h + dy)], top, o))
        s.append(_poly([(x, y), (x + w, y), (x + w, y - h), (x, y - h)], color, o))
        if roof == "flat":
            rc = ROOF.get(color, CORAL)
            s.append(_poly([(x - 3, y - h), (x + w + 3, y - h), (x + w + 3 + dx, y - h + dy), (x - 3 + dx, y - h + dy)], rc, shade(rc, -0.3)))
            s.append(f'<rect x="{x - 3}" y="{y - h}" width="{w + 6}" height="5" fill="{shade(rc, -0.12)}"/>')
    for (wx, wy, ww, wh) in (windows or []):
        s.append(f'<rect x="{x + wx}" y="{y - h + wy}" width="{ww}" height="{wh}" rx="2.5" fill="#A9E0FF" stroke="{shade(color, -0.28)}" stroke-width="1.2"/>')
        s.append(f'<rect x="{x + wx + 1.5}" y="{y - h + wy + 1.5}" width="{ww * 0.35}" height="{wh * 0.35}" rx="1" fill="#FFFFFF" opacity=".75"/>')
    if door:
        dxp, dw, dh, dc = door
        s.append(f'<rect x="{x + dxp}" y="{y - dh}" width="{dw}" height="{dh}" rx="{dw / 2.4}" fill="{dc}" stroke="{shade(dc, -0.3)}" stroke-width="1.2"/>')
    return "".join(s)


ROOF = {}


def tree(x, y, r=14, color="#4DB860", kind="round"):
    s = [f'<ellipse cx="{x + 3}" cy="{y + 1}" rx="{r * 0.95}" ry="{r * 0.32}" fill="rgba(30,60,40,.18)"/>']
    if kind == "round":
        s.append(f'<rect x="{x - 2.5}" y="{y - r * 0.9}" width="5" height="{r * 0.9}" rx="2" fill="#A86E43"/>')
        s.append(f'<circle cx="{x}" cy="{y - r * 1.25}" r="{r}" fill="{color}" stroke="{shade(color, -0.22)}" stroke-width="1.4"/>')
        s.append(f'<circle cx="{x - r * 0.35}" cy="{y - r * 1.55}" r="{r * 0.38}" fill="{shade(color, 0.14)}"/>')
    elif kind == "pine":
        s.append(f'<rect x="{x - 2.5}" y="{y - r * 0.6}" width="5" height="{r * 0.6}" rx="2" fill="#A86E43"/>')
        for i, k in enumerate((1.0, 0.78, 0.56)):
            yy = y - r * 0.5 - i * r * 0.55
            s.append(_poly([(x - r * k, yy), (x + r * k, yy), (x, yy - r * 0.95)], shade(color, -0.04 * i), shade(color, -0.25)))
    elif kind == "palm":
        s.append(f'<path d="M{x} {y} q -3 {-r} 2 {-r * 2.1}" stroke="#B07A4C" stroke-width="4" fill="none" stroke-linecap="round"/>')
        tx, ty = x + 2, y - r * 2.1
        for ang in (-150, -110, -60, -20, 20):
            a = math.radians(ang)
            ex, ey = tx + math.cos(a) * r * 1.1, ty + math.sin(a) * r * 0.7 + r * 0.25
            s.append(f'<path d="M{tx} {ty} Q {(tx + ex) / 2} {ty - r * 0.5} {ex:.1f} {ey:.1f}" stroke="{color}" stroke-width="6" fill="none" stroke-linecap="round"/>')
    return "".join(s)


def flower_patch(x, y, colors=("#FF8FB1", "#FFD166", "#FFFFFF")):
    out = []
    for i, (ox, oy) in enumerate([(0, 0), (9, 4), (-7, 6), (4, 10)]):
        c = colors[i % len(colors)]
        out.append(f'<circle cx="{x + ox}" cy="{y + oy}" r="3.2" fill="{c}"/><circle cx="{x + ox}" cy="{y + oy}" r="1.2" fill="#FFB020"/>')
    return "".join(out)


def cloud(x, y, s=1.0, opacity=0.95):
    return (f'<g transform="translate({x} {y}) scale({s})" opacity="{opacity}">'
            '<path d="M10 40 a12 12 0 0 1 4-23 a16 16 0 0 1 30-8 a14 14 0 0 1 26 4 a13 13 0 0 1 8 27 z" fill="#FFFFFF"/>'
            '<path d="M14 40 h62" stroke="#DCEFFF" stroke-width="3" stroke-linecap="round"/></g>')


def car(x, y, color, kind="car", flip=False):
    t = f'translate({x} {y})' + (' scale(-1 1)' if flip else '')
    if kind == "scooter":
        body = (f'<ellipse cx="0" cy="2" rx="13" ry="3" fill="rgba(30,60,40,.18)"/>'
                f'<circle cx="-8" cy="-2" r="4" fill="#3A3F4B"/><circle cx="8" cy="-2" r="4" fill="#3A3F4B"/>'
                f'<path d="M-10 -6 h14 l5 -8 h3" stroke="{color}" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
                f'<circle cx="-3" cy="-17" r="5" fill="#FFC94A" stroke="#D9A21C" stroke-width="1.2"/>'
                f'<rect x="-5" y="-13" width="5" height="7" rx="2" fill="#4DA8FF"/>')
    elif kind == "bus":
        body = (f'<ellipse cx="0" cy="2" rx="30" ry="4" fill="rgba(30,60,40,.18)"/>'
                f'<rect x="-28" y="-24" width="56" height="24" rx="7" fill="{color}" stroke="{shade(color, -0.3)}" stroke-width="1.4"/>'
                + "".join(f'<rect x="{-23 + i * 12}" y="-19" width="9" height="8" rx="2" fill="#A9E0FF"/>' for i in range(4))
                + f'<circle cx="-16" cy="0" r="5" fill="#3A3F4B"/><circle cx="16" cy="0" r="5" fill="#3A3F4B"/>')
    else:
        body = (f'<ellipse cx="0" cy="2" rx="20" ry="3.5" fill="rgba(30,60,40,.18)"/>'
                f'<path d="M-19 -4 v-8 q0-3 3-3 h6 l6-7 h12 l6 7 h3 q3 0 3 3 v8 z" fill="{color}" stroke="{shade(color, -0.3)}" stroke-width="1.4" stroke-linejoin="round"/>'
                f'<path d="M-6 -14 l4 -5 h9 l4 5 z" fill="#A9E0FF"/>'
                f'<circle cx="-10" cy="-2" r="4.5" fill="#3A3F4B"/><circle cx="10" cy="-2" r="4.5" fill="#3A3F4B"/>')
        if color == "#FFD23F":  # taxi sign
            body += '<rect x="-2" y="-26" width="9" height="5" rx="1.5" fill="#FFFFFF" stroke="#D9A21C" stroke-width="1"/>'
    return f'<g transform="{t}">{body}</g>'


def duck(x, y, s=1.0, flip=False):
    t = f'translate({x} {y}) scale({-s if flip else s} {s})'
    return (f'<g transform="{t}"><ellipse cx="0" cy="0" rx="8" ry="5" fill="#FFFFFF" stroke="#D8DEE8" stroke-width="1"/>'
            f'<circle cx="6" cy="-6" r="4" fill="#FFFFFF" stroke="#D8DEE8" stroke-width="1"/>'
            f'<path d="M9 -6 l4 1 -4 1 z" fill="#FFB020"/><circle cx="7" cy="-7" r="0.9" fill="#2A211D"/></g>')


PLACE_TYPES = [("home", "家"), ("grandma", "阿公阿嬤家"), ("school", "幼兒園"), ("park", "公園"),
               ("food", "好吃的店"), ("shop", "商店"), ("zoo", "動物園"), ("water", "河邊海邊"),
               ("mountain", "山上"), ("temple", "廟"), ("station", "車站"), ("travel", "去旅行"), ("aquarium", "海洋館"), ("dinoPark", "恐龍樂園"),
               ("transport", "交通車館"), ("botanical", "植物園"), ("insects", "昆蟲館")]
PLACE_NAMES = dict(PLACE_TYPES)


def place_icon(kind, size=64):
    """A tiny picture of each kind of place, recognizable without reading."""
    g = '<ellipse cx="32" cy="56" rx="24" ry="4" fill="rgba(30,60,40,.15)"/>'
    art = {
        "home": g + '<rect x="15" y="30" width="34" height="24" rx="3" fill="#FFF4E2" stroke="#C9A06B" stroke-width="1.6"/>'
                '<path d="M10 33 L32 13 L54 33 Z" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.6" stroke-linejoin="round"/>'
                '<rect x="27" y="40" width="10" height="14" rx="4" fill="#C98B5E"/><rect x="18" y="36" width="7" height="7" rx="2" fill="#A9E0FF"/>'
                '<rect x="39" y="36" width="7" height="7" rx="2" fill="#A9E0FF"/><path d="M32 24 c-2-3-6-1-4 2 l4 3 4-3 c2-3-2-5-4-2z" fill="#fff"/>',
        "grandma": g + '<rect x="12" y="30" width="40" height="24" rx="2" fill="#E8836B" stroke="#B85A44" stroke-width="1.6"/>'
                   '<path d="M8 32 Q 32 16 56 32 L52 34 L12 34 Z" fill="#5E7290" stroke="#43546E" stroke-width="1.6"/>'
                   '<path d="M16 38 h32 M16 44 h32 M16 50 h32" stroke="#C96A54" stroke-width="1"/>'
                   '<rect x="27" y="40" width="10" height="14" rx="2" fill="#7A4A2A"/>'
                   '<path d="M20 40 c-2-3-6-1-4 2 l4 3 4-3 c2-3-2-5-4-2z" fill="#FF8FB1"/><path d="M44 40 c-2-3-6-1-4 2 l4 3 4-3 c2-3-2-5-4-2z" fill="#FF8FB1"/>',
        "school": g + '<rect x="10" y="30" width="44" height="24" rx="2" fill="#FFE7A3" stroke="#C29A4A" stroke-width="1.6"/>'
                  '<rect x="8" y="27" width="48" height="5" rx="2" fill="#6F86FF"/><rect x="25" y="16" width="14" height="14" fill="#FFE7A3" stroke="#C29A4A" stroke-width="1.4"/>'
                  '<path d="M22 17 L32 8 L42 17 Z" fill="#6F86FF"/><circle cx="32" cy="23" r="3.6" fill="#fff" stroke="#C29A4A"/>'
                  '<rect x="28" y="42" width="8" height="12" rx="3" fill="#E8A24A"/><rect x="14" y="36" width="8" height="7" rx="2" fill="#A9E0FF"/><rect x="42" y="36" width="8" height="7" rx="2" fill="#A9E0FF"/>'
                  '<path d="M32 8 V1" stroke="#8A6A4A" stroke-width="1.6"/><path d="M32 1 l8 2.5 -8 2.5z" fill="#FF5E5B"/>',
        "park": g + '<rect x="16" y="34" width="4" height="20" rx="2" fill="#A86E43"/><circle cx="18" cy="26" r="13" fill="#4DB860" stroke="#3A9A4C" stroke-width="1.4"/>'
                '<circle cx="14" cy="21" r="4.5" fill="#78D383"/><path d="M36 54 L40 32 H50 L50 54" stroke="#FF8FB1" stroke-width="3" fill="none" stroke-linejoin="round"/>'
                '<path d="M50 32 Q 60 40 60 54" stroke="#FFC94A" stroke-width="5" fill="none" stroke-linecap="round"/>',
        "food": g + '<rect x="12" y="34" width="40" height="20" rx="3" fill="#FFF4E2" stroke="#C9A06B" stroke-width="1.6"/>'
                '<rect x="9" y="24" width="46" height="11" rx="3" fill="#FF5E5B"/>' + "".join(f'<rect x="{12 + k * 11}" y="24" width="5" height="11" fill="#fff" opacity=".8"/>' for k in range(4)) +
                '<path d="M22 44 h20 a10 7 0 0 1 -20 0z" fill="#FFC94A" stroke="#D9A21C" stroke-width="1.2"/><path d="M27 40 q-2 -3 0 -6 M32 40 q-2 -3 0 -6 M37 40 q-2 -3 0 -6" stroke="#B9B2A4" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
                '<ellipse cx="14" cy="16" rx="4" ry="5" fill="#FF5E5B"/><ellipse cx="50" cy="16" rx="4" ry="5" fill="#FFC94A"/><path d="M14 11 Q 32 4 50 11" stroke="#8A6A4A" stroke-width="1.2" fill="none"/>',
        "shop": g + '<rect x="12" y="28" width="40" height="26" rx="2" fill="#FFF6E8" stroke="#C98F5E" stroke-width="1.6"/>'
                + "".join(f'<path d="M{10 + k * 11} 20 h 11 v 9 q -5.5 7 -11 0 z" fill="{"#FF5E5B" if k % 2 == 0 else "#FFFFFF"}" stroke="#D94B4B" stroke-width="1"/>' for k in range(4))
                + '<rect x="16" y="37" width="18" height="13" rx="2" fill="#A9E0FF"/><rect x="38" y="38" width="10" height="16" rx="3" fill="#C98F5E"/>'
                '<path d="M19 40 h5 v9 h-5 z M19 40 l2.5 -3 l2.5 3" fill="#FFFFFF" stroke="#4DA3FF" stroke-width="1.1"/>'
                '<path d="M26 41 h6 l-3 8 z" fill="#FF9442"/><path d="M29 41 l-1.5 -3 M29 41 l1.5 -3" stroke="#3FB37A" stroke-width="1.3" stroke-linecap="round"/>',
        "zoo": g + '<path d="M26 56 V26 q0 -12 8 -14" stroke="#F7C35C" stroke-width="10" stroke-linecap="round" fill="none"/>'
               '<circle cx="30" cy="34" r="2.6" fill="#C98536"/><circle cx="26" cy="46" r="3" fill="#C98536"/>'
               '<ellipse cx="40" cy="14" rx="11" ry="7.5" fill="#F7C35C" stroke="#C98536" stroke-width="1.4"/>'
               '<path d="M35 7 v-6 M43 7 v-6" stroke="#C98536" stroke-width="2.4" stroke-linecap="round"/><circle cx="43" cy="12" r="1.8" fill="#2A211D"/>'
               + "".join(f'<rect x="{8 + k * 10}" y="44" width="5" height="12" rx="2" fill="#E8C79A" stroke="#B9935E" stroke-width="1"/>' for k in range(5)),
        "water": g + '<rect x="6" y="36" width="52" height="18" rx="9" fill="#7CCFFF"/><path d="M10 44 q5 -4 10 0 t10 0 t10 0 t10 0" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round"/>'
                 '<path d="M22 34 h22 l-4 6 h-14 z" fill="#fff" stroke="#9FB3C8" stroke-width="1.4"/><path d="M33 34 V12 L46 30 Z" fill="#FFC94A" stroke="#D9A21C" stroke-width="1.2"/>',
        "mountain": g + '<path d="M4 54 L24 18 L36 36 L44 26 L60 54 Z" fill="#6BCB77" stroke="#3FA052" stroke-width="1.6" stroke-linejoin="round"/>'
                    '<path d="M20 25 L24 18 L28 25 Z" fill="#fff"/><path d="M6 14 L58 6" stroke="#5E6F86" stroke-width="1.4"/>'
                    '<path d="M38 8 v4" stroke="#5E6F86" stroke-width="1.4"/><rect x="33" y="12" width="10" height="9" rx="3" fill="#FF5E5B"/><rect x="35" y="14" width="6" height="3" rx="1" fill="#E8F6FF"/>',
        "temple": g + '<rect x="14" y="34" width="36" height="20" fill="#FFE3C4" stroke="#B83A26" stroke-width="1.4"/><rect x="18" y="34" width="4" height="20" fill="#E0503A"/><rect x="42" y="34" width="4" height="20" fill="#E0503A"/>'
                  '<rect x="27" y="40" width="10" height="14" rx="1" fill="#C9452E"/>'
                  '<path d="M4 30 Q 12 34 16 26 L48 26 Q 52 34 60 30 L54 36 L10 36 Z" fill="#F0583E" stroke="#B83A26" stroke-width="1.4"/>'
                  '<path d="M16 26 Q 32 14 48 26 Z" fill="#FF7A54" stroke="#B83A26" stroke-width="1.4"/><circle cx="32" cy="16" r="3" fill="#FFC94A"/>',
        "station": g + '<rect x="14" y="14" width="36" height="38" rx="10" fill="#fff" stroke="#9FB3C8" stroke-width="1.8"/>'
                   '<rect x="18" y="19" width="28" height="14" rx="4" fill="#A9E0FF"/><rect x="14" y="36" width="36" height="5" fill="#4DA8FF"/>'
                   '<circle cx="22" cy="46" r="3" fill="#FFD23F"/><circle cx="42" cy="46" r="3" fill="#FFD23F"/><path d="M18 56 L14 60 M46 56 L50 60" stroke="#9FB3C8" stroke-width="2.4" stroke-linecap="round"/>',
        "aquarium": g + '<path d="M8 54 V38 Q 32 10 56 38 V54 Z" fill="#7CCFFF" stroke="#43A9E0" stroke-width="1.6"/>'
                    '<path d="M16 34 Q 24 22 36 20" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity=".85"/>'
                    '<path d="M20 42 q4 -9 15 -7 q9 2 9 9 q-2 7 -13 7 q-9 0 -11 -9z" fill="#4DA8FF"/><path d="M21 42 l-7 -5 v10z" fill="#4DA8FF"/>'
                    '<circle cx="38" cy="42" r="1.7" fill="#2A211D"/><path d="M8 50 q6 -3 12 0 t12 0 t12 0 t12 0 V54 H8z" fill="#2C7FD6"/>',
        "dinoPark": g + '<path d="M6 54 L 18 30 L 26 30 L 38 54 Z" fill="#A47A4F"/><path d="M16 34 L 18 30 L 26 30 L 28 34 Z" fill="#FF8A3D"/>'
                    '<circle cx="22" cy="24" r="4" fill="#fff" opacity=".85"/><circle cx="25" cy="16" r="5" fill="#fff" opacity=".85"/>'
                    '<path d="M30 54 C 30 40, 36 26, 44 16 L 50 19 C 44 30, 40 42, 40 54 Z" fill="#7BD389" stroke="#3FA052" stroke-width="1.4"/>'
                    '<ellipse cx="50" cy="15" rx="9" ry="6" fill="#7BD389" stroke="#3FA052" stroke-width="1.4"/><circle cx="52" cy="13" r="1.6" fill="#2A211D"/>'
                    '<circle cx="36" cy="40" r="2" fill="#3FA052"/><circle cx="40" cy="30" r="1.8" fill="#3FA052"/>',
        "transport": g + '<path d="M8 54 V30 Q 32 12 56 30 V54 Z" fill="#E9EEF5" stroke="#9AA9BC" stroke-width="1.6"/>'
                     '<path d="M12 30 Q 32 18 52 30" fill="none" stroke="#BFD9F2" stroke-width="4"/>'
                     '<rect x="12" y="44" width="34" height="9" rx="2" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.2"/>'
                     '<rect x="34" y="34" width="12" height="11" rx="2" fill="#FF5E5B" stroke="#C9423F" stroke-width="1.2"/><rect x="37" y="37" width="6" height="5" fill="#A9E0FF"/>'
                     '<rect x="16" y="37" width="6" height="8" fill="#5A6472"/><circle cx="18" cy="54" r="3.4" fill="#2F3540"/><circle cx="28" cy="54" r="3.4" fill="#2F3540"/>'
                     '<circle cx="40" cy="54" r="3.4" fill="#2F3540"/><path d="M48 54 L 54 50 V 54 Z" fill="#FFD23F"/>'
                     '<path d="M30 21 l10 -3 l2 2 l-9 4 Z M34 19 l-2 -4 h2 l3 3 Z" fill="#4DA8FF"/>',
        "botanical": g + '<path d="M8 54 V36 Q 32 8 56 36 V54 Z" fill="#DDF5E3" stroke="#6FBF86" stroke-width="1.6"/>'
                     '<path d="M20 54 V30 M32 54 V20 M44 54 V30 M10 40 H54" stroke="#9AD4AC" stroke-width="1.6"/>'
                     '<path d="M24 54 q-2 -14 8 -20 q6 10 -2 20 z" fill="#5FCB79"/><circle cx="40" cy="36" r="6" fill="#FFD23F" stroke="#E0A21C" stroke-width="1.2"/>'
                     '<circle cx="40" cy="36" r="2.4" fill="#A86E43"/><path d="M40 42 V54" stroke="#3FA052" stroke-width="2"/>'
                     '<circle cx="18" cy="46" r="3" fill="#FF8FB1"/><circle cx="48" cy="48" r="3" fill="#FF8FB1"/>',
        "insects": g + '<path d="M32 30 C 22 14, 6 16, 10 30 C 12 38, 24 38, 32 34 Z" fill="#FF9F45" stroke="#D9692A" stroke-width="1.4"/>'
                   '<path d="M32 30 C 42 14, 58 16, 54 30 C 52 38, 40 38, 32 34 Z" fill="#FF9F45" stroke="#D9692A" stroke-width="1.4"/>'
                   '<path d="M32 34 C 24 40, 16 48, 22 52 C 28 54, 30 44, 32 38 Z M32 34 C 40 40, 48 48, 42 52 C 36 54, 34 44, 32 38 Z" fill="#FFD166" stroke="#D9692A" stroke-width="1.2"/>'
                   '<ellipse cx="32" cy="36" rx="2.6" ry="12" fill="#5A4636"/><path d="M31 25 q-4 -8 -8 -10 M33 25 q4 -8 8 -10" stroke="#5A4636" stroke-width="1.6" fill="none" stroke-linecap="round"/>'
                   '<circle cx="16" cy="26" r="2.4" fill="#fff"/><circle cx="48" cy="26" r="2.4" fill="#fff"/>',
        "travel": g + '<rect x="12" y="22" width="40" height="32" rx="7" fill="#FF8A3D" stroke="#D9692A" stroke-width="1.6"/>'
                  '<path d="M24 22 v-6 a3 3 0 0 1 3 -3 h10 a3 3 0 0 1 3 3 v6" stroke="#8A5A3A" stroke-width="3" fill="none"/>'
                  '<rect x="18" y="30" width="10" height="8" rx="2" fill="#fff" transform="rotate(-8 23 34)"/><circle cx="42" cy="40" r="5" fill="#4DA8FF"/>'
                  '<path d="M17 46 h14" stroke="#fff" stroke-width="2.4" stroke-linecap="round"/><circle cx="18" cy="56" r="2.6" fill="#5A3A20"/><circle cx="46" cy="56" r="2.6" fill="#5A3A20"/>',
    }[kind]
    return f'<svg width="{size}" height="{size}" viewBox="0 0 64 64" aria-hidden="true">{art}</svg>'


def empty_lot(x, y, w, h, kind):
    """An empty plot waiting for its building, with a sign showing what goes there."""
    cx = x + w / 2
    sy = y + h / 2 - 6
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="#EED9AF" stroke="#D2B47C" stroke-width="2" stroke-dasharray="8 7"/>'
            + "".join(f'<circle cx="{x + 14 + (i * 37) % (w - 24)}" cy="{y + 12 + (i * 23) % (h - 20)}" r="2" fill="#D9BF8C"/>' for i in range(9))
            + f'<rect x="{cx - 2}" y="{sy + 8}" width="4" height="26" fill="#A47A4F"/>'
            + f'<rect x="{cx - 24}" y="{sy - 30}" width="48" height="40" rx="8" fill="#FFFFFF" stroke="#C9A06B" stroke-width="2"/>'
            + f'<g transform="translate({cx - 18} {sy - 28}) scale(0.56)" opacity=".5">{place_icon(kind, 64)[place_icon(kind, 64).index(">") + 1:-6]}</g>')


def tower101(tx, ty, k=1.0):
    """Taipei 101 as a stack of flared tiers; (tx, ty) is the base's bottom-left."""
    s = [f'<g transform="translate({tx} {ty}) scale({k}) translate({-tx} {-ty})">',
         f'<ellipse cx="{tx + 30}" cy="{ty + 2}" rx="40" ry="8" fill="rgba(30,60,40,.18)"/>',
         box(tx, ty, 44, 26, 4, "#6CCBBE")]
    for i in range(6):
        yb = ty - 26 - i * 26
        c = "#8FE0D4" if i % 2 == 0 else "#7BD6C9"
        s.append(_poly([(tx + 4, yb), (tx + 40, yb), (tx + 47, yb - 26), (tx - 3, yb - 26)], c, "#3E9C90"))
        s.append(f'<path d="M{tx + 6} {yb - 9} H{tx + 38}" stroke="#FFFFFF" stroke-width="2.4" opacity=".85"/>')
    top = ty - 26 - 6 * 26
    s.append(f'<rect x="{tx + 12}" y="{top - 14}" width="20" height="14" rx="3" fill="#6CCBBE" stroke="#3E9C90" stroke-width="1.4"/>')
    s.append(f'<path d="M{tx + 22} {top - 14} V{top - 46}" stroke="#3E9C90" stroke-width="3" stroke-linecap="round"/>')
    s.append(f'<circle cx="{tx + 22}" cy="{top - 48}" r="4" fill="#FFD23F"/></g>')
    return "".join(s)


def town_map(dim=False, built=None):
    """The child's town, top-down with front facades, 390 x 844.

    [built] lists the place kinds that have a building yet (None: all of them).
    """
    B = lambda kind: built is None or kind in built
    s = []
    W, H = 390, 844
    s.append('<defs>'
             '<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7CCBFF"/><stop offset="1" stop-color="#D4F0FF"/></linearGradient>'
             '<linearGradient id="mtB" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8FD49D"/><stop offset="1" stop-color="#B5E5B6"/></linearGradient>'
             '<linearGradient id="mtF" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5FBF72"/><stop offset="1" stop-color="#8ED48E"/></linearGradient>'
             '<linearGradient id="river" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5CC0F5"/><stop offset="1" stop-color="#8ED8FF"/></linearGradient>'
             '<pattern id="grassdots" width="18" height="18" patternUnits="userSpaceOnUse"><circle cx="4" cy="5" r="1.4" fill="#8BD07E"/><circle cx="13" cy="13" r="1.2" fill="#B6E9A6"/></pattern>'
             '<pattern id="tiles" width="14" height="14" patternUnits="userSpaceOnUse"><rect width="14" height="14" fill="#F6E7CC"/><path d="M0 0H14M0 0V14" stroke="#EAD5B0" stroke-width="1.2"/></pattern>'
             '</defs>')
    # sky and mountains
    s.append(f'<rect width="{W}" height="230" fill="url(#sky)"/>')
    s.append('<g transform="translate(316 92)"><circle r="34" fill="#FFE27A" opacity=".35"/><circle r="22" fill="#FFD23F"/></g>')
    s.append(cloud(30, 86, 0.9) + cloud(196, 118, 0.7, 0.9))
    s.append('<path d="M-10 196 C 30 150, 60 140, 96 168 C 120 128, 168 112, 214 158 C 250 130, 300 118, 400 160 L400 230 L-10 230 Z" fill="url(#mtB)"/>')
    s.append('<path d="M-10 214 C 40 176, 90 172, 130 196 C 170 168, 220 166, 262 192 C 300 170, 350 164, 400 186 L400 236 L-10 236 Z" fill="url(#mtF)"/>')
    # Maokong-style gondola line
    s.append('<path d="M150 182 L 286 132 L 400 120" stroke="#5E6F86" stroke-width="1.6" fill="none"/>')
    for gx, gy, gc in [(196, 165, "#FF5E5B"), (268, 139, "#FFC94A"), (340, 126, "#4DA8FF")]:
        s.append(f'<path d="M{gx} {gy} v6" stroke="#5E6F86" stroke-width="1.4"/><rect x="{gx - 7}" y="{gy + 6}" width="14" height="12" rx="4" fill="{gc}" stroke="{shade(gc, -0.3)}" stroke-width="1.2"/><rect x="{gx - 4.5}" y="{gy + 8.5}" width="9" height="4.5" rx="1.5" fill="#E8F6FF"/>')
    s.append('<path d="M120 62 l6 4 6-4 M140 54 l5 3 5-3" stroke="#4E6D8C" stroke-width="2" fill="none" stroke-linecap="round"/>')
    # hot air balloon
    s.append('<g transform="translate(92 140)"><path d="M0 -26 C 16 -26, 18 -6, 6 4 L -6 4 C -18 -6, -16 -26, 0 -26 Z" fill="#FF8FB1" stroke="#E0668C" stroke-width="1.4"/>'
             '<path d="M0 -26 C 6 -20, 6 -4, 3 4 M0 -26 C -6 -20, -6 -4, -3 4" stroke="#FFFFFF" stroke-width="2" fill="none"/>'
             '<path d="M-5 4 L-4 10 M5 4 L4 10" stroke="#8A6A4A" stroke-width="1.2"/><rect x="-5" y="10" width="10" height="7" rx="2" fill="#C98B5E"/></g>')
    # land
    s.append(f'<rect x="0" y="224" width="{W}" height="{H - 224}" fill="#A6DE97"/>')
    s.append(f'<rect x="0" y="224" width="{W}" height="{H - 224}" fill="url(#grassdots)"/>')
    # river with riverside strip
    s.append('<path d="M-10 232 C 80 220, 150 250, 240 238 S 340 222, 400 236 L400 286 C 330 274, 260 296, 180 288 S 60 272, -10 286 Z" fill="url(#river)" stroke="#43A9E0" stroke-width="1.5"/>')
    for wx, wy in [(30, 254), (120, 264), (210, 258), (300, 250), (350, 266)]:
        s.append(f'<path d="M{wx} {wy} q6 -4 12 0 t12 0" stroke="#D8F3FF" stroke-width="2.4" fill="none" stroke-linecap="round"/>')
    # rainbow-ish red arch bridge
    s.append('<g transform="translate(286 230)"><path d="M0 52 L0 12 L60 12 L60 52" fill="none"/>'
             '<rect x="-4" y="22" width="68" height="9" rx="3" fill="#F3E3C6" stroke="#C9A97B" stroke-width="1.2"/>'
             '<path d="M2 24 Q30 -8 58 24" stroke="#FF5E5B" stroke-width="5" fill="none" stroke-linecap="round"/>'
             + "".join(f'<path d="M{8 + i * 11} 24 V{14 - (i in (2, 3)) * 6 + (i in (0, 4)) * 4}" stroke="#FF5E5B" stroke-width="2"/>' for i in range(5))
             + '</g>')
    # boat
    s.append('<g transform="translate(70 270)"><path d="M-18 -6 h36 l-6 9 h-24 z" fill="#FFFFFF" stroke="#9FB3C8" stroke-width="1.4"/>'
             '<path d="M0 -6 V-28 L 16 -10 Z" fill="#FFC94A" stroke="#D9A21C" stroke-width="1.2"/><path d="M0 -26 L-12 -10 H0" fill="#FF8FB1"/></g>')
    s.append(duck(170, 276, 0.9) + duck(186, 281, 0.75))

    # roads: two avenues across, one up the middle
    def road(d, w):
        return (f'<path d="{d}" stroke="#F4E4C8" stroke-width="{w + 12}" fill="none" stroke-linecap="butt"/>'
                f'<path d="{d}" stroke="#E2E7EE" stroke-width="{w}" fill="none"/>'
                f'<path d="{d}" stroke="#FFFFFF" stroke-width="2.6" fill="none" stroke-dasharray="12 12"/>')
    s.append(road("M-20 448 L410 448", 30))
    s.append(road("M-20 652 L410 652", 30))
    s.append(road("M206 296 L206 870", 30))
    for cx, cy in [(206, 448), (206, 652)]:
        s.append(f'<rect x="{cx - 15}" y="{cy - 15}" width="30" height="30" fill="#E2E7EE"/>')
        for i in range(5):
            s.append(f'<rect x="{cx - 14 + i * 6}" y="{cy - 30}" width="3.4" height="13" fill="#FFFFFF"/>')
            s.append(f'<rect x="{cx - 14 + i * 6}" y="{cy + 17}" width="3.4" height="13" fill="#FFFFFF"/>')
    # plaza by the tower
    s.append('<rect x="232" y="474" width="150" height="160" rx="18" fill="url(#tiles)"/>')
    if B("park"):
        # park (大安森林公園)
        s.append('<rect x="10" y="470" width="180" height="164" rx="26" fill="#8CD27D"/><rect x="10" y="470" width="180" height="164" rx="26" fill="url(#grassdots)"/>')
        s.append('<path d="M20 520 C 60 530, 90 560, 120 600" stroke="#F4E4C8" stroke-width="9" fill="none" stroke-linecap="round"/>')
        s.append('<path d="M90 584 C 100 556, 152 552, 172 572 C 188 592, 156 616, 122 612 C 98 610, 84 602, 90 584 Z" fill="#7CCFFF" stroke="#43A9E0" stroke-width="1.5"/>')
        s.append('<path d="M108 590 q6 -3 12 0 M140 598 q6 -3 12 0" stroke="#D8F3FF" stroke-width="2" fill="none" stroke-linecap="round"/>')
        s.append(duck(124, 584, 0.9) + duck(148, 592, 0.8, True))
        s.append('<g transform="translate(140 516)"><path d="M0 26 L8 -4 H22 L22 26" stroke="#FF8FB1" stroke-width="4" fill="none" stroke-linejoin="round"/><path d="M22 -4 Q 44 4 46 26" stroke="#FFC94A" stroke-width="7" fill="none" stroke-linecap="round"/></g>')
    else:
        s.append(empty_lot(14, 478, 172, 150, "park"))

    # MRT elevated line across (drawn before the buildings in front of it)
    s.append('<rect x="-10" y="318" width="410" height="12" rx="3" fill="#D5DEE9" stroke="#A9B6C6" stroke-width="1.4"/>')
    for px in range(14, 400, 64):
        s.append(f'<rect x="{px}" y="330" width="9" height="30" fill="#C2CDDA" stroke="#A9B6C6" stroke-width="1.2"/>')
    def mrt_car(x0):
        return (f'<rect x="{x0}" y="296" width="58" height="22" rx="8" fill="#FFFFFF" stroke="#9FB3C8" stroke-width="1.4"/>'
                f'<rect x="{x0}" y="309" width="58" height="5" fill="#4DA8FF"/>'
                + "".join(f'<rect x="{x0 + 6 + i * 13}" y="300" width="9" height="7" rx="2" fill="#A9E0FF"/>' for i in range(4)))
    s.append(mrt_car(38) + mrt_car(98) + mrt_car(158))
    s.append('<path d="M216 318 a10 10 0 0 1 0 -18" fill="none"/>')
    # MRT station
    s.append('<rect x="250" y="288" width="96" height="30" rx="6" fill="#E9F3FF" stroke="#9FB3C8" stroke-width="1.4"/>'
             '<path d="M244 290 Q298 262 352 290 Z" fill="#7CC6FF" stroke="#4E9AD6" stroke-width="1.4"/>'
             '<circle cx="298" cy="303" r="7" fill="#FFFFFF" stroke="#4DA8FF" stroke-width="2.2"/><path d="M294 303 h8" stroke="#4DA8FF" stroke-width="2.2"/>')

    # ---- row 1 (between the MRT and the first avenue)
    ROOF.update({"#FFF4E2": CORAL, "#FFE7A3": "#6F86FF", "#E3F6E8": "#3FB37A", "#FFE3EA": "#FF8FB1", "#E8EEFF": "#7C6CFF"})
    s.append(tree(26, 414, 12) + tree(178, 400, 11, "#58C46B"))
    s.append(box(44, 420, 66, 46, 7, "#FFF4E2", roof="gable", roof_h=26,
                 windows=[(8, 12, 13, 12), (45, 12, 13, 12)], door=(26, 15, 24, "#C98B5E")))
    s.append('<path d="M78 368 c-3-4-9-1-6 3 l6 5 6-5 c3-4-3-7-6-3z" fill="#FFFFFF" opacity=".9" transform="translate(-1 -4)"/>')
    # mailbox by the home
    s.append('<rect x="124" y="402" width="4" height="18" fill="#8A6A4A"/><rect x="116" y="390" width="20" height="14" rx="5" fill="#3FB37A" stroke="#2A8A57" stroke-width="1.2"/><rect x="134" y="386" width="3" height="8" fill="#FF5E5B"/>')
    if B("school"):
        # school
        s.append(box(236, 424, 104, 58, 8, "#FFE7A3", roof="flat",
                     windows=[(8, 14, 13, 12), (26, 14, 13, 12), (64, 14, 13, 12), (82, 14, 13, 12), (8, 34, 13, 12), (82, 34, 13, 12)],
                     door=(44, 16, 26, "#E8A24A")))
        s.append('<rect x="273" y="344" width="30" height="24" fill="#FFE7A3" stroke="#C29A4A" stroke-width="1.4"/><path d="M268 346 L288 328 L308 346 Z" fill="#6F86FF" stroke="#4A5FC4" stroke-width="1.4"/>'
                 '<circle cx="288" cy="357" r="7" fill="#FFFFFF" stroke="#C29A4A" stroke-width="1.2"/><path d="M288 357 V352 M288 357 L291 359" stroke="#4A3B47" stroke-width="1.4" stroke-linecap="round"/>')
        s.append('<path d="M352 424 V380" stroke="#8A6A4A" stroke-width="2"/><path d="M352 380 L370 385 L352 390 Z" fill="#FF5E5B"/>')
    else:
        s.append(empty_lot(234, 342, 130, 86, "school"))
    s.append(tree(372, 430, 11))

    # ---- row 2: park trees on the left, 101 and a shop on the right
    if B("park"):
        s.append(tree(30, 512, 13) + tree(62, 500, 11, "#58C46B") + tree(178, 640, 10, "#58C46B", "pine") + tree(28, 628, 12, "#4DB860", "palm"))
        s.append(flower_patch(40, 586) + flower_patch(166, 488, ("#FFFFFF", "#FF8FB1", "#FFD166")))
    # convenience store
    if B("shop"):
        s.append(box(240, 600, 66, 36, 6, "#E8EEFF", roof="flat", windows=[(6, 14, 24, 16)], door=(38, 18, 24, "#9FB3C8")))
        s.append('<rect x="240" y="566" width="66" height="7" fill="#FF8A3D"/><rect x="240" y="573" width="66" height="5" fill="#3FB37A"/>')
    else:
        s.append(empty_lot(238, 556, 72, 62, "shop"))
    # 101-style tower
    s.append(tower101(320, 626))

    if B("food"):
        # ---- row 3 (mostly under the dock): night market, temple, zoo
        s.append('<path d="M14 684 Q 94 704 180 684" stroke="#8A6A4A" stroke-width="1.5" fill="none"/>')
        for i, lx in enumerate([30, 58, 86, 114, 142, 168]):
            ly = 684 + 16 * math.sin(math.pi * (lx - 14) / 166) - 4
            c = "#FF5E5B" if i % 2 == 0 else "#FFC94A"
            s.append(f'<ellipse cx="{lx}" cy="{ly + 6}" rx="6" ry="7" fill="{c}" stroke="{shade(c, -0.3)}" stroke-width="1.2"/><rect x="{lx - 3}" y="{ly - 2}" width="6" height="3" fill="#8A6A4A"/>')
        for i, (sx, aw) in enumerate([(14, "#FF5E5B"), (70, "#FFC94A"), (126, "#3FB37A")]):
            s.append(box(sx, 754, 48, 26, 5, "#FFF4E2"))
            s.append(f'<rect x="{sx - 4}" y="722" width="56" height="12" rx="4" fill="{aw}" stroke="{shade(aw, -0.3)}" stroke-width="1.2"/>')
            s.append("".join(f'<rect x="{sx + 2 + k * 13}" y="722" width="6" height="12" fill="#FFFFFF" opacity=".75"/>' for k in range(4)))
    else:
        s.append(empty_lot(12, 680, 172, 120, "food"))
    if B("temple"):
        # temple, its swallowtail roof peeking over the dock
        tx0 = 230
        s.append(box(tx0 + 10, 800, 96, 34, 6, "#FFE3C4", door=(36, 24, 26, "#C9452E")))
        s.append(f'<path d="M{tx0} 760 Q {tx0 + 12} 766 {tx0 + 22} 752 L{tx0 + 96} 752 Q {tx0 + 106} 766 {tx0 + 118} 760 L {tx0 + 108} 770 L {tx0 + 10} 770 Z" fill="#F0583E" stroke="#B83A26" stroke-width="1.4"/>'
                 f'<path d="M{tx0 + 16} 752 Q {tx0 + 59} 732 {tx0 + 102} 752 Z" fill="#FF7A54" stroke="#B83A26" stroke-width="1.4"/>'
                 f'<path d="M{tx0 + 4} 758 q-6 -8 -2 -12 M{tx0 + 114} 758 q6 -8 2 -12" stroke="#FFC94A" stroke-width="3" fill="none" stroke-linecap="round"/>'
                 f'<circle cx="{tx0 + 59}" cy="728" r="5" fill="#FFC94A" stroke="#D9A21C"/>')
    else:
        s.append(empty_lot(232, 676, 96, 120, "temple"))
    if B("zoo"):
        # zoo corner: a giraffe looks over the fence
        s.append('<g transform="translate(330 690)">'
                 '<path d="M26 88 V20 q0 -14 10 -16" stroke="#F7C35C" stroke-width="12" stroke-linecap="round" fill="none"/>'
                 '<circle cx="31" cy="44" r="3" fill="#C98536"/><circle cx="27" cy="62" r="3.4" fill="#C98536"/><circle cx="32" cy="28" r="2.6" fill="#C98536"/>'
                 '<ellipse cx="42" cy="6" rx="12" ry="8" fill="#F7C35C" stroke="#C98536" stroke-width="1.4"/>'
                 '<path d="M36 -2 v-7 M44 -2 v-7" stroke="#C98536" stroke-width="2.4" stroke-linecap="round"/><circle cx="45" cy="4" r="1.8" fill="#2A211D"/></g>')
    # traffic
    s.append(car(60, 452, "#FFD23F") + car(300, 446, CORAL, flip=True) + car(150, 658, "#4DA8FF", "scooter")
             + car(206, 560, "#7BD389", "bus") + car(330, 658, "#FF8FB1", "scooter", flip=True))

    if dim:
        s.append(f'<rect width="{W}" height="{H}" fill="rgba(25,45,35,.38)"/>')
    return f'<svg class="abs" style="left:0;top:0" width="{W}" height="{H}" viewBox="0 0 {W} {H}" aria-hidden="true">{"".join(s)}</svg>'
