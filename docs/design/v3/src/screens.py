"""The v3 "畫畫小鎮" screens. Run this to write html/*.html, then render.js."""
import pathlib
import re

from kit import *  # noqa: F401,F403

OUT = pathlib.Path(__file__).resolve().parent.parent / "html"
SCREENS = {}


def screen(name):
    def wrap(fn):
        SCREENS[name] = fn
        return fn
    return wrap


# ---------------------------------------------------------------- shared pieces

def mini_album(size=46):
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 46 46" aria-hidden="true">
<g transform="rotate(-12 23 23)"><rect x="7" y="9" width="30" height="24" rx="4" fill="#FFFFFF" stroke="#C8D6E6" stroke-width="1.5"/><rect x="10" y="12" width="24" height="15" rx="2" fill="#FFD166"/></g>
<g transform="rotate(8 23 25)"><rect x="9" y="13" width="30" height="24" rx="4" fill="#FFFFFF" stroke="#C8D6E6" stroke-width="1.5"/>
<rect x="12" y="16" width="24" height="15" rx="2" fill="#9ED8FF"/><path d="M12 31 L20 23 L26 28 L30 25 L36 31 Z" fill="#6BCB77"/><circle cx="31" cy="20" r="2.6" fill="#FF5E5B"/></g></svg>'''


def mini_book(size=46):
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 46 46" aria-hidden="true">
<rect x="9" y="6" width="30" height="35" rx="4" fill="#FF8FB1" stroke="#E0668C" stroke-width="1.5"/>
<rect x="9" y="6" width="7" height="35" rx="3" fill="#E0668C"/>
<path d="M27 14 l2.4 4.9 5.4.8-3.9 3.8.9 5.4-4.8-2.6-4.8 2.6.9-5.4-3.9-3.8 5.4-.8z" fill="#FFFFFF"/>
<rect x="20" y="33" width="14" height="3" rx="1.5" fill="#FFFFFF" opacity=".8"/></svg>'''


def mini_paper(size=46):
    """A blank sheet with a scribble and a crayon: draw on empty paper."""
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 46 46" aria-hidden="true">
<g transform="rotate(-8 23 23)"><rect x="8" y="6" width="28" height="34" rx="3.5" fill="#FFFFFF" stroke="#C9D6E3" stroke-width="1.6"/>
<path d="M13 30 C 16 20, 20 34, 24 22 S 30 26, 31 18" stroke="#FF5E5B" stroke-width="2.6" fill="none" stroke-linecap="round"/>
<path d="M13 14 q4 -4 8 0" stroke="#4DA8FF" stroke-width="2.4" fill="none" stroke-linecap="round"/></g>
<g transform="rotate(38 35 28)"><rect x="31.5" y="14" width="7" height="20" rx="2" fill="#FFC94A" stroke="#E0A21C" stroke-width="1"/>
<path d="M31.5 34 L35 41 L38.5 34 Z" fill="#F3C9A0"/><path d="M34 39 L35 41 L36 39 Z" fill="#E0A21C"/></g></svg>'''


def hud(child="bear", name="小熊", count=12, dark=False):
    return f'''<button aria-label="切換小朋友" class="abs center" style="left:14px;top:14px;height:56px;padding:0 16px 0 5px;gap:8px;border-radius:28px;background:#FFFFFF;box-shadow:0 6px 14px rgba(30,60,40,.22)">
<span class="center" style="width:46px;height:46px;border-radius:50%;background:#FFF1DA">{animal(child, 40)}</span>
<span style="font-size:17px;font-weight:700;color:{INK}">{name}的小鎮</span></button>
<div class="abs center" aria-label="已經寄了 {count} 張明信片" style="right:66px;top:21px;height:42px;padding:0 14px 0 10px;gap:6px;border-radius:21px;background:#FFFFFF;box-shadow:0 6px 14px rgba(30,60,40,.2)">
<span class="center" style="width:28px;height:28px;border-radius:9px;background:{CORAL}">{icon("mail", 18, "#FFFFFF", 2.2)}</span>
<span style="font-size:18px;font-weight:700;color:{INK}">{count}</span></div>
<button aria-label="家長模式" class="abs center" style="right:14px;top:21px;width:42px;height:42px;border-radius:50%;background:rgba(255,255,255,.82)">{icon("lock", 19, INK_SOFT)}</button>'''


def camera_button(x=None, bottom=50, size=128):
    return f'''<button aria-label="拍照" class="abs center" style="left:50%;margin-left:{-size / 2}px;bottom:{bottom}px;width:{size}px;height:{size}px;border-radius:50%;border:7px solid #FFFFFF;background:radial-gradient(circle at 35% 28%, #FF9A8C 0, {CORAL} 58%, {CORAL_DARK} 100%);box-shadow:0 16px 30px rgba(217,66,63,.45)">
{icon("camera", 60, "#FFFFFF", 2)}
<span class="abs" style="right:6px;top:2px">{solid("sparkle", 24, "#FFE27A")}</span></button>'''


def dock():
    return f'''<div class="abs" style="left:14px;right:14px;bottom:18px;height:100px;border-radius:40px;background:#FFFFFF;box-shadow:0 14px 34px rgba(30,60,40,.28)">
<button aria-label="明信片冊" class="abs center" style="left:18px;top:16px;width:68px;height:68px;border-radius:24px;background:#E8F3FF">{mini_album(48)}</button>
<button aria-label="主題著色本" class="abs center" style="right:18px;top:16px;width:68px;height:68px;border-radius:24px;background:#FFEAF1">{mini_book(48)}</button>
</div>{camera_button(bottom=48)}'''


def walker(x, y, kind="bear", size=46):
    return (f'<span class="abs" style="left:{x - size / 2 + 4}px;top:{y - 5}px;width:{size * 0.7}px;height:8px;border-radius:50%;background:rgba(30,60,40,.22)"></span>'
            f'<span class="abs" style="left:{x - size / 2}px;top:{y - size}px;transform:rotate(-5deg)">{animal(kind, size, "你的角色")}</span>')


def town_overlay(today=True):
    pins = [
        art_pin(78, 344, A + "art_cat.jpg", 60, "家裡的作品，3 張", count=3),
        art_pin(342, 326, A + "art_rocket.jpg", 60, "101 的作品"),
        art_pin(150, 300, A + "art_eagle.jpg", 54, "河濱公園的作品"),
        empty_pin(62, 690, "夜市，還沒畫過"),
        empty_pin(372, 676, "動物園，還沒畫過"),
    ]
    if today:
        pins.append(art_pin(74, 566, A + "art_coffee.jpg", 74, "今天在大安森林公園畫的", ring=SUN, today=True))
    flying = f'<span class="abs" style="left:206px;top:128px;transform:rotate(-8deg)">{pigeon(70, flying=True)}</span>'
    return walker(152, 432) + flying + "".join(pins)


# ---------------------------------------------------------------- screens

@screen("01_home")
def home():
    return page("小鎮地圖", town_map() + town_overlay() + hud() + dock())



@screen("02_place")
def place():
    cards = [(A + "art_coffee.jpg", "10/24", -4), (A + "art_coffee2.jpg", "10/12", 3), (A + "art_cat2.jpg", "9/30", -2)]
    row = "".join(f'''<button aria-label="打開 {d} 的明信片" class="abs" style="left:{22 + k * 150}px;top:0;width:136px;height:150px;transform:rotate({t}deg)">
<span class="abs" style="left:0;top:0;width:136px;height:150px;border-radius:16px;background:#fff;padding:7px;box-shadow:0 8px 16px rgba(30,60,40,.2)">
<img src="{img}" alt="" style="display:block;width:122px;height:112px;border-radius:10px;object-fit:cover">
<span class="center" style="height:24px;font-size:15px;color:{INK_SOFT}">{d}</span></span></button>''' for k, (img, d, t) in enumerate(cards))
    sheet = f'''<div class="abs" style="left:0;right:0;bottom:0;height:410px;border-radius:36px 36px 0 0;background:{PAPER};box-shadow:0 -12px 30px rgba(20,40,30,.25)">
<span class="abs" style="left:175px;top:10px;width:40px;height:5px;border-radius:3px;background:#E3D5BE"></span>
<div class="abs center" style="left:20px;top:30px;width:62px;height:62px;border-radius:20px;background:#DDF3D6">{tree_icon()}</div>
<div class="abs" style="left:96px;top:32px;font-size:23px;font-weight:700">大安森林公園</div>
<div class="abs center" style="left:96px;top:66px;gap:6px;font-size:15px;color:{INK_SOFT}">{icon("mail", 16, INK_SOFT)}<span>3 張明信片</span><span style="opacity:.5">·</span>{icon("clock", 16, INK_SOFT)}<span>最近 10/24</span></div>
<button aria-label="關閉" class="abs center" style="right:18px;top:30px;width:44px;height:44px;border-radius:50%;background:#F1E6D3">{icon("close", 20, INK_SOFT, 2.6)}</button>
<div class="abs" style="left:0;right:0;top:118px;height:160px">{row}</div>
<button aria-label="在這裡再畫一張" class="abs center" style="left:22px;right:22px;bottom:34px;height:78px;border-radius:39px;gap:12px;background:{CORAL};color:#fff;font-size:21px;font-weight:700;box-shadow:0 7px 0 {CORAL_DARK},0 16px 26px rgba(217,66,63,.35)">
{icon("camera", 36, "#FFFFFF", 2.2)}<span>在這裡再畫一張</span></button>
</div>'''
    pin = art_pin(74, 566, A + "art_coffee.jpg", 74, "今天在大安森林公園畫的", ring=SUN, today=True)
    return page("地點：大安森林公園", town_map(dim=True) + pin + sheet)


def tree_icon(size=44):
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 44 44" aria-hidden="true"><ellipse cx="28" cy="34" rx="13" ry="5" fill="#7CCFFF"/>
<rect x="13" y="22" width="4" height="14" rx="2" fill="#A86E43"/><circle cx="15" cy="17" r="10" fill="#4DB860"/><circle cx="12" cy="13" r="3.5" fill="#78D383"/>
<ellipse cx="29" cy="33" rx="4" ry="2.4" fill="#FFFFFF"/></svg>'''


