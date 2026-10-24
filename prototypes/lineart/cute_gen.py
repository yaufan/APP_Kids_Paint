"""Cute style v2 experiment: redraw the photo as a chibi cartoon with an open-source model.

The photo's own lines (from lineart.py) guide Stable Diffusion 1.5 through a
lineart ControlNet, so the cartoon keeps the subject's layout and stays
recognizable while the prompt pushes it toward a cute, simple look. An
LCM LoRA cuts sampling to a few steps so it is bearable on a CPU. The
result is cleaned into even lines and a leak-free fill map, exactly like
the other styles.

Models (downloaded from Hugging Face on first run):
  stable-diffusion-v1-5/stable-diffusion-v1-5   CreativeML OpenRAIL-M
  lllyasviel/control_v11p_sd15_lineart          OpenRAIL
  latent-consistency/lcm-lora-sdv1-5            OpenRAIL++
All allow commercial use under their use-based restrictions.
"""
import argparse
import json
import time
from pathlib import Path

import cv2
import numpy as np
from skimage.morphology import skeletonize

from lineart import (CUTE, DETAILS, OUT_SIZE, drop_short, edge_map, fill_regions,
                     frame_photo, line_ink, preview_colored, resize_long, round_ink, stroke)

BASE = "stable-diffusion-v1-5/stable-diffusion-v1-5"
CONTROLNET = "lllyasviel/control_v11p_sd15_lineart"
LCM_LORA = "latent-consistency/lcm-lora-sdv1-5"
GEN_SIZE = 512  # long side of the generated image

PROMPT = ("cute kawaii chibi cartoon {label}, children's coloring book page, "
          "bold clean black outlines, white background, simple rounded shapes, no shading")
NEGATIVE = "color, shading, gradient, grey, text, watermark, photo, realistic, messy, sketchy, hatching"

_pipe = None


def pipeline():
    global _pipe
    if _pipe is None:
        import torch
        from diffusers import ControlNetModel, LCMScheduler, StableDiffusionControlNetPipeline
        controlnet = ControlNetModel.from_pretrained(CONTROLNET, torch_dtype=torch.float32)
        pipe = StableDiffusionControlNetPipeline.from_pretrained(
            BASE, controlnet=controlnet, torch_dtype=torch.float32)
        pipe.scheduler = LCMScheduler.from_config(pipe.scheduler.config)
        pipe.load_lora_weights(LCM_LORA)
        pipe.fuse_lora()
        pipe.set_progress_bar_config(disable=True)
        _pipe = pipe
    return _pipe


def control_image(big, mask):
    """White-on-black guide lines at generation size (what the lineart ControlNet expects)."""
    ink = line_ink(edge_map(big), mask, DETAILS["normal"])
    guide = resize_long((ink * 255).astype(np.uint8), GEN_SIZE)
    h, w = guide.shape
    return cv2.resize(guide, (w // 8 * 8, h // 8 * 8), interpolation=cv2.INTER_AREA)


def generate(guide, label, strength, seed, steps=6):
    import torch
    from PIL import Image
    out = pipeline()(
        PROMPT.format(label=label), negative_prompt=NEGATIVE,
        image=Image.fromarray(guide).convert("RGB"),
        num_inference_steps=steps, guidance_scale=1.5,
        controlnet_conditioning_scale=strength,
        generator=torch.Generator().manual_seed(seed),
        height=guide.shape[0], width=guide.shape[1])
    return cv2.cvtColor(np.array(out.images[0]), cv2.COLOR_RGB2BGR)


def clean_generated(img):
    """Generated cartoon -> even, rounded coloring lines plus the fill-region map."""
    gray = cv2.cvtColor(resize_long(img, OUT_SIZE, cv2.INTER_CUBIC), cv2.COLOR_BGR2GRAY)
    dark = (cv2.GaussianBlur(gray, (0, 0), 1.5) < 130).astype(np.uint8)
    dark = cv2.morphologyEx(dark, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    center = drop_short(skeletonize(dark > 0), 0.02 * np.hypot(*gray.shape))
    smooth = cv2.GaussianBlur(center.astype(np.float32), (0, 0), 1.2) > 0.12
    line_px = CUTE.line * OUT_SIZE
    ink = round_ink(stroke(smooth, line_px), CUTE.rounding * OUT_SIZE, line_px)
    page = np.round(255 * (1 - ink)).astype(np.uint8)
    return page, fill_regions(ink, round(CUTE.gap * OUT_SIZE), CUTE.min_region * page.size)


def convert_v2(img, label, rect=None, strength=0.7, seed=1):
    """Return (raw cartoon, page, region_map, stats)."""
    t0 = time.perf_counter()
    big, mask = frame_photo(img, rect, margin=0.15, mask_smooth=0.02)
    raw = generate(control_image(big, mask), label, strength, seed)
    page, regions = clean_generated(raw)
    stats = {"style": "cute_v2", "label": label, "strength": strength, "seed": seed,
             "regions": int(regions.max()), "ms": round(1000 * (time.perf_counter() - t0))}
    return raw, page, regions, stats


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("image")
    ap.add_argument("--label", required=True, help='what the photo shows, e.g. "coffee cup"')
    ap.add_argument("--rect", type=float, nargs=4, metavar=("X0", "Y0", "X1", "Y1"),
                    help="rough subject box as fractions of the photo; omit to keep the whole scene")
    ap.add_argument("--strength", type=float, default=0.7,
                    help="how closely to follow the photo's lines (0..1); lower = more cartoonish")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out", default="out")
    a = ap.parse_args()

    raw, page, regions, stats = convert_v2(cv2.imread(a.image), a.label, a.rect, a.strength, a.seed)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    stem = f"{Path(a.image).stem}_cute_v2"
    cv2.imwrite(str(out / f"{stem}_raw.png"), raw)
    cv2.imwrite(str(out / f"{stem}_page.png"), page)
    cv2.imwrite(str(out / f"{stem}_colored.png"), preview_colored(page, regions))
    print(json.dumps(stats, ensure_ascii=False))


if __name__ == "__main__":
    main()
