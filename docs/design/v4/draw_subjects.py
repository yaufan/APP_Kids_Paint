"""Draw every subject in subjects.py with a few seeds, to pick the best.

    python3 draw_subjects.py out_dir [ids...] [--seeds 1 2 3]
"""
import argparse
import time
from pathlib import Path

import sd_draw
import subjects

ap = argparse.ArgumentParser()
ap.add_argument("out")
ap.add_argument("ids", nargs="*")
ap.add_argument("--seeds", type=int, nargs="+", default=[1, 2, 3])
a = ap.parse_args()
out = Path(a.out)
out.mkdir(parents=True, exist_ok=True)
for cid in a.ids or list(subjects.SUBJECTS):
    for seed in a.seeds:
        path = out / f"{cid}_{seed}.png"
        if path.exists():
            continue
        t = time.time()
        sd_draw.draw(subjects.prompt(cid), seed, negative=subjects.NEGATIVE).save(path)
        print(f"{path.name} {time.time() - t:.0f}s", flush=True)