@screen("03_camera")
def camera():
    corner = lambda l, t, r, b: (f'<span class="abs" style="{l};{t};width:44px;height:44px;border-{r}:6px solid #fff;border-{b}:6px solid #fff;'
                                 f'border-{b.split("-")[0]}-{r.split("-")[0] if False else ""}radius:0"></span>')
    frame = "".join([
        '<span class="abs" style="left:34px;top:150px;width:46px;height:46px;border-left:6px solid #fff;border-top:6px solid #fff;border-top-left-radius:18px"></span>',
        '<span class="abs" style="right:34px;top:150px;width:46px;height:46px;border-right:6px solid #fff;border-top:6px solid #fff;border-top-right-radius:18px"></span>',
        '<span class="abs" style="left:34px;top:524px;width:46px;height:46px;border-left:6px solid #fff;border-bottom:6px solid #fff;border-bottom-left-radius:18px"></span>',
        '<span class="abs" style="right:34px;top:524px;width:46px;height:46px;border-right:6px solid #fff;border-bottom:6px solid #fff;border-bottom-right-radius:18px"></span>'])
    body = f'''<img src="{A}photo_coffee_full.jpg" alt="相機畫面" class="abs" style="left:0;top:0;width:390px;height:660px;object-fit:cover;object-position:42% 50%">
<div class="abs" style="left:0;top:0;width:390px;height:660px;background:radial-gradient(ellipse 62% 48% at 50% 52%, rgba(0,0,0,0) 60%, rgba(0,0,0,.42) 100%)"></div>
{frame}
<button aria-label="關閉相機" class="abs center" style="left:16px;top:18px;width:48px;height:48px;border-radius:50%;background:rgba(20,25,30,.45)">{icon("close", 24, "#FFFFFF", 2.6)}</button>
<button aria-label="閃光燈" class="abs center" style="right:16px;top:18px;width:48px;height:48px;border-radius:50%;background:rgba(20,25,30,.45)">{icon("flash", 24, "#FFFFFF", 2.2)}</button>
<div class="abs" style="left:18px;top:566px;width:200px;height:90px">
<span class="abs" style="left:0;top:8px">{animal("bear", 76, "小熊")}</span>
<span class="abs center" style="left:70px;top:0;height:52px;padding:0 14px;gap:6px;border-radius:26px;background:#fff;box-shadow:0 6px 14px rgba(0,0,0,.25)">{icon("sound", 22, SKY, 2.4)}<span style="font-size:16px;font-weight:700;color:{INK};white-space:nowrap">對準你想畫的東西</span></span>
</div>
<div class="abs" style="left:0;top:660px;width:390px;height:184px;background:#14181D"></div>
<button aria-label="從相簿選照片" class="abs" style="left:34px;top:712px;width:62px;height:62px;border-radius:18px;overflow:hidden;border:3px solid #fff"><img src="{A}art_cat2.jpg" alt="" style="width:100%;height:100%;object-fit:cover"></button>
<button aria-label="拍照" class="abs center" style="left:149px;top:695px;width:92px;height:92px;border-radius:50%;border:6px solid #fff;background:#14181D">
<span style="width:70px;height:70px;border-radius:50%;background:{CORAL}"></span></button>
<button aria-label="換鏡頭" class="abs center" style="right:34px;top:712px;width:62px;height:62px;border-radius:50%;background:rgba(255,255,255,.14)">{icon("flip", 30, "#FFFFFF", 2.2)}</button>'''
    return page("拍照", body, bg="#14181D")


def sparkles(points, color="#FFE27A"):
    return "".join(f'<span class="abs" style="left:{x}px;top:{y}px;opacity:{o}">{solid("sparkle", s, color)}</span>' for x, y, s, o in points)


@screen("04_magic")
def magic():
    stars = "".join(f'<span class="abs" style="left:{x}px;top:{y}px;width:{r}px;height:{r}px;border-radius:50%;background:#fff;opacity:{o}"></span>'
                    for x, y, r, o in [(30, 90, 3, .8), (80, 150, 2, .6), (340, 110, 3, .9), (300, 200, 2, .5), (50, 640, 2, .6),
                                       (350, 600, 3, .7), (200, 70, 2, .7), (120, 720, 3, .5), (260, 760, 2, .6), (370, 400, 2, .6)])
    card = f'''<div class="abs" style="left:30px;top:170px;width:330px;height:318px;border-radius:26px;background:#fff;padding:10px;box-shadow:0 0 0 8px rgba(255,255,255,.18),0 24px 50px rgba(10,5,60,.5)">
<div class="abs" style="left:10px;top:10px;width:310px;height:298px;border-radius:18px;overflow:hidden">
<img src="{A}coffee_normal_page.png" alt="" style="position:absolute;left:0;top:0;width:310px;height:298px;object-fit:cover">
<img src="{A}photo_coffee.jpg" alt="" style="position:absolute;left:0;top:0;width:310px;height:298px;object-fit:cover;clip-path:polygon(0 0,58% 0,30% 100%,0 100%)">
<svg style="position:absolute;left:0;top:0" width="310" height="298" aria-hidden="true"><line x1="180" y1="-4" x2="93" y2="302" stroke="#FFE27A" stroke-width="12" opacity=".55" stroke-linecap="round"/><line x1="180" y1="-4" x2="93" y2="302" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/></svg>
</div></div>'''
    body = f'''<div class="abs" style="inset:0;background:radial-gradient(circle at 50% 40%, #6E57FF 0, #3B2FB5 55%, #221C70 100%)"></div>
{stars}
<div class="abs" style="left:0;right:0;top:64px;text-align:center;font-size:24px;font-weight:700;color:#fff;letter-spacing:2px">變變變！</div>
<div class="abs center" style="left:0;right:0;top:102px;gap:6px;color:#CFC7FF;font-size:15px">{icon("sound", 18, "#CFC7FF")}<span>小熊正在把照片變成著色畫</span></div>
{card}
{sparkles([(196, 150, 30, 1), (120, 470, 26, .95), (60, 300, 18, .8), (318, 260, 22, .9), (250, 500, 16, .8), (160, 230, 14, .9)])}
<div class="abs" style="left:34px;top:540px;transform:rotate(-6deg)">{animal("bear", 120, "小熊")}</div>
<svg class="abs" style="left:120px;top:500px" width="140" height="120" viewBox="0 0 140 120" aria-hidden="true">
<path d="M18 100 L72 40" stroke="#5A3A20" stroke-width="7" stroke-linecap="round"/><path d="M18 100 L72 40" stroke="#C98B5E" stroke-width="4" stroke-linecap="round"/>
<path d="M72 40 C 92 20, 110 18, 130 4" stroke="#FFE27A" stroke-width="3" stroke-dasharray="2 9" stroke-linecap="round" fill="none"/>
<path d="M72 28 l3.6 8.4 8.4 3.6 -8.4 3.6 -3.6 8.4 -3.6 -8.4 -8.4 -3.6 8.4 -3.6z" fill="#FFE27A"/></svg>
<div class="abs center" style="left:0;right:0;bottom:70px;gap:16px" aria-label="快好了">
{solid("star", 46, "#FFD23F")}{solid("star", 46, "#FFD23F")}{icon("star", 46, "#8D80E6", 2)}</div>'''
    return page("魔法變身", body, bg="#2B2490")


@screen("05_style")
def style():
    def card(img, top, tilt, badge_bg, badge_icon, label, tape):
        return f'''<button aria-label="{label}" class="abs" style="left:34px;top:{top}px;width:322px;height:276px;transform:rotate({tilt}deg)">
<span class="abs" style="inset:0;border-radius:24px;background:#fff;padding:12px;box-shadow:0 14px 30px rgba(40,60,80,.22)"><img src="{img}" alt="" style="display:block;width:100%;height:100%;object-fit:contain"></span>
<span class="abs" style="left:126px;top:-12px;width:72px;height:24px;background:{tape};opacity:.85;transform:rotate(-3deg)"></span>
<span class="abs center" style="left:-14px;top:-14px;width:66px;height:66px;border-radius:50%;background:{badge_bg};border:5px solid #fff;box-shadow:0 6px 12px rgba(40,60,80,.25)">{badge_icon}</span></button>'''
    confetti = "".join(f'<span class="abs" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;border-radius:3px;background:{c};transform:rotate({r}deg)"></span>'
                       for x, y, w, h, c, r in [(30, 120, 10, 6, CORAL, 20), (340, 140, 8, 8, SUN, 40), (360, 470, 10, 6, TEAL, -30),
                                                (14, 500, 8, 8, GRAPE, 10), (300, 800, 10, 6, PINK, 60), (60, 810, 8, 8, SKY, -20)])
    body = f'''<div class="abs" style="inset:0;background:linear-gradient(180deg,#DDF2FF 0%,#FFF6E8 70%)"></div>{confetti}
<button aria-label="重拍" class="abs center" style="left:16px;top:18px;width:52px;height:52px;border-radius:18px;background:#fff;box-shadow:0 5px 12px rgba(40,60,80,.18)">{icon("back", 26, INK, 2.6)}</button>
<div class="abs" style="left:84px;top:12px">{animal("bear", 64, "小熊")}</div>
<div class="abs center" style="left:150px;top:22px;height:48px;padding:0 16px;gap:8px;border-radius:24px;background:#fff;box-shadow:0 5px 12px rgba(40,60,80,.15)">{icon("sound", 20, SKY, 2.4)}<span style="font-size:17px;font-weight:700">你喜歡哪一張？</span></div>
{card(A + "coffee_normal_page.png", 112, -2.5, SKY, icon("camera", 32, "#fff", 2.2), "真實風格", "#9ED8FF")}
{card(A + "coffee_cute_page.png", 462, 2.5, PINK, solid("sparkle", 32, "#fff"), "可愛風格", "#FFC2D4")}'''
    return page("選風格", body, bg="#FFF6E8")


def tool_crayon(c="#FF5E5B"):
    d, l = shade(c, -0.25), shade(c, 0.15)
    return f'''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true"><g transform="rotate(-28 22 26)">
<rect x="15" y="13" width="14" height="34" rx="3" fill="{c}" stroke="{d}" stroke-width="1.5"/>
<path d="M15 14 L22 1 L29 14 Z" fill="{l}" stroke="{d}" stroke-width="1.5" stroke-linejoin="round"/>
<rect x="15" y="23" width="14" height="13" fill="#fff" opacity=".55"/><path d="M15 26.5 h14 M15 32.5 h14" stroke="{d}" stroke-width="1.2" opacity=".6"/></g></svg>'''


def tool_bucket(c="#FF5E5B"):
    d = shade(c, -0.25)
    return f'''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true">
<path d="M9 19 q13 -20 26 0" stroke="#9FB3C8" stroke-width="2.2" fill="none"/>
<path d="M7 19 h30 l-3.5 25 a4 4 0 0 1 -4 3.5 h-15 a4 4 0 0 1 -4 -3.5 z" fill="#EEF2F7" stroke="#9FB3C8" stroke-width="1.6"/>
<ellipse cx="22" cy="19" rx="15" ry="5" fill="{c}" stroke="{d}" stroke-width="1.4"/>
<path d="M31 21 q2 9 0 13 a2.6 2.6 0 0 0 5.2 0 q-.8 -6 -2.2 -13" fill="{c}" stroke="{d}" stroke-width="1"/>
<rect x="11" y="28" width="5" height="12" rx="2.5" fill="#fff" opacity=".8"/></svg>'''


