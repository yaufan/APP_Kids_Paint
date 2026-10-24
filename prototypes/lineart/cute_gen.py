"""Cute style v2 experiment: redraw the photo as a chibi cartoon with an open-source model.

The photo's own lines (from lineart.py) guide Stable Diffusion 1.5 through a
lineart ControlNet, so the cartoon keeps the subject's layout and stays
recognizable while the prompt pushes it toward a cute, simple look. An
LCM LoRA cuts sampling to a few steps so it is bearable on a CPU.

The model paints a flat-color cartoon rather than bare lines; that suits
us, because the same edge network then traces it into clean lines far
more easily than a photo, and the usual clean-up gives even strokes and a
leak-free fill map.

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

from lineart import (CUTE, DETAILS, OUT_SIZE, convert, cute_extras, edge_map, fill_holes,
                     fill_regions, frame_photo, largest_component, line_ink, preview_colored,
                     resize_long, round_ink, smooth_mask)

BASE = "stable-diffusion-v1-5/stable-diffusion-v1-5"
CONTROLNET = "lllyasviel/control_v11p_sd15_lineart"
LCM_LORA = "latent-consistency/lcm-lora-sdv1-5"
GEN_SIZE = 512  # long side of the generated image

PROMPT = ("cute kawaii chibi {label}, flat color cartoon sticker illustration, "
          "thick outlines, simple rounded shapes, plain white background")
NEGATIVE = "photo, realistic, text, watermark, messy, noisy, detailed texture"

SAMPLES = {  # scikit-image sample -> rough subject box (None = whole scene), what it shows
    "coffee": ([0.12, 0.02, 0.81, 0.98], "coffee cup on a saucer with a spoon"),
    "chelsea": (None, "cat face"),
    "rocket": ([0.46, 0.28, 0.54, 0.97], "rocket on a launch pad between two towers"),
}

_pipe = None


def pipeline():
    global _pipe
    if _pipe is None:
        import torch
        from diffusers import ControlNetModel, LCMScheduler, StableDiffusionControlNetPipeline
        # fp16 files halve the download; the CPU still runs them in float32.
        controlnet = ControlNetModel.from_pretrained(CONTROLNET, variant="fp16", torch_dtype=torch.float32)
        pipe = StableDiffusionControlNetPipeline.from_pretrained(
            BASE, controlnet=controlnet, variant="fp16", torch_dtype=torch.float32)
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


def cartoon_mask(img):
    """The cartoon's subject: everything that differs from its plain background."""
    h, w = img.shape[:2]
    edge_px = np.concatenate([img[0], img[-1], img[:, 0], img[:, -1]])
    bg = np.median(edge_px, 0).astype(np.uint8).reshape(1, 1, 3)
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB).astype(np.float32)
    dist = np.linalg.norm(lab - cv2.cvtColor(bg, cv2.COLOR_BGR2LAB).astype(np.float32), axis=2)
    mask = np.where(dist > 18, 255, 0).astype(np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)))
    mask = smooth_mask(fill_holes(largest_component(mask)), 0.01 * max(h, w))
    return mask if 0.05 < (mask > 0).mean() < 0.9 else None


def cartoon_page(raw, cut_out):
    """Generated cartoon -> even, rounded coloring lines plus the fill-region map."""
    big = resize_long(raw, OUT_SIZE, cv2.INTER_CUBIC)
    mask = cartoon_mask(big) if cut_out else None
    ink = line_ink(edge_map(big), mask, CUTE)
    ink = cute_extras(round_ink(ink, CUTE.rounding * OUT_SIZE, CUTE.line * OUT_SIZE), mask, face=False)
    page = np.round(255 * (1 - ink)).astype(np.uint8)
    return page, fill_regions(ink, round(CUTE.gap * OUT_SIZE), CUTE.min_region * page.size)


def convert_v2(img, label, rect=None, strength=0.7, seed=1):
    """Return (raw cartoon, page, region_map, stats)."""
    t0 = time.perf_counter()
    big, mask = frame_photo(img, rect, margin=0.15, mask_smooth=0.02)
    t1 = time.perf_counter()
    raw = generate(control_image(big, mask), label, strength, seed)
    t2 = time.perf_counter()
    page, regions = cartoon_page(raw, cut_out=mask is not None)
    stats = {"style": "cute_v2", "label": label, "strength": strength, "seed": seed,
             "framing": "scene" if mask is None else "subject", "regions": int(regions.max()),
             "generate_s": round(t2 - t1, 1), "total_s": round(time.perf_counter() - t0, 1)}
    return raw, page, regions, stats


def run_samples(out, strengths, seed):
    from run_samples import tile
    rows, summary = [], []
    for name, (rect, label) in SAMPLES.items():
        import skimage.data
        img = cv2.cvtColor(getattr(skimage.data, name)(), cv2.COLOR_RGB2BGR)
        v1, _, _ = convert(img, "cute", rect=rect)
        cells = [tile(img, f"{name}（原圖）"), tile(v1, "可愛 v1（不用 AI）")]
        for s in strengths:
            raw, page, regions, stats = convert_v2(img, label, rect, s, seed)
            stats["photo"] = name
            summary.append(stats)
            print(json.dumps(stats, ensure_ascii=False), flush=True)
            cv2.imwrite(str(out / f"{name}_cute_v2_raw.png"), raw)
            cv2.imwrite(str(out / f"{name}_cute_v2_page.png"), page)
            cells += [tile(raw, f"Q版 AI 生成（{s}）"), tile(page, f"Q版著色頁　{stats['regions']} 區"),
                      tile(preview_colored(page, regions), "Q版・模擬塗色")]
        rows.append(np.hstack(cells))
    sheet = np.vstack([np.pad(r, ((0, 8), (0, 0), (0, 0)), constant_values=255) for r in rows])
    cv2.imwrite(str(out / "comparison_cute_v2.jpg"), sheet, [cv2.IMWRITE_JPEG_QUALITY, 88])
    (out / "summary_cute_v2.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2))
    print(f"comparison sheet: {out / 'comparison_cute_v2.jpg'}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("image", nargs="?", help="photo to convert; omit to run the built-in samples")
    ap.add_argument("--label", help='what the photo shows, e.g. "coffee cup"')
    ap.add_argument("--rect", type=float, nargs=4, metavar=("X0", "Y0", "X1", "Y1"),
                    help="rough subject box as fractions of the photo; omit to keep the whole scene")
    ap.add_argument("--strength", type=float, nargs="+", default=[0.7],
                    help="how closely to follow the photo's lines (0..1); lower = more cartoonish")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out", default=str(Path(__file__).parent / "results"))
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)

    if a.image is None:
        run_samples(out, a.strength, a.seed)
        return
    if not a.label:
        ap.error("--label is required with an image")
    raw, page, regions, stats = convert_v2(cv2.imread(a.image), a.label, a.rect, a.strength[0], a.seed)
    stem = f"{Path(a.image).stem}_cute_v2"
    cv2.imwrite(str(out / f"{stem}_raw.png"), raw)
    cv2.imwrite(str(out / f"{stem}_page.png"), page)
    cv2.imwrite(str(out / f"{stem}_colored.png"), preview_colored(page, regions))
    print(json.dumps(stats, ensure_ascii=False))


if __name__ == "__main__":
    main()
