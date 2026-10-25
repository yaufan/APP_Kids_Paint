"""Pairs of screens side by side, sized for viewing on a phone."""
import sys
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
root = Path(__file__).resolve().parent.parent
font = ImageFont.truetype(str(root.parent.parent.parent / 'app/assets/fonts/jf-openhuninn-2.1.ttf'), 46)
small = ImageFont.truetype(str(root.parent.parent.parent / 'app/assets/fonts/jf-openhuninn-2.1.ttf'), 30)
PAIRS = [
    ('1', '首頁與地點', ['01_home', '02_place'], ['小鎮地圖', '點一個圖釘']),
    ('2', '拍照與變身', ['03_camera', '04_magic'], ['拍照', '魔法變身']),
    ('3', '選風格與著色', ['05_style', '06_coloring'], ['選一張', '塗顏色']),
    ('4', '貼紙與寄出', ['07_stickers', '08_sent'], ['貼貼紙', '寄到地圖']),
    ('5', '明信片冊與分享', ['09_album', '10_share'], ['明信片冊', '分享（家長）']),
    ('6', '第一次使用與家長模式', ['11_welcome', '12_parent'], ['選角色', '家長模式']),
    ('8', '第一天與蓋新地方', ['13_day1', '15_build'], ['第一天：小鎮空空的', '寄到新地方就蓋好']),
    ('9', '寄到哪裡與家長確認', ['14_address', '16_gate'], ['寄到哪裡？', '家長確認']),
    ('10', '給家長與時間到', ['17_setup', '18_timeup'], ['第一次打開：給家長', '時間到了']),
    ('11', '隱私與安全', ['19_privacy', '10_share'], ['隱私與安全', '分享（安全的預設）']),
]
out = root / 'sheets'; out.mkdir(exist_ok=True)
only = set(sys.argv[1:])
for key, title, names, caps in PAIRS:
    if only and key not in only: continue
    ims = [Image.open(root / 'screens' / f'{n}.png').convert('RGB') for n in names]
    w, h = ims[0].size
    W, H = w * 2 + 90, h + 200
    s = Image.new('RGB', (W, H), (246, 243, 236)); d = ImageDraw.Draw(s)
    d.text((30, 34), f'{key}. {title}', fill=(52, 65, 58), font=font)
    for i, (im, cap) in enumerate(zip(ims, caps)):
        x = 30 + i * (w + 30)
        s.paste(im, (x, 120))
        d.text((x + 6, 120 + h + 18), cap, fill=(107, 122, 112), font=small)
    s = s.resize((W * 7 // 10, H * 7 // 10), Image.LANCZOS)
    s.save(out / f'{key}_{title}.jpg', quality=87)
    print(out / f'{key}_{title}.jpg')