def tool_rainbow():
    """A crayon in rainbow stripes: its color changes as you draw."""
    bands = ["#FF5E5B", "#FF9F45", "#FFD166", "#5FCB79", "#4DA3FF", "#8C6CFF"]
    stripes = "".join(f'<rect x="{15 + i * 14 / 6:.2f}" y="13" width="{14 / 6 + 0.1:.2f}" height="34" fill="{c}"/>' for i, c in enumerate(bands))
    return f'''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true"><g transform="rotate(-28 22 26)">
{stripes}<rect x="15" y="13" width="14" height="34" rx="3" fill="none" stroke="#8C6CFF" stroke-width="1.5"/>
<path d="M15 14 L22 1 L29 14 Z" fill="#FFD166" stroke="#E0A21C" stroke-width="1.5" stroke-linejoin="round"/>
<rect x="15" y="24" width="14" height="10" fill="#fff" opacity=".5"/></g></svg>'''


def tool_glitter_pen(c="#FF5E5B"):
    """A glitter tube in the chosen color, with sparkles."""
    d, l = shade(c, -0.25), shade(c, 0.15)
    return f'''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true"><g transform="rotate(-24 22 26)">
<rect x="14" y="16" width="16" height="30" rx="6" fill="{l}" stroke="{d}" stroke-width="1.5"/>
<rect x="16" y="6" width="12" height="11" rx="3" fill="{c}" stroke="{d}" stroke-width="1.4"/>
<circle cx="19" cy="26" r="1.8" fill="#fff"/><circle cx="25" cy="31" r="1.6" fill="#fff"/><circle cx="20" cy="37" r="1.6" fill="#fff"/><circle cx="25" cy="41" r="1.3" fill="#fff"/></g>
<path d="M37 7 l1.6 3.8 3.8 1.6 -3.8 1.6 -1.6 3.8 -1.6 -3.8 -3.8 -1.6 3.8 -1.6z" fill="#FFD23F"/><path d="M7 30 l1 2.4 2.4 1 -2.4 1 -1 2.4 -1 -2.4 -2.4 -1 2.4 -1z" fill="#FFD23F"/></svg>'''


def tool_stamp(c="#FF5E5B"):
    """A rubber stamp: a wooden knob and a pad in the chosen color."""
    d = shade(c, -0.25)
    return f'''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true">
<circle cx="22" cy="10" r="7" fill="#E8C79A" stroke="#B9935E" stroke-width="1.5"/><rect x="18" y="15" width="8" height="12" rx="2" fill="#E8C79A" stroke="#B9935E" stroke-width="1.5"/>
<rect x="8" y="26" width="28" height="10" rx="3" fill="#C98B5E" stroke="#8A6A4A" stroke-width="1.5"/>
<rect x="10" y="36" width="24" height="5" rx="1.5" fill="{c}" stroke="{d}" stroke-width="1.2"/>
<path d="M22 43.5 l1.6 3.2 3.5.5-2.5 2.5.6 3.5-3.2-1.7-3.2 1.7.6-3.5-2.5-2.5 3.5-.5z" fill="{c}"/></svg>'''


def tool_eraser():
    return '''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true"><g transform="rotate(-28 22 26)">
<rect x="12" y="10" width="20" height="34" rx="5" fill="#FF8FB1" stroke="#E0668C" stroke-width="1.5"/>
<rect x="12" y="10" width="20" height="14" rx="5" fill="#FFFFFF" stroke="#E0668C" stroke-width="1.5"/>
<rect x="15" y="28" width="5" height="12" rx="2.5" fill="#fff" opacity=".6"/></g></svg>'''


def tool_glitter():
    return '''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true">
<rect x="13" y="17" width="18" height="30" rx="6" fill="#EFE6FF" stroke="#A58CF0" stroke-width="1.6"/><rect x="15" y="8" width="14" height="10" rx="3" fill="#B79CFF" stroke="#8C6CFF" stroke-width="1.4"/>
<circle cx="18" cy="36" r="2" fill="#FF8FB1"/><circle cx="25" cy="31" r="2" fill="#FFD23F"/><circle cx="22" cy="41" r="2" fill="#4DA8FF"/><circle cx="27" cy="39" r="1.6" fill="#2EC4B6"/><circle cx="19" cy="27" r="1.6" fill="#FF5E5B"/>
<path d="M36 6 l1.6 3.8 3.8 1.6 -3.8 1.6 -1.6 3.8 -1.6 -3.8 -3.8 -1.6 3.8 -1.6z" fill="#FFD23F"/><path d="M6 14 l1 2.4 2.4 1 -2.4 1 -1 2.4 -1 -2.4 -2.4 -1 2.4 -1z" fill="#FFD23F"/></svg>'''


def tool_pattern():
    return '''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true"><defs><clipPath id="pc"><circle cx="22" cy="28" r="16"/></clipPath></defs>
<circle cx="22" cy="28" r="17" fill="#FFD166" stroke="#E0A21C" stroke-width="1.6"/>
<g clip-path="url(#pc)"><path d="M0 46 L40 6 M10 52 L50 12" stroke="#FF8FB1" stroke-width="5"/><circle cx="14" cy="22" r="2.6" fill="#fff"/><circle cx="24" cy="18" r="2.6" fill="#fff"/><circle cx="30" cy="30" r="2.6" fill="#fff"/><circle cx="16" cy="35" r="2.6" fill="#fff"/></g></svg>'''


def tool_sticker():
    return '''<svg width="40" height="48" viewBox="0 0 44 52" aria-hidden="true">
<path d="M22 8 l4.6 9.4 10.4 1.5 -7.5 7.3 1.8 10.3 -9.3 -4.9 -9.3 4.9 1.8 -10.3 -7.5 -7.3 10.4 -1.5z" fill="#FF8FB1" stroke="#fff" stroke-width="4" stroke-linejoin="round" paint-order="stroke" style="filter:drop-shadow(0 2px 2px rgba(0,0,0,.25))"/>
<circle cx="22" cy="24" r="1.6" fill="#7A2E46"/><path d="M18.5 23 h.01 M25.5 23 h.01" stroke="#7A2E46" stroke-width="3" stroke-linecap="round"/><path d="M19.5 27 q2.5 2.4 5 0" stroke="#7A2E46" stroke-width="1.6" fill="none" stroke-linecap="round"/></svg>'''


PALETTE = [("紅", "#FF5E5B"), ("橘", "#FF9F45"), ("黃", "#FFD166"), ("綠", "#5FCB79"), ("藍綠", "#2EC4B6"), ("藍", "#4DA3FF"),
           ("紫", "#8C6CFF"), ("粉紅", "#FF8FB1"), ("咖啡", "#A0673F"), ("白", "#FFFFFF"), ("灰", "#9AA5B1"), ("黑", "#34413A")]


def palette_tray(selected="#FF5E5B", top=568):
    pots = []
    for name, c in PALETTE:
        sel = c == selected
        size = 50 if sel else 44
        ring = f"outline:3px solid {c};outline-offset:3px;" if sel and c != "#FFFFFF" else ""
        edge = "box-shadow:inset 0 0 0 2px #E3E8E4;" if c == "#FFFFFF" else f"box-shadow:inset 0 -5px 0 {shade(c, -0.12)};"
        pots.append(f'<button aria-label="{name}色" {"aria-pressed=\"true\"" if sel else ""} style="width:{size}px;height:{size}px;border-radius:50%;border:4px solid #fff;{ring}{edge}'
                    f'background:radial-gradient(circle at 34% 28%, rgba(255,255,255,.65) 0 14%, transparent 15%), {c}"></button>')
    return (f'<div class="abs" style="left:14px;right:14px;top:{top}px;border-radius:28px;background:#fff;padding:14px 10px;'
            f'box-shadow:0 8px 18px rgba(30,60,40,.15);display:grid;grid-template-columns:repeat(6,1fr);row-gap:10px;justify-items:center;align-items:center">'
            + "".join(pots) + "</div>")


def tool_tray(selected="bucket", top=478):
    tools = [("bucket", "油漆桶", tool_bucket(), "#FFE6E5"), ("crayon", "蠟筆", tool_crayon(), "#FFF1D9"),
             ("glitter", "亮晶晶", tool_glitter(), "#F1EAFF"), ("pattern", "花紋", tool_pattern(), "#FFF6D6"),
             ("sticker", "貼紙", tool_sticker(), "#FFE9F1")]
    out = []
    for key, label, art, bg in tools:
        sel = key == selected
        out.append(f'<button aria-label="{label}" {"aria-pressed=\"true\"" if sel else ""} class="center" style="width:62px;height:70px;border-radius:22px;'
                   f'background:{bg if sel else "#FFFFFF"};{"transform:translateY(-8px);box-shadow:0 8px 0 " + shade(bg, -0.12) + ";" if sel else "box-shadow:0 4px 0 #E8E2D6;"}">{art}</button>')
    return f'<div class="abs center" style="left:0;right:0;top:{top}px;gap:9px">{"".join(out)}</div>'


def blurred_place():
    return (f'<div class="abs" style="left:0;top:0;width:390px;height:844px;overflow:hidden">'
            f'<div style="position:absolute;left:0;top:0;width:390px;height:844px;transform:scale(2.4);transform-origin:70px 560px;filter:blur(9px)">{town_map()}</div></div>'
            f'<div class="abs" style="inset:0;background:rgba(255,248,236,.55)"></div>')


def coloring_top(place="大安森林公園", date="10/24"):
    return f'''<button aria-label="回到地圖" class="abs center" style="left:14px;top:16px;width:56px;height:56px;border-radius:20px;background:#fff;box-shadow:0 5px 12px rgba(30,60,40,.18)">{icon("map", 30, GRASS_DARK, 2.2)}</button>
<div class="abs center" style="left:50%;transform:translateX(-50%);top:24px;height:40px;gap:6px;padding:0 14px;border-radius:20px;background:#fff;border:2px dashed #E89A4C;color:#8A4B12;font-size:15px;font-weight:700;white-space:nowrap">{icon("pin", 17, "#E0702A", 2.4)}<span>{place}</span><span style="font-weight:400;color:#B0703A">{date}</span></div>
<button aria-label="復原" class="abs center" style="right:14px;top:16px;width:56px;height:56px;border-radius:20px;background:#fff;box-shadow:0 5px 12px rgba(30,60,40,.18)">{icon("undo", 30, GRAPE, 2.4)}</button>'''


