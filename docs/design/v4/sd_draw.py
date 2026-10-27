"""Draw illustrations on this machine with open models (no service, no GPU).

DreamShaper 8, a Stable Diffusion 1.5 model tuned for illustration
(CreativeML OpenRAIL-M: the pictures may be used commercially), with the
LCM-LoRA (6 steps instead of 30), on the CPU: about a minute a picture.

    python3 sd_draw.py out_dir "prompt" [--seeds 1 2 3] [--size 512x512] [--negative "..."]

Each seed gives one PNG: out_dir/<slug>_<seed>.png.
"""
import argparse
import re
import time
from pathlib import Path

import torch
from diffusers import LCMScheduler, StableDiffusionPipeline

BASE = "Lykon/dreamshaper-8"
LCM = "latent-consistency/lcm-lora-sdv1-5"
NEGATIVE = ("text, letters, watermark, signature, frame, border, blurry, lowres, deformed, extra legs, extra limbs, "
            "missing legs, cropped, cut off, two heads, people, person")

_pipe = None


def pipe():
    global _pipe
    if _pipe is None:
        torch.set_num_threads(4)
        # fp16 files halve the download; the CPU still runs them in float32.
        p = StableDiffusionPipeline.from_pretrained(BASE, variant="fp16", torch_dtype=torch.float32, safety_checker=None, requires_safety_checker=False)
        p.scheduler = LCMScheduler.from_config(p.scheduler.config)
        p.load_lora_weights(LCM, weight_name="pytorch_lora_weights.safetensors")
        p.fuse_lora()
        p.set_progress_bar_config(disable=True)
        _pipe = p
    return _pipe


def draw(prompt, seed, size=(512, 512), negative=NEGATIVE, steps=6, guidance=1.5):
    g = torch.Generator().manual_seed(seed)
    w, h = size
    return pipe()(prompt, negative_prompt=negative, num_inference_steps=steps, guidance_scale=guidance,
                  width=w, height=h, generator=g).images[0]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("prompt")
    ap.add_argument("--name")
    ap.add_argument("--seeds", type=int, nargs="+", default=[1, 2, 3, 4])
    ap.add_argument("--size", default="512x512")
    ap.add_argument("--negative", default=NEGATIVE)
    ap.add_argument("--steps", type=int, default=6)
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    slug = a.name or re.sub(r"[^a-z0-9]+", "_", a.prompt.lower())[:40].strip("_")
    w, h = (int(v) for v in a.size.split("x"))
    for seed in a.seeds:
        t = time.time()
        draw(a.prompt, seed, (w, h), a.negative, a.steps).save(out / f"{slug}_{seed}.png")
        print(f"{slug}_{seed}.png {time.time() - t:.0f}s", flush=True)


if __name__ == "__main__":
    main()
