"""Writes the painted scenes into the app: app/assets/scenes/<habitat>.jpg.

(0.10's creature pages were also painted and traced here; since 0.11
they are drawn in docs/design/v5.)

    python3 export.py <draw_scenes out> [habitats...]
"""
import sys
from pathlib import Path

import cv2
import numpy as np

APP = Path(__file__).resolve().parents[3] / "app"

# habitat: the seed that came out best
SCENES = {
    "zoo": 2,
    "aquarium": 1,
    "dinoPark": 1,
    "transport": 1,
    "botanical": 2,
    "insects": 2,
    "shop": 3,
    "space": 2,
    "nightMarket": 3,
    "polar": 1,
}

# Parts of a scene's layout put back over its painting (scene units, 1000
# across): the model turns the pictures on a sign into made-up letters.
KEEP = {
    "transport": [(394, 374, 606, 442)],
}


def main():
    src = Path(sys.argv[1])
    out = APP / "assets" / "scenes"
    out.mkdir(parents=True, exist_ok=True)
    for habitat, seed in SCENES.items():
        if sys.argv[2:] and habitat not in sys.argv[2:]:
            continue
        img = cv2.resize(cv2.imread(str(src / f"{habitat}_{seed}.png")), (1024, 1024), interpolation=cv2.INTER_LANCZOS4)
        if habitat in KEEP:
            layout = cv2.resize(cv2.imread(str(src / f"{habitat}_layout.png")), (1024, 1024), interpolation=cv2.INTER_LANCZOS4)
            keep = np.zeros(img.shape[:2], np.float32)
            for x0, y0, x1, y1 in KEEP[habitat]:
                keep[round(y0 * 1.024):round(y1 * 1.024), round(x0 * 1.024):round(x1 * 1.024)] = 1
            keep = cv2.GaussianBlur(keep, (0, 0), 2)[..., None]
            img = (img * (1 - keep) + layout * keep).astype(np.uint8)
        cv2.imwrite(str(out / f"{habitat}.jpg"), img, [cv2.IMWRITE_JPEG_QUALITY, 86])
        print(habitat, flush=True)


if __name__ == "__main__":
    main()