def postcard(img, extra=""):
    return f'''<div class="abs" style="left:18px;top:96px;width:354px;height:356px;border-radius:22px;background:#fff;padding:12px;box-shadow:0 16px 34px rgba(30,60,40,.22);transform:rotate(-1deg)">
<img src="{img}" alt="正在塗色的咖啡杯" style="display:block;width:330px;height:308px;border-radius:12px;object-fit:contain">{extra}
<span class="abs" style="left:14px;bottom:8px;width:170px;height:2px;background:repeating-linear-gradient(90deg,#E8DCC8 0 8px,transparent 8px 14px)"></span></div>
<div class="abs" style="right:10px;top:72px">{stamp(A + "photo_coffee.jpg", 76, 90, 7)}</div>
<div class="abs" style="right:38px;top:118px">{postmark("10.24", 58)}</div>'''


@screen("06_coloring")
def coloring():
    done = f'''<button aria-label="畫好了，寄到地圖" class="abs center" style="left:50%;margin-left:-110px;bottom:34px;width:220px;height:80px;border-radius:40px;gap:10px;background:{GRASS};box-shadow:0 7px 0 {GRASS_DARK},0 16px 26px rgba(63,160,82,.35)">
{icon("check", 42, "#fff", 3.2)}{icon("mail", 30, "#fff", 2.4)}</button>'''
    friend = f'<div class="abs" style="left:6px;top:398px;transform:rotate(-8deg)">{animal("bear", 62, "小熊陪你畫")}</div>'
    return page("著色", blurred_place() + coloring_top() + postcard(A + "coloring_progress.png") + friend + tool_tray("bucket") + palette_tray() + done, bg=PAPER)


def sticker_art(kind, size=66):
    S = 'stroke="#fff" stroke-width="5" stroke-linejoin="round" paint-order="stroke"'
    face = '<circle cx="26" cy="32" r="2.4" fill="#5A2E1E"/><circle cx="38" cy="32" r="2.4" fill="#5A2E1E"/><path d="M27 38 q5 4 10 0" stroke="#5A2E1E" stroke-width="2" fill="none" stroke-linecap="round"/>'
    art = {
        "star": f'<path d="M32 6 l7.6 15.5 17 2.5 -12.3 12 2.9 17 -15.2 -8 -15.2 8 2.9 -17 -12.3 -12 17 -2.5z" fill="#FFD23F" {S}/>' + face,
        "heart": f'<path d="M32 56 C 6 40, 4 16, 20 12 C 27 10, 31 15, 32 18 C 33 15, 37 10, 44 12 C 60 16, 58 40, 32 56 Z" fill="#FF6F91" {S}/>' + face,
        "flower": "".join(f'<circle cx="{32 + 15 * math.cos(math.radians(a))}" cy="{32 + 15 * math.sin(math.radians(a))}" r="11" fill="#FF8FB1" {S}/>' for a in range(-90, 270, 72))
                  + "".join(f'<circle cx="{32 + 15 * math.cos(math.radians(a))}" cy="{32 + 15 * math.sin(math.radians(a))}" r="11" fill="#FF8FB1"/>' for a in range(-90, 270, 72))
                  + '<circle cx="32" cy="32" r="10" fill="#FFD23F"/>',
        "sun": "".join(f'<path d="M{32 + 20 * math.cos(math.radians(a)):.1f} {32 + 20 * math.sin(math.radians(a)):.1f} L{32 + 29 * math.cos(math.radians(a)):.1f} {32 + 29 * math.sin(math.radians(a)):.1f}" stroke="#FFB020" stroke-width="6" stroke-linecap="round"/>' for a in range(0, 360, 45))
               + f'<circle cx="32" cy="32" r="17" fill="#FFD23F" {S}/>' + face,
        "rainbow": f'<path d="M6 46 A26 26 0 0 1 58 46" stroke="#fff" stroke-width="30" fill="none"/>'
                   + "".join(f'<path d="M{6 + k * 5} 46 A{26 - k * 5} {26 - k * 5} 0 0 1 {58 - k * 5} 46" stroke="{c}" stroke-width="5.5" fill="none"/>' for k, c in enumerate(["#FF5E5B", "#FFB020", "#FFD23F", "#5FCB79", "#4DA3FF"]))
                   + '<circle cx="10" cy="48" r="7" fill="#fff"/><circle cx="54" cy="48" r="7" fill="#fff"/>',
        "cloud": f'<path d="M14 48 a10 10 0 0 1 2 -20 a14 14 0 0 1 26 -6 a11 11 0 0 1 10 26 z" fill="#E6F4FF" {S}/>' + face.replace("cy=\"32\"", "cy=\"36\"").replace("M27 38", "M27 42"),
        "butterfly": f'<ellipse cx="20" cy="24" rx="13" ry="11" fill="#8C6CFF" {S}/><ellipse cx="44" cy="24" rx="13" ry="11" fill="#8C6CFF" {S}/><ellipse cx="22" cy="42" rx="10" ry="9" fill="#2EC4B6" {S}/><ellipse cx="42" cy="42" rx="10" ry="9" fill="#2EC4B6" {S}/>'
                     '<ellipse cx="20" cy="24" rx="13" ry="11" fill="#8C6CFF"/><ellipse cx="44" cy="24" rx="13" ry="11" fill="#8C6CFF"/><ellipse cx="22" cy="42" rx="10" ry="9" fill="#2EC4B6"/><ellipse cx="42" cy="42" rx="10" ry="9" fill="#2EC4B6"/>'
                     '<rect x="29" y="16" width="6" height="36" rx="3" fill="#5A3A70"/><circle cx="20" cy="24" r="4" fill="#fff" opacity=".7"/><circle cx="44" cy="24" r="4" fill="#fff" opacity=".7"/>',
        "rocket": f'<path d="M32 6 C 44 16, 46 32, 40 48 H24 C 18 32, 20 16, 32 6 Z" fill="#F3F6FA" {S}/><circle cx="32" cy="26" r="6" fill="#4DA3FF" stroke="#2C7FD6" stroke-width="2"/>'
                  '<path d="M24 40 L14 50 L24 50 Z M40 40 L50 50 L40 50 Z" fill="#FF5E5B"/><path d="M27 50 Q32 62 37 50 Z" fill="#FFB020"/>',
    }[kind]
    return f'<svg width="{size}" height="{size}" viewBox="0 0 64 64" aria-hidden="true" style="filter:drop-shadow(0 3px 3px rgba(0,0,0,.2))">{art}</svg>'


STICKERS = [("star", "星星"), ("heart", "愛心"), ("flower", "花"), ("sun", "太陽"), ("rainbow", "彩虹"), ("cloud", "雲"), ("butterfly", "蝴蝶"), ("rocket", "火箭")]


@screen("07_stickers")
def stickers():
    placed = (f'<span class="abs" style="left:24px;top:22px;transform:rotate(-12deg)">{sticker_art("star", 70)}</span>'
              f'<span class="abs" style="left:250px;top:226px;transform:rotate(10deg)">{sticker_art("heart", 60)}</span>')
    grid = "".join(f'<button aria-label="{label}貼紙" class="center" style="width:78px;height:78px;border-radius:24px;background:{bg}">{sticker_art(k, 62)}</button>'
                   for (k, label), bg in zip(STICKERS, ["#FFF6D6", "#FFE9F1", "#FFE9F1", "#FFF6D6", "#E8F3FF", "#E8F3FF", "#F1EAFF", "#FFEDE8"]))
    tabs = "".join(f'<button aria-label="{label}" class="center" style="width:56px;height:44px;border-radius:16px;background:{bg}">{art}</button>'
                   for label, bg, art in [("可愛貼紙", "#FFE9F1", solid("heart", 24, "#FF6F91")), ("動物貼紙", "#FFFFFF", animal("cat", 30)),
                                          ("交通貼紙", "#FFFFFF", icon("map", 22, INK_SOFT)), ("我的照片貼紙", "#FFFFFF", icon("camera", 22, INK_SOFT))])
    sheet = f'''<div class="abs" style="left:0;right:0;bottom:0;height:372px;border-radius:34px 34px 0 0;background:#fff;box-shadow:0 -12px 30px rgba(20,40,30,.18)">
<span class="abs" style="left:175px;top:10px;width:40px;height:5px;border-radius:3px;background:#E5E0D6"></span>
<div class="abs center" style="left:0;right:0;top:26px;gap:10px">{tabs}</div>
<div class="abs" style="left:22px;right:22px;top:90px;display:grid;grid-template-columns:repeat(4,1fr);gap:14px;justify-items:center">{grid}</div>
<button aria-label="收起貼紙" class="abs center" style="left:50%;margin-left:-36px;bottom:26px;width:72px;height:44px;border-radius:22px;background:#F1EEE8">{icon("chevron", 24, INK_SOFT, 2.6).replace('viewBox="0 0 24 24"', 'viewBox="0 0 24 24" style="transform:rotate(90deg)"')}</button>
</div>'''
    return page("貼紙", blurred_place() + coloring_top() + postcard(A + "coloring_progress.png", placed) + sheet, bg=PAPER)


@screen("08_sent")
def sent():
    conf = []
    import random
    rnd = random.Random(7)
    for _ in range(46):
        x, y = rnd.randint(0, 380), rnd.randint(90, 760)
        c = rnd.choice([CORAL, SUN, SKY, GRASS, PINK, GRAPE, TEAL])
        w, h = rnd.choice([(10, 6), (8, 8), (12, 5)])
        conf.append(f'<span class="abs" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px;border-radius:2px;background:{c};transform:rotate({rnd.randint(0, 90)}deg)"></span>')
    burst = '<div class="abs" style="left:-100px;top:120px;width:590px;height:590px;background:repeating-conic-gradient(from 0deg at 50% 50%, rgba(255,255,255,.42) 0 7deg, rgba(255,255,255,0) 7deg 18deg);-webkit-mask:radial-gradient(circle, #000 0 30%, transparent 62%);mask:radial-gradient(circle, #000 0 30%, transparent 62%)"></div>'
    card = f'''<div class="abs" style="left:64px;top:250px;width:250px;height:262px;border-radius:20px;background:#fff;padding:10px;transform:rotate(-9deg);box-shadow:0 24px 40px rgba(20,40,30,.35)">
<img src="{A}art_coffee.jpg" alt="畫好的咖啡杯" style="display:block;width:230px;height:214px;border-radius:12px;object-fit:cover"></div>
<div class="abs" style="left:236px;top:226px;transform:rotate(8deg)">{stamp(A + "photo_coffee.jpg", 62, 74, 0)}</div>
<div class="abs center" style="left:40px;top:430px;width:118px;height:118px;border-radius:50%;border:5px solid rgba(217,66,63,.9);transform:rotate(-16deg);color:rgba(217,66,63,.95);flex-direction:column;background:rgba(255,255,255,.55)">
<span style="font-size:30px;font-weight:700;letter-spacing:2px">寄出</span><span style="font-size:13px">2026.10.24</span></div>'''
    trail = '<svg class="abs" style="left:0;top:0" width="390" height="844" aria-hidden="true"><path d="M300 250 C 330 200, 330 160, 290 130" stroke="#fff" stroke-width="4" stroke-dasharray="3 12" stroke-linecap="round" fill="none"/></svg>'
    body = (town_map() + '<div class="abs" style="inset:0;background:radial-gradient(circle at 50% 46%, rgba(255,240,190,.75) 0, rgba(255,240,190,.25) 55%, rgba(255,255,255,0) 80%)"></div>'
            + burst + "".join(conf) + trail + card
            + f'<div class="abs" style="left:236px;top:150px;transform:rotate(-10deg)">{pigeon(118, letter=False, flying=True)}</div>'
            + hud(count=13)
            + f'<span class="abs center" style="right:56px;top:72px;height:30px;padding:0 10px;border-radius:15px;background:{CORAL};color:#fff;font-size:16px;font-weight:700;box-shadow:0 4px 10px rgba(217,66,63,.4)">+1</span>'
            + f'''<div class="abs center" style="left:0;right:0;bottom:40px;gap:22px">
<button aria-label="回到小鎮" class="center" style="width:86px;height:86px;border-radius:50%;background:#fff;box-shadow:0 7px 0 #DCD3C3,0 14px 24px rgba(20,40,30,.25)">{icon("map", 40, GRASS_DARK, 2.2)}</button>
<button aria-label="再畫一張" class="center" style="width:104px;height:104px;border-radius:50%;background:{CORAL};border:6px solid #fff;box-shadow:0 14px 26px rgba(217,66,63,.45)">{icon("camera", 48, "#fff", 2.1)}</button></div>''')
    return page("寄出囉", body)


