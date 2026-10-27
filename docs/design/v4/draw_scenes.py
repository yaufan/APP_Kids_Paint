"""Paint the scenes: each vector scene (docs/design/v3/src/creatures.py)
is the layout, and Stable Diffusion repaints it as a detailed picture-book
illustration (img2img), so the ground, the road and the track stay where
the creatures expect them.

    python3 draw_scenes.py out_dir [habitats...] [--seeds 1 2 3] [--strength 0.55]
"""
import argparse
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import torch
from diffusers import StableDiffusionImg2ImgPipeline
from PIL import Image

import sd_draw

SRC = Path(__file__).resolve().parents[1] / "v3" / "src"
sys.path.insert(0, str(SRC))
import creatures  # noqa: E402

PAINT = "empty landscape, nobody, detailed children's picture book painting, soft natural light, rich colors, high quality"
# Negative prompts do little at LCM's low guidance, so the prompts avoid
# words that bring animals or people along ("zoo", "aquarium", "dinosaur").
NEGATIVE = "text, letters, watermark, signature, frame, border, blurry, lowres, people, person, animals, fish, cartoon emoji, flat vector"
PROMPTS = {
    "zoo": "a sunny savanna park, acacia trees on green hills, a big rock with a small waterfall into a pond, a bamboo grove, a wooden fence, a grassy meadow with a sandy path",
    "aquarium": "an empty underwater glass tunnel, a coral reef with colorful corals, rocks, seaweed, a sandy sea floor, sunbeams through clear blue water",
    "dinoPark": "a prehistoric jungle valley, a smoking volcano, palm trees and ferns, a swamp, a nest of big spotted eggs, old bones on the grass",
    "transport": "a museum plaza, a big glass-roofed exhibition hall, an empty railway track, an empty two-lane asphalt road with a zebra crossing, traffic lights, a bus stop sign, trees, blue sky",
    "botanical": "a botanical garden, a big glass greenhouse with palm trees inside, colorful flower beds along a path, a small lily pond, a lush green lawn",
    "insects": "a sunny meadow with wildflowers and tall grass, a tree stump, a log and mushrooms, a round red house shaped like a ladybug, trees",
    "shop": "a cozy little shop interior, a red and white striped awning, warm hanging lamps, a big wall of empty wooden shelves, "
            "a checkered tile floor, a potted plant, a wicker basket",
    "space": "outer space, a starry purple night sky, the blue planet earth, an orange ringed planet, a small pink planet, "
             "the grey surface of the moon with craters, a metal launch tower, a small white dome base",
    "nightMarket": "a taiwanese night market street at dusk, glowing red and yellow paper lanterns on a string, a row of empty food stalls "
                   "with striped awnings and wooden shelves, a long table with a red cloth, a blue goldfish pool, brick pavement, nobody",
    "polar": "an arctic landscape at night, green and purple northern lights, white icebergs, ice floes on a calm dark blue sea, "
             "snowy white ground, a red flag, small ice blocks",
}

_img2img = None


def img2img():
    global _img2img
    if _img2img is None:
        _img2img = StableDiffusionImg2ImgPipeline(**sd_draw.pipe().components)
        _img2img.set_progress_bar_config(disable=True)
    return _img2img


def layout(habitat, size):
    with tempfile.TemporaryDirectory() as tmp:
        svg, png = Path(tmp) / "s.svg", Path(tmp) / "s.png"
        svg.write_text(creatures.SCENES[habitat]())
        subprocess.run(["node", str(SRC / "render_svg.js"), str(svg), str(png), "1000", "1000"], check=True)
        return Image.open(png).convert("RGB").resize((size, size), Image.LANCZOS)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("out")
    ap.add_argument("habitats", nargs="*")
    ap.add_argument("--seeds", type=int, nargs="+", default=[1, 2, 3])
    ap.add_argument("--strength", type=float, default=0.55)
    ap.add_argument("--size", type=int, default=768)
    a = ap.parse_args()
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    for habitat in a.habitats or list(PROMPTS):
        base = layout(habitat, a.size)
        base.save(out / f"{habitat}_layout.png")
        for seed in a.seeds:
            t = time.time()
            image = img2img()(f"{PROMPTS[habitat]}, {PAINT}", image=base, strength=a.strength, negative_prompt=NEGATIVE,
                              num_inference_steps=8, guidance_scale=1.5, generator=torch.Generator().manual_seed(seed)).images[0]
            image.save(out / f"{habitat}_{seed}.png")
            print(f"{habitat}_{seed}.png {time.time() - t:.0f}s", flush=True)


if __name__ == "__main__":
    main()
