"""Run every style on the test photos and build a comparison sheet.

Without arguments it uses public-domain sample photos bundled with
scikit-image. Pass a folder to test your own photos instead; an optional
samples.json in that folder gives each photo's subject box and face flag:
  {"dog.jpg": {"rect": [0.1, 0.1, 0.9, 0.95], "face": false}}
"""
import argparse
import json
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

from lineart import convert, preview_colored, resize_long

BUILTIN = {  # scikit-image sample name -> subject hint
    "coffee": {"rect": [0.12, 0.02, 0.81, 0.98], "face": True},
    "chelsea": {"rect": None, "face": False},
    "rocket": {"rect": [0.46, 0.28, 0.54, 0.97], "face": True},
}
VARIANTS = [
    ("真實・簡單", "realistic", "simple"),
    ("真實・普通", "realistic", "normal"),
    ("可愛", "cute", "simple"),
]
FONTS = ["/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
         "/System/Library/Fonts/PingFang.ttc", "C:/Windows/Fonts/msjh.ttc"]
TILE = 360


def load_inputs(folder):
    if folder is None:
        import skimage.data
        for name, hint in BUILTIN.items():
            rgb = getattr(skimage.data, name)()
            yield name, cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), hint
        return
    folder = Path(folder)
    hints = json.loads((folder / "samples.json").read_text()) if (folder / "samples.json").exists() else {}
    for path in sorted(folder.iterdir()):
        if path.suffix.lower() in {".jpg", ".jpeg", ".png", ".heic", ".webp"}:
            img = cv2.imread(str(path))
            if img is not None:
                yield path.stem, img, {"rect": None, "face": True, **hints.get(path.name, {})}


def font(size):
    for f in FONTS:
        if Path(f).exists():
            return ImageFont.truetype(f, size)
    return ImageFont.load_default()


def tile(img_bgr, caption):
    if img_bgr.ndim == 2:
        img_bgr = cv2.cvtColor(img_bgr, cv2.COLOR_GRAY2BGR)
    fitted = resize_long(img_bgr, TILE)
    canvas = np.full((TILE + 40, TILE, 3), 245, np.uint8)
    y, x = (TILE - fitted.shape[0]) // 2, (TILE - fitted.shape[1]) // 2
    canvas[y:y + fitted.shape[0], x:x + fitted.shape[1]] = fitted
    pil = Image.fromarray(cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB))
    ImageDraw.Draw(pil).text((10, TILE + 8), caption, fill=(40, 40, 40), font=font(20))
    return cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("folder", nargs="?", help="folder of test photos (default: built-in samples)")
    ap.add_argument("--out", default=str(Path(__file__).parent / "results"))
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)

    rows, summary = [], []
    for name, img, hint in load_inputs(a.folder):
        cells = [tile(img, f"{name}（原圖）")]
        for label, style, detail in VARIANTS:
            page, regions, stats = convert(img, style, detail, hint["rect"], hint["face"])
            stats["photo"] = name
            summary.append(stats)
            cv2.imwrite(str(out / f"{name}_{stats['detail']}_page.png"), page)
            caption = f"{label}　{stats['regions']} 區"
            cells.append(tile(page, caption))
            if style == "cute":
                cells.append(tile(preview_colored(page, regions), "可愛・模擬塗色"))
            print(json.dumps(stats, ensure_ascii=False))
        rows.append(np.hstack(cells))

    sheet = np.vstack([np.pad(r, ((0, 8), (0, 0), (0, 0)), constant_values=255) for r in rows])
    cv2.imwrite(str(out / "comparison.jpg"), sheet, [cv2.IMWRITE_JPEG_QUALITY, 88])
    (out / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"comparison sheet: {out / 'comparison.jpg'}")


if __name__ == "__main__":
    main()