@screen("09_album")
def album():
    chips = [("全部", "12", True, None), ("最愛", None, False, solid("heart", 16, "#FF6F91")), ("公園", "3", False, None), ("家裡", "3", False, None), ("101", "2", False, None)]
    chip_html = "".join(f'<button class="center" style="flex:none;height:44px;padding:0 16px;gap:6px;border-radius:22px;font-size:16px;font-weight:700;'
                        f'background:{CORAL if sel else "#fff"};color:{"#fff" if sel else INK};box-shadow:0 3px 0 {CORAL_DARK if sel else "#E8DCC8"}">{ic or ""}<span>{t}</span>'
                        f'{f"<span style=\"opacity:.75;font-weight:400\">{n}</span>" if n else ""}</button>' for t, n, sel, ic in chips)

    def pc(img, date, fav, tilt):
        heart = solid("heart", 22, "#FF6F91") if fav else icon("heart", 22, "#C9BBA6", 2.2)
        return f'''<button aria-label="{date} 的明信片" style="position:relative;width:166px;height:190px;border-radius:18px;background:#fff;padding:8px;box-shadow:0 8px 16px rgba(120,90,40,.16);transform:rotate({tilt}deg);text-align:left">
<img src="{img}" alt="" style="display:block;width:150px;height:140px;border-radius:12px;object-fit:cover">
<span class="abs" style="left:12px;bottom:10px;font-size:15px;color:{INK_SOFT}">{date}</span><span class="abs" style="right:10px;bottom:8px">{heart}</span></button>'''
    section = lambda title, n, icon_html: (f'<div class="center" style="justify-content:flex-start;gap:8px;margin:18px 0 12px 22px;font-size:19px;font-weight:700">'
                                           f'{icon_html}<span>{title}</span><span style="font-weight:400;color:{INK_SOFT};font-size:15px">{n} 張</span></div>')
    grid = lambda cards: f'<div style="display:grid;grid-template-columns:repeat(2,166px);gap:16px 14px;justify-content:center">{cards}</div>'
    body = f'''<div class="abs" style="inset:0;background-color:{PAPER};background-image:radial-gradient(#F0E2C8 1.4px, transparent 1.5px);background-size:20px 20px"></div>
<button aria-label="回到地圖" class="abs center" style="left:14px;top:16px;width:56px;height:56px;border-radius:20px;background:#fff;box-shadow:0 5px 12px rgba(120,90,40,.18)">{icon("map", 30, GRASS_DARK, 2.2)}</button>
<div class="abs center" style="left:0;right:0;top:22px;gap:10px;font-size:23px;font-weight:700">{mini_album(40)}<span>明信片冊</span></div>
<div class="abs" style="left:0;right:0;top:88px;display:flex;gap:10px;padding:0 16px;overflow:hidden">{chip_html}</div>
<div class="abs" style="left:0;right:0;top:140px">
{section("大安森林公園", 3, tree_icon(28))}
{grid(pc(A + "art_coffee.jpg", "10/24", True, -1.5) + pc(A + "art_coffee2.jpg", "10/12", False, 1.5) + pc(A + "art_cat2.jpg", "9/30", True, 1) + pc(A + "art_eagle.jpg", "9/18", False, -1))}
{section("家裡", 3, animal("bear", 28))}
{grid(pc(A + "art_cat.jpg", "9/12", False, 1.5) + pc(A + "art_rocket.jpg", "9/02", True, -1.5))}
</div>'''
    return page("明信片冊", body, bg=PAPER)


def toggle(on):
    return (f'<span style="position:relative;display:inline-block;width:54px;height:32px;border-radius:16px;background:{GRASS if on else "#D6D9D4"}">'
            f'<span style="position:absolute;top:3px;{"right" if on else "left"}:3px;width:26px;height:26px;border-radius:50%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.2)"></span></span>')


def logo(size=40):
    return f'''<svg width="{size}" height="{size}" viewBox="0 0 48 48" aria-hidden="true">
<rect x="2" y="2" width="44" height="44" rx="14" fill="{CORAL}"/>
<path d="M10 34 C 14 26, 20 24, 24 30 C 28 22, 34 20, 38 30 L38 38 L10 38 Z" fill="#6BCB77"/>
<rect x="28" y="12" width="7" height="20" rx="1.5" fill="#FFFFFF"/><path d="M28 12 L31.5 6 L35 12 Z" fill="#FFD23F"/>
<path d="M14 16 l1.6 3.4 3.6.5-2.6 2.6.6 3.6-3.2-1.7-3.2 1.7.6-3.6-2.6-2.6 3.6-.5z" fill="#FFD23F"/></svg>'''


@screen("10_share")
def share():
    card = f"""<div class="abs" style="left:45px;top:78px;width:300px;height:360px;border-radius:24px;overflow:hidden;background:linear-gradient(180deg,#DDF2FF 0%,#FFF6E8 58%);box-shadow:0 14px 34px rgba(40,50,60,.22)">
<svg class="abs" style="left:0;bottom:0" width="300" height="110" viewBox="0 0 300 110" aria-hidden="true">
<path d="M0 64 C 60 36, 110 40, 150 60 C 200 36, 250 34, 300 56 L300 110 L0 110 Z" fill="#A6DE97"/>
<path d="M0 84 C 80 70, 160 76, 300 72 L300 110 L0 110 Z" fill="#8CD27D"/>
{tree(36, 96, 9) + tree(58, 100, 7, "#58C46B") + tree(140, 90, 8, "#4DB860", "pine")}</svg>
<div class="abs" style="left:34px;top:24px;width:232px;height:232px;border-radius:16px;background:#fff;padding:8px;transform:rotate(-3deg);box-shadow:0 10px 20px rgba(40,50,60,.2)">
<img src="{A}art_coffee.jpg" alt="畫好的咖啡杯" style="display:block;width:216px;height:216px;border-radius:10px;object-fit:cover"></div>
<span class="abs" style="left:226px;top:196px;transform:rotate(14deg)">{sticker_art("star", 56)}</span>
<div class="abs center" style="left:18px;top:274px;gap:8px">{animal("bear", 38)}<span class="center" style="gap:4px;font-size:15px;color:{INK_SOFT}">{place_icon("park", 26)}公園 · 2026/10/24</span></div>
<div class="abs center" style="right:12px;bottom:12px;gap:6px;height:36px;padding:0 10px 0 4px;border-radius:18px;background:rgba(255,255,255,.92)">{logo(28)}<span style="font-size:13px;font-weight:700">畫畫小鎮</span></div>
</div>"""
    def row(ic, title, right, note=""):
        n = f'<div style="font-size:13px;color:{note[0]};margin:-4px 0 8px 32px">{note[1]}</div>' if note else ""
        return (f'<div style="border-bottom:1px solid #EFEAE0"><div class="center" style="justify-content:space-between;min-height:52px;padding:0 2px">'
                f'<span class="center" style="gap:10px;font-size:16px">{ic}<span>{title}</span></span>{right}</div>{n}</div>')
    seg = ('<span style="display:grid;grid-template-columns:repeat(3,auto);gap:4px;padding:3px;border-radius:12px;background:#F0ECE4">'
           + "".join(f'<span class="center" style="height:32px;padding:0 9px;border-radius:9px;font-size:13px;{"background:#fff;font-weight:700;box-shadow:0 1px 3px rgba(0,0,0,.12)" if o == "只說公園" else "color:" + INK_SOFT}">{o}</span>' for o in ["不顯示", "只說公園", "地點名稱"])
           + "</span>")
    body = f"""<div class="abs" style="inset:0;background:#F7F5F0"></div>
<button aria-label="返回" class="abs center" style="left:10px;top:16px;width:48px;height:48px">{icon("back", 28, INK, 2.4)}</button>
<div class="abs" style="left:0;right:0;top:26px;text-align:center;font-size:20px;font-weight:700">分享這張畫</div>
{card}
<div class="abs" style="left:22px;right:22px;top:452px">
{row(icon("users", 22, INK_SOFT), "名字和年紀", toggle(False))}
{row(icon("pin", 22, INK_SOFT), "地點", seg)}
{row(icon("camera", 22, INK_SOFT), "放上原本的照片", toggle(False), ("#C2410C", "照片裡有人的臉，建議不要放"))}</div>
<div class="abs" style="left:22px;right:22px;top:654px;display:grid;grid-template-columns:1fr 1.4fr;gap:12px">
<button class="center" style="height:62px;border-radius:20px;gap:8px;background:#fff;border:2px solid #E3DED3;font-size:17px;font-weight:700">{icon("download", 24, INK)}<span>存到相簿</span></button>
<button class="center" style="height:62px;border-radius:20px;gap:8px;background:{CORAL};color:#fff;font-size:17px;font-weight:700;box-shadow:0 5px 0 {CORAL_DARK}">{icon("share", 24, "#fff")}<span>分享到 LINE、IG…</span></button></div>
<div class="abs" style="left:22px;right:22px;top:736px;font-size:13px;color:{INK_SOFT};line-height:1.7">
<div class="center" style="justify-content:flex-start;gap:6px">{icon("shield", 16, GRASS_DARK)}分享的圖片已經拿掉 GPS、拍攝時間和手機資訊</div>
<div class="center" style="justify-content:flex-start;gap:6px">{icon("lock", 16, INK_SOFT)}在家長鎖後面，小朋友不會自己分享</div></div>"""
    return page("分享", body, bg="#F7F5F0")


