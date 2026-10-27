"""Writes the painted art into the app.

- app/assets/pages/<creature>.png: the coloring pages, traced (to_page.py)
  from the pictures chosen in subjects/<creature>.jpg, cut out along
  subjects/<creature>_mask.png (segment.py).
- app/assets/scenes/<habitat>.jpg: the scenes chosen.
- colors/<creature>.jpg: each subject in color where its page puts it.

    python3 export.py --subjects <draw_subjects out> --scenes <draw_scenes out>
        # first copies the chosen seeds (and their cutouts) into subjects/
        # and the chosen scenes into the app
    python3 export.py [names...]
        # traces the pages again from subjects/ (all, or just these)
"""
import argparse
from pathlib import Path

import cv2
import numpy as np

import segment
import to_page

HERE = Path(__file__).resolve().parent
APP = HERE.parents[2] / "app"
SUBJECTS = HERE / "subjects"
REFERENCES = HERE / "colors"

# creature: (seed, flip so it faces right, strength, min_area, detail, min_width);
# see to_page.page. Fur and scales want no extra lines (detail 0), smooth
# skins and machines a few.
PAGES = {
    # the zoo
    "elephant": (2, False, 0.45, 1200, 0.2, 5),
    "giraffe": (3, False, 0.22, 400, 0.2, 3),
    "lion": (1, False, 0.45, 1200, 0.3, 5),
    "panda": (3, False, 0.3, 900, 0.5, 5),
    "zebra": (2, False, 0.3, 350, 0.0, 2.5),
    "monkey": (3, False, 0.35, 900, 0.4, 5),
    # the aquarium
    "clownfish": (3, False, 0.3, 700, 0.5, 4),
    "octopus": (3, False, 0.35, 900, 0.4, 5),
    "turtle": (4, True, 0.35, 900, 0.3, 4),
    "whale": (3, False, 0.35, 1200, 0.3, 5),
    "jellyfish": (6, False, 0.3, 600, 0.3, 3),
    "crab": (2, False, 0.35, 900, 0.4, 5),
    # the dinosaur park
    "trex": (3, False, 0.4, 1200, 0.3, 5),
    "triceratops": (1, True, 0.4, 1000, 0.3, 4),
    "brachiosaurus": (3, False, 0.4, 1000, 0.3, 4),
    "stegosaurus": (2, True, 0.35, 900, 0.3, 4),
    "pterosaur": (3, False, 0.35, 800, 0.3, 4),
    "babyDino": (7, False, 0.35, 900, 0.4, 4),
    # the transport museum
    "fireTruck": (3, True, 0.35, 900, 0.5, 5),
    "policeCar": (4, True, 0.35, 900, 0.5, 4),
    "ambulance": (4, True, 0.35, 900, 0.5, 4),
    "bus": (2, False, 0.35, 900, 0.5, 5),
    "scooter": (1, False, 0.35, 700, 0.5, 5),
    "airplane": (1, False, 0.35, 700, 0.5, 5),
    "train": (3, True, 0.35, 900, 0.5, 5),
    "helicopter": (1, False, 0.35, 700, 0.5, 3),
    # the botanical garden
    "sunflower": (2, False, 0.35, 700, 0.4, 4),
    "tulip": (1, False, 0.35, 700, 0.4, 5),
    "cactus": (2, False, 0.4, 900, 0.3, 5),
    "lotus": (4, False, 0.35, 700, 0.4, 5),
    "strawberry": (2, False, 0.35, 600, 0.4, 4),
    "rose": (1, False, 0.35, 700, 0.4, 4),
    # the insect museum
    "butterfly": (1, False, 0.3, 500, 0.3, 4),
    "beetle": (4, True, 0.35, 700, 0.4, 4),
    "ladybug": (1, False, 0.3, 300, 0.3, 3),
    "bee": (2, False, 0.35, 600, 0.4, 3),
    "dragonfly": (2, False, 0.35, 600, 0.3, 3),
    "mantis": (1, False, 0.35, 600, 0.4, 3),
}

# habitat: seed
SCENES = {
    "zoo": 2,
    "aquarium": 1,
    "dinoPark": 1,
    "transport": 1,
    "botanical": 2,
    "insects": 2,
}

# Parts of a scene's layout put back over its painting (scene units, 1000
# across): the model turns the pictures on a sign into made-up letters.
KEEP = {
    "transport": [(394, 374, 606, 442)],
}


def trace(cid):
    seed, flip, strength, min_area, detail, min_width = PAGES[cid]
    img = cv2.imread(str(SUBJECTS / f"{cid}.jpg"))
    mask = cv2.imread(str(SUBJECTS / f"{cid}_mask.png"), cv2.IMREAD_GRAYSCALE)
    page = to_page.page(img, flip, strength, min_area, detail, min_width, mask=mask)
    cv2.imwrite(str(APP / "assets" / "pages" / f"{cid}.png"), page, [cv2.IMWRITE_PNG_COMPRESSION, 9])
    # Its real colors, aligned with the page (the demo video colors with them).
    REFERENCES.mkdir(exist_ok=True)
    cv2.imwrite(str(REFERENCES / f"{cid}.jpg"), to_page.reference(img, flip, mask), [cv2.IMWRITE_JPEG_QUALITY, 85])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*")
    ap.add_argument("--subjects", type=Path, help="draw_subjects.py's output: copy the chosen seeds here")
    ap.add_argument("--scenes", type=Path, help="draw_scenes.py's output: write the chosen ones into the app")
    a = ap.parse_args()
    if a.subjects:
        SUBJECTS.mkdir(exist_ok=True)
        for cid, (seed, *_) in PAGES.items():
            if a.names and cid not in a.names:
                continue
            img = cv2.imread(str(a.subjects / f"{cid}_{seed}.png"))
            cv2.imwrite(str(SUBJECTS / f"{cid}.jpg"), img, [cv2.IMWRITE_JPEG_QUALITY, 95])
            # Cut out from the original (SAM is sensitive to JPEG's noise).
            cv2.imwrite(str(SUBJECTS / f"{cid}_mask.png"), segment.mask(img), [cv2.IMWRITE_PNG_BILEVEL, 1])
    if a.scenes:
        out = APP / "assets" / "scenes"
        out.mkdir(parents=True, exist_ok=True)
        for habitat, seed in SCENES.items():
            img = cv2.resize(cv2.imread(str(a.scenes / f"{habitat}_{seed}.png")), (1024, 1024), interpolation=cv2.INTER_LANCZOS4)
            if habitat in KEEP:
                layout = cv2.resize(cv2.imread(str(a.scenes / f"{habitat}_layout.png")), (1024, 1024), interpolation=cv2.INTER_LANCZOS4)
                keep = np.zeros(img.shape[:2], np.float32)
                for x0, y0, x1, y1 in KEEP[habitat]:
                    keep[round(y0 * 1.024):round(y1 * 1.024), round(x0 * 1.024):round(x1 * 1.024)] = 1
                keep = cv2.GaussianBlur(keep, (0, 0), 2)[..., None]
                img = (img * (1 - keep) + layout * keep).astype(np.uint8)
            cv2.imwrite(str(out / f"{habitat}.jpg"), img, [cv2.IMWRITE_JPEG_QUALITY, 86])
    for cid in a.names or PAGES:
        if cid in PAGES:
            trace(cid)
            print(cid, flush=True)


if __name__ == "__main__":
    main()