@screen("11_welcome")
def welcome():
    tiles = []
    for k in ANIMALS:
        sel = k == "bear"
        pressed = ' aria-pressed="true"' if sel else ""
        look = (f"box-shadow:0 0 0 4px {CORAL},0 8px 16px rgba(217,66,63,.3);transform:scale(1.08)" if sel
                else "box-shadow:0 5px 0 #E3DACB")
        check = (f'<span class="abs center" style="right:-8px;top:-8px;width:28px;height:28px;border-radius:50%;background:{CORAL};border:3px solid #fff">'
                 f'{icon("check", 16, "#fff", 3.4)}</span>') if sel else ""
        tiles.append(f'<button aria-label="{ANIMAL_NAMES[k]}"{pressed} class="center" style="position:relative;width:78px;height:78px;border-radius:26px;background:#fff;{look}">{animal(k, 60)}{check}</button>')
    body = f'''<div class="abs" style="inset:0;background:linear-gradient(180deg,#8FD6FF 0%,#DDF3FF 46%,#FFF6E8 46.1%)"></div>
<svg class="abs" style="left:0;top:300px" width="390" height="100" viewBox="0 0 390 100" aria-hidden="true">
<path d="M0 90 C 60 40, 110 40, 170 70 C 220 30, 300 30, 390 66 L390 100 L0 100 Z" fill="#A6DE97"/>
{tower101(318, 98, 0.42)}{tree(60, 92, 12) + tree(86, 96, 9, "#58C46B") + tree(250, 84, 9, "#4DB860", "pine")}</svg>
{cloud(24, 70, 0.8)}{cloud(250, 130, 0.6)}
<div class="abs" style="left:24px;top:120px">{pigeon(150)}</div>
<div class="abs" style="left:176px;top:96px;width:192px;padding:16px 18px;border-radius:24px;background:#fff;box-shadow:0 8px 20px rgba(40,70,90,.18);font-size:20px;font-weight:700;line-height:1.45">歡迎來到<br>畫畫小鎮！<div style="margin-top:6px;font-size:15px;font-weight:400;color:{INK_SOFT}" class="center">{icon("sound", 18, SKY, 2.4)}<span style="margin-left:6px">選一隻動物當你</span></div></div>
<div class="abs" style="left:30px;right:30px;top:420px;display:grid;grid-template-columns:repeat(4,78px);justify-content:space-between;row-gap:18px">{"".join(tiles)}</div>
<div class="abs" style="left:30px;right:30px;top:626px">
<div style="font-size:14px;color:{INK_SOFT};margin:0 0 6px 6px">名字（爸媽幫忙打）</div>
<div class="center" style="justify-content:space-between;height:58px;padding:0 18px;border-radius:20px;background:#fff;border:2px solid #E3DACB;font-size:20px;font-weight:700">小熊<span style="font-size:14px;font-weight:400;color:{INK_SOFT}">4 歲</span></div></div>
<button aria-label="出發" class="abs center" style="left:50%;margin-left:-110px;bottom:40px;width:220px;height:76px;border-radius:38px;gap:10px;background:{GRASS};color:#fff;font-size:22px;font-weight:700;box-shadow:0 7px 0 {GRASS_DARK},0 16px 26px rgba(63,160,82,.35)">
<span>出發</span>{icon("chevron", 30, "#fff", 3)}</button>'''
    return page("選角色", body, bg="#FFF6E8")


@screen("12_parent")
def parent():
    def card(title, inner):
        return (f'<div style="margin:0 16px 14px;border-radius:22px;background:#fff;padding:14px 16px;box-shadow:0 2px 0 #ECE7DD">'
                f'<div style="font-size:14px;color:{INK_SOFT};margin-bottom:6px">{title}</div>{inner}</div>')
    kid = lambda a, n, age: (f'<div class="center" style="justify-content:space-between;height:58px"><span class="center" style="gap:12px">'
                             f'<span class="center" style="width:46px;height:46px;border-radius:50%;background:#FFF1DA">{animal(a, 40)}</span>'
                             f'<span style="font-size:18px;font-weight:700">{n}</span><span style="font-size:15px;color:{INK_SOFT}">{age}</span></span>{icon("chevron", 20, "#B9B2A4", 2.4)}</div>')
    seg = lambda opts, sel: ('<div style="display:grid;grid-template-columns:repeat(' + str(len(opts)) + ',1fr);gap:6px;padding:4px;border-radius:14px;background:#F3F0EA">'
                             + "".join(f'<span class="center" style="height:38px;border-radius:11px;font-size:15px;{"background:#fff;font-weight:700;box-shadow:0 1px 3px rgba(0,0,0,.12)" if o == sel else "color:" + INK_SOFT}">{o}</span>' for o in opts) + "</div>")
    rowlink = lambda ic, t, color=INK: (f'<div class="center" style="justify-content:space-between;height:50px"><span class="center" style="gap:10px;font-size:17px;color:{color}">{ic}<span>{t}</span></span>{icon("chevron", 20, "#B9B2A4", 2.4)}</div>')
    body = f'''<div class="abs" style="inset:0;background:#F7F5F0"></div>
<div class="abs center" style="left:0;right:0;top:0;height:76px;justify-content:space-between;padding:0 16px">
<button aria-label="回到小鎮" class="center" style="width:44px;height:44px">{icon("back", 28, INK, 2.4)}</button>
<span class="center" style="gap:8px;font-size:20px;font-weight:700">{logo(30)}家長模式</span><span style="width:44px"></span></div>
<div class="abs" style="left:0;right:0;top:80px">
{card("小朋友", kid("bear", "小熊", "4 歲") + '<div style="height:1px;background:#F0EBE2"></div>' + kid("rabbit", "小兔", "2 歲") + f'<div class="center" style="justify-content:flex-start;gap:8px;height:46px;color:{SKY_DARK};font-size:16px;font-weight:700">{icon("plus", 20, SKY_DARK, 2.6)}新增小朋友</div>')}
{card("每天可以玩多久", f'<div class="center" style="justify-content:space-between;margin-bottom:10px"><span class="center" style="gap:8px;font-size:17px">{icon("clock", 22, INK_SOFT)}時間到了，小熊會說晚安</span></div>' + seg(["15 分", "30 分", "45 分", "60 分"], "30 分"))}
{card("我們的地方", '<div style="font-size:14px;color:' + INK_SOFT + ';margin-bottom:10px">不使用定位，小朋友寄出明信片時自己選地方</div>' + "".join(f'<span class="center" style="display:inline-flex;gap:4px;height:40px;padding:0 12px 0 6px;margin:0 8px 8px 0;border-radius:20px;background:#F6F2EA;font-size:15px">{place_icon(k, 30)}{t}</span>' for k, t in [("park", "大安森林公園"), ("park", "青年公園"), ("grandma", "台中阿嬤家"), ("school", "向日葵幼兒園")]) + f'<span class="center" style="display:inline-flex;gap:4px;height:40px;padding:0 12px;border-radius:20px;border:2px dashed #D6CFC2;color:{SKY_DARK};font-size:15px;font-weight:700">{icon("plus", 16, SKY_DARK, 2.6)}新增</span>')}
{card("其他", rowlink(icon("shield", 22, GRASS_DARK), "隱私與安全") + rowlink(icon("info", 22, INK_SOFT), "開放原始碼授權"))}
</div>'''
    return page("家長模式", body, bg="#F7F5F0")



@screen("99_guide")
def guide():
    sw = lambda c, n, use, dark=False: (f'<div style="width:168px"><div style="height:74px;border-radius:18px;background:{c};{"box-shadow:inset 0 0 0 2px #E8E1D4;" if c in (PAPER, "#FFFFFF") else ""}"></div>'
                                         f'<div style="margin-top:6px;font-size:16px;font-weight:700">{n}</div><div style="font-size:13px;color:{INK_SOFT}">{c} · {use}</div></div>')
    h = lambda t: f'<div style="font-size:22px;font-weight:700;margin:30px 0 14px">{t}</div>'
    colors = "".join([sw(CORAL, "珊瑚紅", "拍照、主要動作"), sw(SUN, "向日葵黃", "今天、獎勵"), sw(SKY, "天空藍", "作品、相簿"),
                      sw(GRASS, "草地綠", "完成、地圖"), sw(GRAPE, "葡萄紫", "復原、魔法"), sw(PINK, "櫻花粉", "貼紙、最愛"),
                      sw(PAPER, "明信片米", "背景"), sw(INK, "森林墨", "文字")])
    icons_row = "".join(f'<span class="center" style="width:52px;height:52px;border-radius:16px;background:#fff">{icon(n, 28, INK)}</span>'
                        for n in ["camera", "album", "map", "pin", "mail", "undo", "bucket", "crayon", "wand", "star", "heart", "check", "share", "lock"])
    animals = "".join(f'<div style="text-align:center"><span class="center" style="width:74px;height:74px;border-radius:24px;background:#fff">{animal(k, 58)}</span><div style="font-size:13px;color:{INK_SOFT};margin-top:4px">{ANIMAL_NAMES[k]}</div></div>' for k in ANIMALS)
    stickers_row = "".join(sticker_art(k, 56) for k, _ in STICKERS)
    buttons = f'''<div style="display:flex;align-items:flex-end;gap:26px">
<div style="position:relative;width:128px;height:128px">{camera_button(bottom=0).replace("left:50%;margin-left:-64px;", "left:0;")}</div>
<button class="center" style="width:200px;height:76px;border-radius:38px;gap:10px;background:{GRASS};box-shadow:0 7px 0 {GRASS_DARK}">{icon("check", 40, "#fff", 3.2)}{icon("mail", 28, "#fff", 2.4)}</button>
<span class="center" style="width:68px;height:68px;border-radius:24px;background:#E8F3FF">{mini_album(48)}</span>
<span class="center" style="width:62px;height:70px;border-radius:22px;background:#FFE6E5;box-shadow:0 8px 0 {shade("#FFE6E5", -0.12)}">{tool_bucket()}</span>
<span class="center" style="width:62px;height:70px;border-radius:22px;background:#fff;box-shadow:0 4px 0 #E8E2D6">{tool_crayon()}</span></div>'''
    pins = f'''<div style="position:relative;height:120px">{art_pin(50, 110, A + "art_cat.jpg", 60, "作品", count=3)}{art_pin(170, 110, A + "art_coffee.jpg", 74, "今天", ring=SUN, today=True)}{empty_pin(270, 110)}</div>'''
    body = f'''<div style="position:absolute;inset:0;background:#F7F3EA;padding:40px 48px;overflow:hidden">
<div class="center" style="justify-content:flex-start;gap:20px">{logo(96)}<div><div style="font-size:40px;font-weight:700">畫畫小鎮</div><div style="font-size:18px;color:{INK_SOFT};margin-top:4px">拍一張照片，變成你的著色畫，貼在你的城市地圖上</div></div>
<div style="margin-left:auto">{pigeon(110)}</div></div>
{h("顏色")}<div style="display:grid;grid-template-columns:repeat(4,168px);gap:18px 20px">{colors}</div>
{h("字型：jf open 粉圓（SIL OFL，可商用）")}<div style="display:flex;gap:36px;align-items:baseline"><span style="font-size:30px;font-weight:700">標題 30</span><span style="font-size:22px;font-weight:700">小標 22</span><span style="font-size:17px">內文 17</span><span style="font-size:14px;color:{INK_SOFT}">說明 14</span></div>
{h("按鈕：又大又胖，按下去會壓扁")}{buttons}
{h("圖示")}<div style="display:flex;flex-wrap:wrap;gap:10px">{icons_row}</div>
{h("角色：小朋友的動物、郵差鴿咕咕")}<div style="display:flex;gap:12px">{animals}</div>
{h("地圖圖釘與貼紙")}{pins}<div style="display:flex;gap:10px;margin-top:10px">{stickers_row}</div>
</div>'''
    return page("設計規範", body).replace(".screen{width:390px;height:844px", ".screen{width:860px;height:1420px")



def voice_bubble(text, left, top, width=None, size=17):
    w = f"width:{width}px;" if width else ""
    return (f'<div class="abs center" style="left:{left}px;top:{top}px;{w}min-height:50px;padding:10px 16px;gap:8px;border-radius:24px;background:#fff;'
            f'box-shadow:0 6px 16px rgba(30,60,40,.2);font-size:{size}px;font-weight:700;line-height:1.35">{icon("sound", 20, SKY, 2.4)}<span>{text}</span></div>')


@screen("13_day1")
def day1():
    body = (town_map(built={"home"}) + walker(152, 432)
            + f'<span class="abs" style="left:226px;top:124px;transform:rotate(-8deg)">{pigeon(70, flying=True)}</span>'
            + voice_bubble("小鎮還空空的，<br>去拍照把它蓋起來吧！", 150, 456, 228, 16)
            + hud(count=0) + dock())
    return page("第一天的小鎮", body)


@screen("14_address")
def address():
    def card(kind, sel=False, tag=None):
        ring = f"box-shadow:0 0 0 5px {SUN},0 10px 22px rgba(224,162,28,.35);" if sel else "box-shadow:0 6px 0 #E6DCCB;"
        t = (f'<span class="abs center" style="left:10px;top:10px;height:28px;padding:0 10px;border-radius:14px;background:{SUN};font-size:14px;font-weight:700">{tag}</span>' if tag else "")
        return (f'<button aria-label="寄到{PLACE_NAMES[kind]}" class="center" style="position:relative;flex-direction:column;gap:2px;height:168px;border-radius:30px;background:#fff;{ring}">'
                f'{place_icon(kind, 104)}<span style="font-size:18px;font-weight:700">{PLACE_NAMES[kind]}</span>{t}</button>')
    body = f'''{blurred_place()}<div class="abs" style="inset:0;background:rgba(40,60,50,.35)"></div>
<div class="abs" style="left:0;right:0;bottom:0;height:640px;border-radius:38px 38px 0 0;background:{PAPER}"></div>
<div class="abs" style="left:26px;top:96px;transform:rotate(-8deg)">
<div style="width:150px;height:150px;border-radius:16px;background:#fff;padding:7px;box-shadow:0 12px 24px rgba(30,60,40,.3)"><img src="{A}art_coffee.jpg" alt="" style="display:block;width:136px;height:136px;border-radius:10px;object-fit:cover"></div></div>
<div class="abs" style="left:126px;top:60px">{pigeon(130, letter=False)}</div>
{voice_bubble("要寄到哪裡呢？", 196, 236, None, 19)}
<div class="abs" style="left:22px;right:22px;top:316px;display:grid;grid-template-columns:1fr 1fr;gap:16px">
{card("park", True, "上次")}{card("home")}{card("school")}{card("grandma")}</div>
<button aria-label="更多地方" class="abs center" style="left:50%;margin-left:-110px;bottom:34px;width:220px;height:64px;border-radius:32px;gap:10px;background:#fff;box-shadow:0 5px 0 #E6DCCB;font-size:18px;font-weight:700">
<span class="center" style="gap:2px">{place_icon("zoo", 30)}{place_icon("food", 30)}{place_icon("water", 30)}</span><span>更多地方</span></button>'''
    return page("寄到哪裡", body, bg=PAPER)


@screen("15_build")
def build():
    puffs = "".join(f'<span class="abs" style="left:{x}px;top:{y}px;width:{r}px;height:{r}px;border-radius:50%;background:#FFFFFF;opacity:{o}"></span>'
                    for x, y, r, o in [(16, 600, 34, .85), (40, 618, 24, .8), (150, 610, 30, .85), (170, 590, 20, .7), (84, 626, 22, .75)])
    crane = '''<svg class="abs" style="left:150px;top:400px" width="80" height="140" viewBox="0 0 80 140" aria-hidden="true">
<path d="M20 136 V18 M30 136 V18 M20 18 H70 M20 30 L30 18 M20 50 L30 38 M20 70 L30 58 M20 90 L30 78 M20 110 L30 98" stroke="#FFC94A" stroke-width="4" stroke-linecap="round"/>
<path d="M20 18 H74" stroke="#E0A21C" stroke-width="6" stroke-linecap="round"/><path d="M64 18 V46" stroke="#5E6F86" stroke-width="2"/><path d="M58 46 h12 v8 h-12z" fill="#FF5E5B"/></svg>'''
    conf = "".join(f'<span class="abs" style="left:{x}px;top:{y}px;width:9px;height:6px;border-radius:2px;background:{c};transform:rotate({r}deg)"></span>'
                   for x, y, c, r in [(30, 460, CORAL, 20), (90, 440, SUN, 60), (150, 470, SKY, -30), (60, 520, GRAPE, 10), (120, 500, PINK, 45), (180, 450, GRASS, -50), (10, 500, TEAL, 30)])
    banner = (f'<div class="abs center" style="left:50%;transform:translateX(-50%);top:228px;height:64px;padding:0 22px 0 10px;gap:8px;border-radius:32px;background:{SUN};'
              f'box-shadow:0 6px 0 {SUN_DARK},0 14px 24px rgba(224,162,28,.4);font-size:21px;font-weight:700;white-space:nowrap">{place_icon("park", 52)}<span>新地方：公園！</span></div>')
    body = (town_map(built={"home", "park"}) + puffs + crane + conf
            + art_pin(74, 566, A + "art_coffee.jpg", 74, "第一張公園的明信片", ring=SUN, today=True)
            + sparkles([(40, 470, 28, 1), (150, 520, 22, .9), (12, 560, 18, .8), (176, 470, 16, .9)])
            + banner + walker(152, 432) + hud(count=1) + dock())
    return page("蓋好新地方", body)


@screen("16_gate")
def gate():
    keys = "".join(f'<button class="center" style="height:70px;border-radius:22px;background:#fff;box-shadow:0 4px 0 #E3DCCF;font-size:30px;font-weight:700">{k}</button>'
                   for k in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"])
    keys = keys.replace('<button class="center" style="height:70px;border-radius:22px;background:#fff;box-shadow:0 4px 0 #E3DCCF;font-size:30px;font-weight:700"></button>', "<span></span>")
    body = f'''<div class="abs" style="inset:0;background:#F7F5F0"></div>
<button aria-label="關閉" class="abs center" style="right:14px;top:16px;width:48px;height:48px;border-radius:50%;background:#EFEAE0">{icon("close", 22, INK_SOFT, 2.6)}</button>
<div class="abs" style="left:22px;top:28px">{animal("bear", 70)}</div>
{voice_bubble("請找爸爸或媽媽來喔", 98, 40, None, 17)}
<div class="abs" style="left:22px;right:22px;top:132px;border-radius:26px;background:#fff;padding:22px;box-shadow:0 2px 0 #ECE7DD">
<div class="center" style="justify-content:flex-start;gap:8px;font-size:15px;color:{INK_SOFT}">{icon("lock", 18, INK_SOFT)}家長確認</div>
<div style="margin-top:10px;font-size:24px;font-weight:700">「七」加「八」等於多少？</div>
<div class="center" style="justify-content:flex-start;gap:12px;margin-top:18px">
<span class="center" style="width:64px;height:72px;border-radius:18px;border:3px solid {SKY};font-size:34px;font-weight:700">1</span>
<span class="center" style="width:64px;height:72px;border-radius:18px;border:3px dashed #D6CFC2;font-size:34px;color:#C9C1B3"></span></div>
<div style="margin-top:14px;font-size:14px;color:{INK_SOFT}">題目每次都不一樣。答錯 3 次要等 1 分鐘。</div></div>
<div class="abs" style="left:22px;right:22px;top:420px;display:grid;grid-template-columns:repeat(3,1fr);gap:12px">{keys}</div>'''
    return page("家長確認", body, bg="#F7F5F0")


def promise(ic, title, sub, bg):
    return (f'<div class="center" style="justify-content:flex-start;gap:14px;padding:12px 0">'
            f'<span class="center" style="flex:none;width:52px;height:52px;border-radius:18px;background:{bg}">{ic}</span>'
            f'<span><span style="display:block;font-size:17px;font-weight:700">{title}</span><span style="display:block;font-size:14px;color:{INK_SOFT};margin-top:2px">{sub}</span></span></div>')


@screen("17_setup")
def setup():
    body = f'''<div class="abs" style="inset:0;background:#F7F5F0"></div>
<div class="abs center" style="left:0;right:0;top:26px;gap:10px">{logo(44)}<span style="font-size:22px;font-weight:700">開始之前</span></div>
<div class="abs" style="left:0;right:0;top:80px;text-align:center;font-size:15px;color:{INK_SOFT}">給爸爸媽媽：這個 APP 怎麼保護小朋友</div>
<div class="abs" style="left:18px;right:18px;top:118px;border-radius:24px;background:#fff;padding:6px 18px;box-shadow:0 2px 0 #ECE7DD">
{promise(icon("shield", 28, GRASS_DARK, 2.2), "照片和畫都只存在這支手機", "不用註冊帳號，不會上傳到任何地方", "#E3F6E6")}
{promise(icon("close", 26, CORAL_DARK, 2.8), "沒有廣告、聊天或陌生人", "也沒有追蹤或分析工具", "#FFE6E5")}
{promise(icon("pin", 28, SKY_DARK, 2.2), "不使用定位", "小朋友自己選「在哪裡畫的」", "#E3F0FF")}
{promise(icon("lock", 28, GRAPE, 2.2), "分享和設定都要家長確認", "小朋友不會自己把畫傳出去", "#EFE9FF")}</div>
<div class="abs" style="left:18px;right:18px;top:470px;border-radius:24px;background:#fff;padding:16px 18px;box-shadow:0 2px 0 #ECE7DD">
<div class="center" style="justify-content:space-between"><span class="center" style="gap:10px;font-size:17px;font-weight:700">{icon("camera", 24, INK)}相機</span>
<span class="center" style="height:40px;padding:0 16px;border-radius:20px;background:{SKY};color:#fff;font-size:15px;font-weight:700">允許</span></div>
<div style="font-size:14px;color:{INK_SOFT};margin-top:6px">只有按下拍照鈕時才會打開。</div>
<div style="height:1px;background:#F0EBE2;margin:14px 0"></div>
<div style="font-size:17px;font-weight:700;margin-bottom:10px" class="center"><span class="center" style="gap:10px;margin-right:auto">{icon("clock", 24, INK)}每天可以玩多久</span></div>
<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:6px;padding:4px;border-radius:14px;background:#F3F0EA">
{"".join(f'<span class="center" style="height:38px;border-radius:11px;font-size:15px;{"background:#fff;font-weight:700;box-shadow:0 1px 3px rgba(0,0,0,.12)" if o == "30 分" else "color:" + INK_SOFT}">{o}</span>' for o in ["15 分", "30 分", "45 分", "60 分"])}</div></div>
<div class="abs center" style="left:18px;right:18px;top:720px;gap:6px;font-size:14px;color:{SKY_DARK}">{icon("info", 16, SKY_DARK)}<span>看完整的隱私權政策</span></div>
<button class="abs center" style="left:18px;right:18px;bottom:30px;height:68px;border-radius:24px;gap:8px;background:{GRASS};color:#fff;font-size:19px;font-weight:700;box-shadow:0 6px 0 {GRASS_DARK}">我知道了，交給小朋友{icon("chevron", 24, "#fff", 3)}</button>'''
    return page("給家長", body, bg="#F7F5F0")


@screen("18_timeup")
def timeup():
    stars = "".join(f'<span class="abs" style="left:{x}px;top:{y}px">{solid("sparkle", s, "#FFE9A8")}</span>'
                    for x, y, s in [(40, 110, 14), (300, 80, 18), (200, 150, 10), (80, 220, 10), (340, 230, 12), (150, 60, 12)])
    bed = f'''<svg class="abs" style="left:45px;top:330px" width="300" height="230" viewBox="0 0 300 230" aria-hidden="true">
<ellipse cx="150" cy="218" rx="140" ry="10" fill="rgba(0,0,0,.25)"/>
<rect x="16" y="70" width="20" height="148" rx="8" fill="#C98B5E"/><rect x="264" y="110" width="20" height="108" rx="8" fill="#C98B5E"/>
<rect x="24" y="150" width="252" height="46" rx="12" fill="#E8B07A"/>
<rect x="40" y="112" width="90" height="46" rx="20" fill="#FFFFFF"/>
<path d="M90 136 C 120 108, 250 108, 268 140 L268 170 L90 170 Z" fill="#7C6CFF"/>
<path d="M110 150 h140 M120 160 h120" stroke="#A493FF" stroke-width="5" stroke-linecap="round"/>
<circle cx="170" cy="134" r="6" fill="#FFD23F"/><circle cx="214" cy="128" r="5" fill="#FF8FB1"/></svg>'''
    sleepy = re.sub(r'<circle cx="(2[34]\.5|4[01]\.5|24\.5|41\.5)" cy="3[23](\.9)?" r="(3\.1|1)" fill="#(2A211D|FFFFFF)"/>', "", animal("bear", 74))
    sleepy = sleepy.replace("</svg>", '<path d="M20 33 q3.5 3 7 0 M37 33 q3.5 3 7 0" stroke="#2A211D" stroke-width="2.2" fill="none" stroke-linecap="round"/></svg>')
    body = f'''<div class="abs" style="inset:0;background:linear-gradient(180deg,#26215E 0%,#4B3FA3 62%,#6C5BD0 100%)"></div>{stars}
<svg class="abs" style="left:290px;top:170px" width="70" height="70" viewBox="0 0 70 70" aria-hidden="true"><path d="M46 8 A28 28 0 1 0 62 52 A22 22 0 1 1 46 8 Z" fill="#FFE27A"/></svg>
<div class="abs" style="left:0;right:0;top:70px;text-align:center;color:#fff;font-size:26px;font-weight:700">晚安，小熊</div>
<div class="abs center" style="left:0;right:0;top:112px;gap:6px;color:#D8D2FF;font-size:16px">{icon("sound", 18, "#D8D2FF")}<span>今天畫了好多，明天再來玩！</span></div>
{bed}
<div class="abs" style="left:76px;top:404px;transform:rotate(-14deg)">{sleepy}</div>
<div class="abs" style="left:150px;top:380px;color:#fff;font-size:24px;font-weight:700;transform:rotate(-10deg)">z<span style="font-size:18px">z</span><span style="font-size:14px">z</span></div>
<div class="abs center" style="left:0;right:0;top:590px;gap:12px">
{"".join(f'<span style="display:block;width:86px;height:86px;border-radius:14px;background:#fff;padding:5px;transform:rotate({t}deg);box-shadow:0 8px 16px rgba(0,0,0,.3)"><img src="{A}{img}" alt="" style="display:block;width:76px;height:76px;border-radius:9px;object-fit:cover"></span>' for img, t in [("art_coffee.jpg", -6), ("art_coffee2.jpg", 3), ("art_cat2.jpg", -2)])}</div>
<div class="abs" style="left:0;right:0;top:700px;text-align:center;color:#D8D2FF;font-size:15px">今天寄出 3 張明信片</div>
<button class="abs center" style="left:50%;margin-left:-110px;bottom:34px;width:220px;height:52px;border-radius:26px;gap:8px;background:rgba(255,255,255,.14);color:#fff;font-size:15px">{icon("lock", 18, "#fff")}家長：再玩 10 分鐘</button>'''
    return page("時間到了", body, bg="#26215E")



@screen("19_privacy")
def privacy():
    no = lambda ic, t: (f'<div class="center" style="flex-direction:column;gap:6px"><span class="center" style="position:relative;width:58px;height:58px;border-radius:20px;background:#FFF0EF">{ic}'
                        f'<span class="abs" style="left:8px;top:27px;width:42px;height:4px;border-radius:2px;background:{CORAL_DARK};transform:rotate(-40deg)"></span></span>'
                        f'<span style="font-size:13px;color:{INK_SOFT}">{t}</span></div>')
    perm = lambda ic, t, state, ok: (f'<div class="center" style="justify-content:space-between;height:50px;border-bottom:1px solid #F0EBE2">'
                                     f'<span class="center" style="gap:10px;font-size:16px">{ic}{t}</span>'
                                     f'<span style="font-size:14px;font-weight:700;color:{GRASS_DARK if ok else INK_SOFT}">{state}</span></div>')
    act = lambda ic, t, color=INK: (f'<div class="center" style="justify-content:space-between;height:50px"><span class="center" style="gap:10px;font-size:16px;color:{color}">{ic}{t}</span>{icon("chevron", 20, "#B9B2A4", 2.4)}</div>')
    body = f"""<div class="abs" style="inset:0;background:#F7F5F0"></div>
<button aria-label="返回" class="abs center" style="left:10px;top:16px;width:48px;height:48px">{icon("back", 28, INK, 2.4)}</button>
<div class="abs" style="left:0;right:0;top:26px;text-align:center;font-size:20px;font-weight:700">隱私與安全</div>
<div class="abs" style="left:16px;right:16px;top:80px;border-radius:24px;background:#fff;padding:16px;box-shadow:0 2px 0 #ECE7DD">
<div class="center" style="justify-content:flex-start;gap:14px"><span class="center" style="flex:none;width:64px;height:64px;border-radius:22px;background:#E3F6E6">{icon("shield", 36, GRASS_DARK, 2.2)}</span>
<span><span style="display:block;font-size:18px;font-weight:700">所有資料都在這支手機</span><span style="display:block;font-size:14px;color:{INK_SOFT};margin-top:3px">照片、畫、名字都不會離開手機。<br>刪掉 APP 就全部刪除。</span></span></div>
<div style="display:grid;grid-template-columns:repeat(4,1fr);margin-top:14px">{no(icon("share", 26, INK_SOFT), "不上傳")}{no(icon("star", 26, INK_SOFT), "沒廣告")}{no(icon("users", 26, INK_SOFT), "沒聊天")}{no(icon("pin", 26, INK_SOFT), "不定位")}</div></div>
<div class="abs" style="left:16px;right:16px;top:318px;border-radius:24px;background:#fff;padding:6px 16px 4px;box-shadow:0 2px 0 #ECE7DD">
<div style="font-size:14px;color:{INK_SOFT};margin:8px 0 2px">APP 用到的權限</div>
{perm(icon("camera", 22, INK), "相機", "按拍照時才用", True)}{perm(icon("album", 22, INK), "相片", "只讀你選的那張", True)}
{perm(icon("pin", 22, INK_SOFT), "位置", "不使用", False)}{perm(icon("sound", 22, INK_SOFT), "麥克風", "不使用", False)}
<div class="center" style="justify-content:space-between;height:50px"><span class="center" style="gap:10px;font-size:16px">{icon("share", 22, INK_SOFT)}網路</span><span style="font-size:14px;font-weight:700;color:{INK_SOFT}">不使用</span></div></div>
<div class="abs" style="left:16px;right:16px;top:640px;border-radius:24px;background:#fff;padding:4px 16px;box-shadow:0 2px 0 #ECE7DD">
{act(icon("download", 22, INK), "把全部明信片存到相簿")}{act(icon("trash", 22, "#D9423F"), "刪除一位小朋友的資料", "#D9423F")}{act(icon("trash", 22, "#D9423F"), "刪除所有資料", "#D9423F")}</div>"""
    return page("隱私與安全", body, bg="#F7F5F0")


if __name__ == "__main__":
    import sys
    OUT.mkdir(exist_ok=True)
    only = set(sys.argv[1:])
    for name, fn in SCREENS.items():
        if only and name not in only:
            continue
        (OUT / f"{name}.html").write_text(fn())
        print(name)
