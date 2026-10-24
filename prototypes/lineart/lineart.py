"""Phase 0 prototype: photo -> toddler-friendly coloring page.

Region-based approach: instead of tracing edges (which leaves gaps), the
subject is split into a few flat color regions and the lines are drawn on
the region borders. Every region is therefore closed by construction, so
bucket fill and the "stay inside the lines" brush always work.

Only OpenCV/NumPy are used so the same steps can later be ported to the
app (opencv_dart on Flutter). GrabCut stands in for the on-device subject
segmentation (ML Kit on Android, Vision on iOS) the app will use.
"""
import argparse
import json
import time
from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np

PROC_SIZE = 512   # long side used for segmentation
OUT_SIZE = 1024   # long side of the produced coloring page


@dataclass(frozen=True)
class Detail:
    colors: int        # k-means clusters inside the subject
    min_area: float    # smallest region, as a fraction of the subject area
    smooth: float      # border smoothing, as a fraction of PROC_SIZE
    outer_line: float  # outline thickness, as a fraction of OUT_SIZE
    inner_line: float  # inner line thickness, as a fraction of OUT_SIZE
    stroke_len: float  # shortest detail stroke kept, as a fraction of the diagonal; 0 = none


DETAILS = {
    "simple": Detail(3, 0.06, 0.020, 0.012, 0.008, stroke_len=0.10),
    "normal": Detail(5, 0.025, 0.014, 0.010, 0.006, stroke_len=0.06),
    "detailed": Detail(8, 0.008, 0.009, 0.008, 0.004, stroke_len=0.035),
}
CUTE = Detail(3, 0.10, 0.030, 0.014, 0.009, stroke_len=0)


# ---------------------------------------------------------------- subject

def resize_long(img, size, interp=cv2.INTER_AREA):
    h, w = img.shape[:2]
    s = size / max(h, w)
    return cv2.resize(img, (round(w * s), round(h * s)), interpolation=interp)


def largest_component(mask):
    n, cc, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
    if n <= 1:
        return mask
    best = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    return np.where(cc == best, 255, 0).astype(np.uint8)


def fill_holes(mask):
    h, w = mask.shape
    flood = mask.copy()
    ff = np.zeros((h + 2, w + 2), np.uint8)
    cv2.floodFill(flood, ff, (0, 0), 255)
    return mask | cv2.bitwise_not(flood)


def inscribed_radius(mask):
    """Radius of the biggest circle inside the mask: how 'thick' the subject is."""
    return float(cv2.distanceTransform((mask > 0).astype(np.uint8), cv2.DIST_L2, 5).max())


def smooth_mask(mask, sigma):
    if sigma <= 0:
        return mask
    blurred = cv2.GaussianBlur(mask, (0, 0), sigma)
    return np.where(blurred >= 128, 255, 0).astype(np.uint8)


def subject_mask(img, rect=None, smooth=0.01):
    """rect = (x0, y0, x1, y1) as fractions, or None when the subject fills the frame."""
    h, w = img.shape[:2]
    if rect is None:
        return np.full((h, w), 255, np.uint8)
    x0, y0, x1, y1 = rect
    r = (max(1, int(x0 * w)), max(1, int(y0 * h)),
         min(w - 2, int((x1 - x0) * w)), min(h - 2, int((y1 - y0) * h)))
    gc = np.zeros((h, w), np.uint8)
    bgd, fgd = np.zeros((1, 65)), np.zeros((1, 65))
    cv2.grabCut(img, gc, r, bgd, fgd, 6, cv2.GC_INIT_WITH_RECT)
    mask = np.where((gc == cv2.GC_FGD) | (gc == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, k)
    mask = fill_holes(largest_component(mask))
    sigma = min(smooth * max(h, w), 0.3 * inscribed_radius(mask))  # keep thin parts
    return largest_component(smooth_mask(mask, sigma))


def crop_to_subject(img, mask, margin):
    """Zoom in on the subject so it fills the page, padding with white where needed.

    Returns the crop and the subject box inside it (fractions), ready for a
    second, sharper segmentation pass.
    """
    H, W = img.shape[:2]
    sy, sx = H / mask.shape[0], W / mask.shape[1]
    x, y, w, h = cv2.boundingRect(mask)
    x, y, w, h = x * sx, y * sy, w * sx, h * sy
    pad = margin * max(w, h)
    cw, ch = w + 2 * pad, h + 2 * pad
    # Keep the page between 3:4 and 4:3 so it prints and displays well.
    cw, ch = max(cw, ch * 0.75), max(ch, cw * 0.75)
    cx, cy = x + w / 2, y + h / 2
    x0, y0 = int(round(cx - cw / 2)), int(round(cy - ch / 2))
    x1, y1 = int(round(cx + cw / 2)), int(round(cy + ch / 2))
    canvas = np.full((y1 - y0, x1 - x0, 3), 255, np.uint8)
    sx0, sy0, sx1, sy1 = max(0, x0), max(0, y0), min(W, x1), min(H, y1)
    canvas[sy0 - y0:sy1 - y0, sx0 - x0:sx1 - x0] = img[sy0:sy1, sx0:sx1]
    grow = 0.03 * max(w, h)
    box = ((x - grow - x0) / (x1 - x0), (y - grow - y0) / (y1 - y0),
           (x + w + grow - x0) / (x1 - x0), (y + h + grow - y0) / (y1 - y0))
    return canvas, tuple(float(np.clip(v, 0.005, 0.995)) for v in box)


# ---------------------------------------------------------------- regions

def quantize(img, mask, k):
    """Flat color clusters inside the mask; 0 = background, 1..k = clusters."""
    flat = cv2.pyrMeanShiftFiltering(img, sp=12, sr=28)
    lab = cv2.cvtColor(flat, cv2.COLOR_BGR2LAB).astype(np.float32)
    lab[..., 0] *= 0.6  # care less about shading than about hue
    pts = lab[mask > 0]
    rng = np.random.default_rng(0)
    sample = pts[rng.choice(len(pts), min(len(pts), 20000), replace=False)]
    crit = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.5)
    cv2.setRNGSeed(0)
    _, _, centers = cv2.kmeans(sample, k, None, crit, 3, cv2.KMEANS_PP_CENTERS)
    d = ((pts[:, None, :] - centers[None, :, :]) ** 2).sum(-1)
    out = np.zeros(mask.shape, np.int32)
    out[mask > 0] = d.argmin(1) + 1
    return out, lab


def majority_filter(labels, sigma):
    """Smooth borders: every pixel takes the label most common around it."""
    ids = np.unique(labels)
    best = np.full(labels.shape, -1.0, np.float32)
    out = labels.copy()
    for i in ids:
        score = cv2.GaussianBlur((labels == i).astype(np.float32), (0, 0), sigma)
        better = score > best
        out[better] = i
        best[better] = score[better]
    return out


def split_components(labels):
    """Give each connected piece of each label its own id (background stays 0)."""
    out = np.zeros(labels.shape, np.int32)
    nxt = 1
    for i in np.unique(labels):
        if i == 0:
            continue
        n, cc = cv2.connectedComponents((labels == i).astype(np.uint8), connectivity=4)
        sel = cc > 0
        out[sel] = cc[sel] + nxt - 1
        nxt += n - 1
    return out


def merge_small(labels, min_px, lab=None, contrast=30.0):
    """Greedily merge regions smaller than min_px into the neighbor they share most border with.

    With lab given, small regions that stand out from all their neighbors
    (eyes, a nose, buttons) are kept down to a fraction of min_px.
    """
    n = int(labels.max()) + 1
    area = np.bincount(labels.ravel(), minlength=n).astype(np.float64)
    if lab is not None:
        sums = np.stack([np.bincount(labels.ravel(), weights=lab[..., c].ravel(), minlength=n)
                         for c in range(3)], 1)
    border = {}
    for a, b in ((labels[:, :-1], labels[:, 1:]), (labels[:-1, :], labels[1:, :])):
        diff = a != b
        pairs = np.stack([a[diff], b[diff]], 1)
        pairs.sort(1)
        uniq, counts = np.unique(pairs, axis=0, return_counts=True)
        for (p, q), c in zip(uniq.tolist(), counts.tolist()):
            border.setdefault(p, {})[q] = border.get(p, {}).get(q, 0) + c
            border.setdefault(q, {})[p] = border.get(q, {}).get(p, 0) + c

    parent = list(range(n))

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def must_merge(i):
        if area[i] >= min_px:
            return False
        if lab is None or area[i] < 0.15 * min_px:
            return True
        mean = sums[i] / area[i]
        others = [r for r in border[i] if r != 0]
        return not others or min(np.linalg.norm(mean - sums[r] / area[r]) for r in others) < contrast

    alive = {i for i in range(1, n) if area[i] > 0}
    while True:
        small = [i for i in alive if border.get(i) and must_merge(i)]
        if not small:
            break
        i = min(small, key=lambda r: area[r])
        nbrs = border.pop(i)
        # Prefer another subject region; fall back to the background.
        target = max(nbrs, key=lambda r: (r != 0, nbrs[r]))
        parent[i] = target
        area[target] += area[i]
        if lab is not None:
            sums[target] += sums[i]
        alive.discard(i)
        for r, c in nbrs.items():
            border[r].pop(i, None)
            if r != target:
                border[target][r] = border[target].get(r, 0) + c
                border[r][target] = border[r].get(target, 0) + c

    lut = np.array([find(i) for i in range(n)], np.int32)
    return lut[labels]


def build_regions(img, mask, detail):
    h, w = mask.shape
    labels, lab = quantize(img, mask, detail.colors)
    labels = majority_filter(labels, min(detail.smooth * max(h, w), 0.3 * inscribed_radius(mask)))
    labels[mask == 0] = 0
    min_px = detail.min_area * max(1, int((mask > 0).sum()))
    return merge_small(split_components(labels), min_px, lab)


def detail_strokes(img, mask, min_len):
    """Strong, long edges (eyes, a nose, a mouth) as open strokes inside the subject.

    They do not have to close: filling flows around them, but they keep
    features that flat color regions lose, e.g. on an animal close-up.
    """
    gray = cv2.cvtColor(cv2.bilateralFilter(img, 9, 40, 9), cv2.COLOR_BGR2GRAY)
    gray = cv2.GaussianBlur(gray, (0, 0), 2.5)
    v = float(np.median(gray[mask > 0]))
    edges = cv2.Canny(gray, 0.33 * v, 0.8 * v)
    edges[cv2.erode(mask, np.ones((9, 9), np.uint8)) == 0] = 0  # the outline is drawn already
    n, cc, stats, _ = cv2.connectedComponentsWithStats(
        cv2.dilate(edges, np.ones((3, 3), np.uint8)), connectivity=8)
    w, h = stats[:, cv2.CC_STAT_WIDTH], stats[:, cv2.CC_STAT_HEIGHT]
    density = stats[:, cv2.CC_STAT_AREA] / np.maximum(1, w * h)
    # Long strokes only; dense scribbles come from glare and texture, not shapes.
    keep = (np.maximum(w, h) >= min_len * np.hypot(*mask.shape)) & (density < 0.3)
    keep[0] = False
    return keep[cc] & (edges > 0)


# ---------------------------------------------------------------- lines

def borders(labels):
    b = np.zeros(labels.shape, bool)
    b[:, :-1] |= labels[:, :-1] != labels[:, 1:]
    b[:-1, :] |= labels[:-1, :] != labels[1:, :]
    return b


def stroke(border_px, thickness):
    """Anti-aliased line coverage (0..1) of the given border pixels."""
    if not border_px.any():
        return np.zeros(border_px.shape, np.float32)
    dist = cv2.distanceTransform((~border_px).astype(np.uint8), cv2.DIST_L2, 5)
    return np.clip(thickness / 2 - dist + 0.5, 0, 1).astype(np.float32)


def upscale_labels(labels, shape, sigma):
    big = cv2.resize(labels.astype(np.float32), (shape[1], shape[0]), interpolation=cv2.INTER_NEAREST)
    return majority_filter(big.astype(np.int32), sigma)


def finish(ink, min_region_px):
    """Turn line coverage into the page image plus the region map used for filling."""
    page = np.round(255 * (1 - ink)).astype(np.uint8)
    paintable = (ink < 0.5).astype(np.uint8)
    n, cc, stats, _ = cv2.connectedComponentsWithStats(paintable, connectivity=4)
    for i in range(1, n):
        if stats[i, cv2.CC_STAT_AREA] < min_region_px:  # slivers too small to color
            page[cc == i] = 0
            cc[cc == i] = 0
    _, cc = np.unique(cc, return_inverse=True)
    return page, cc.reshape(page.shape).astype(np.int32)


# ---------------------------------------------------------------- cute extras

def roomiest_spot(labels):
    """Center and radius of the biggest circle that fits inside one region."""
    inside = ((labels > 0) & ~borders(labels)).astype(np.uint8)
    _, radius, _, center = cv2.minMaxLoc(cv2.distanceTransform(inside, cv2.DIST_L2, 5))
    return center, radius


def make_room_for_face(labels):
    """Pick the face spot; if no region is roomy enough, open a round patch mid-subject."""
    center, radius = roomiest_spot(labels)
    (sx, sy), sr = roomiest_spot((labels > 0).astype(np.int32))
    if radius >= 0.5 * sr:
        return labels, center, radius
    patch = np.zeros(labels.shape, np.uint8)
    cv2.circle(patch, (sx, sy), int(0.8 * sr), 1, -1)
    labels = np.where((patch > 0) & (labels > 0), labels[sy, sx], labels)
    return labels, (sx, sy), 0.8 * sr


def draw_face(shape, center, radius, line):
    """Kawaii face (eyes with highlights, smile, blush) that fits in the given circle."""
    cx, cy = center
    s = min(0.9 * radius, 0.18 * OUT_SIZE)
    layer = np.zeros(shape, np.uint8)
    t = max(2, round(line))
    for side in (-1, 1):
        ex, ey = int(cx + side * 0.42 * s), int(cy - 0.12 * s)
        cv2.ellipse(layer, (ex, ey), (int(0.13 * s), int(0.17 * s)), 0, 0, 360, 255, -1, cv2.LINE_AA)
        hx, hy = int(ex - 0.04 * s), int(ey - 0.06 * s)
        cv2.circle(layer, (hx, hy), max(2, int(0.045 * s)), 0, -1, cv2.LINE_AA)
        bx, by = int(cx + side * 0.72 * s), int(cy + 0.22 * s)
        cv2.ellipse(layer, (bx, by), (int(0.15 * s), int(0.09 * s)), 0, 0, 360, 255, t, cv2.LINE_AA)
    cv2.ellipse(layer, (int(cx), int(cy + 0.12 * s)), (int(0.2 * s), int(0.15 * s)), 0, 20, 160, 255, t, cv2.LINE_AA)
    return layer.astype(np.float32) / 255


def star(cx, cy, r):
    a = np.arange(10) * np.pi / 5 - np.pi / 2
    rr = np.where(np.arange(10) % 2 == 0, r, r * 0.45)
    return np.stack([cx + rr * np.cos(a), cy + rr * np.sin(a)], 1)


def heart(cx, cy, r):
    t = np.linspace(0, 2 * np.pi, 60)
    x = 16 * np.sin(t) ** 3
    y = -(13 * np.cos(t) - 5 * np.cos(2 * t) - 2 * np.cos(3 * t) - np.cos(4 * t))
    return np.stack([cx + x * r / 17, cy + y * r / 17], 1)


def draw_decorations(keepout, line, seed=1, count=6):
    """Scatter stars and hearts on the empty background."""
    h, w = keepout.shape
    layer = np.zeros((h, w), np.uint8)
    taken = keepout.copy()
    rng = np.random.default_rng(seed)
    t = max(2, round(line))
    placed = 0
    for _ in range(400):
        if placed == count:
            break
        r = rng.uniform(0.045, 0.07) * min(h, w)
        cx, cy = rng.uniform(r * 1.3, w - r * 1.3), rng.uniform(r * 1.3, h - r * 1.3)
        spot = np.zeros((h, w), np.uint8)
        cv2.circle(spot, (int(cx), int(cy)), int(r * 1.35), 255, -1)
        if (taken & (spot > 0)).any():
            continue
        shape = star(cx, cy, r) if placed % 2 == 0 else heart(cx, cy, r)
        cv2.polylines(layer, [np.round(shape).astype(np.int32)], True, 255, t, cv2.LINE_AA)
        taken |= spot > 0
        placed += 1
    return layer.astype(np.float32) / 255


# ---------------------------------------------------------------- pipeline

def convert(img, style="realistic", detail="simple", rect=None, face=True):
    """Return (page, region_map, stats). page is white with black lines."""
    t0 = time.perf_counter()
    cute = style == "cute"
    d = CUTE if cute else DETAILS[detail]
    if rect is not None:
        coarse = subject_mask(resize_long(img, PROC_SIZE), rect, smooth=0.006)
        img, rect = crop_to_subject(img, coarse, margin=0.25 if cute else 0.08)
    small = resize_long(img, PROC_SIZE)
    mask = subject_mask(small, rect, smooth=d.smooth if cute else 0.006)
    labels = build_regions(small, mask, d)

    out_h, out_w = resize_long(img, OUT_SIZE).shape[:2]
    scale = OUT_SIZE / PROC_SIZE
    sigma = min(d.smooth * OUT_SIZE * 0.5, 0.3 * inscribed_radius(mask) * scale)
    labels = upscale_labels(labels, (out_h, out_w), sigma)
    extra = np.zeros(labels.shape, np.float32)
    if cute and face:
        labels, center, radius = make_room_for_face(labels)
        extra = draw_face(labels.shape, center, radius, d.inner_line * OUT_SIZE)
    big_mask = np.where(labels > 0, 255, 0).astype(np.uint8)

    outer_px, inner_px = d.outer_line * OUT_SIZE, d.inner_line * OUT_SIZE
    edge = borders(labels)
    bg = labels == 0
    near_bg = cv2.dilate(bg.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
    outer = edge & near_bg
    inner = edge & ~near_bg
    # The image frame closes subjects that touch the edge of the photo.
    frame = np.zeros_like(edge)
    frame[[0, -1], :] = frame[:, [0, -1]] = True
    outer |= frame & ~bg

    if d.stroke_len:
        feat = detail_strokes(small, mask, d.stroke_len).astype(np.float32)
        feat = cv2.GaussianBlur(cv2.resize(feat, (out_w, out_h)), (0, 0), 1.5)
        extra = np.maximum(extra, stroke(feat > 0.15, 0.5 * inner_px))

    if cute and bg.any():
        # Sticker-style halo around the subject, then stars and hearts around it.
        halo = cv2.dilate(big_mask, cv2.getStructuringElement(
            cv2.MORPH_ELLIPSE, (int(0.05 * OUT_SIZE),) * 2))
        outer |= borders(halo > 0) & (big_mask == 0)
        keepout = cv2.dilate(halo, np.ones((9, 9), np.uint8)) > 0
        extra = np.maximum(extra, draw_decorations(keepout, inner_px))

    ink = np.maximum.reduce([stroke(outer, outer_px), stroke(inner, inner_px), extra])
    page, regions = finish(ink, min_region_px=0.0004 * out_h * out_w)

    areas = np.bincount(regions.ravel())[1:]
    stats = {
        "style": style,
        "detail": detail if style != "cute" else "cute",
        "regions": int(len(areas)),
        "smallest_region_pct": round(100 * float(areas.min()) / regions.size, 2) if len(areas) else 0,
        "ms": round(1000 * (time.perf_counter() - t0)),
    }
    return page, regions, stats


KID_PALETTE = [  # bright, toddler-friendly colors (BGR)
    (60, 76, 231), (34, 126, 230), (15, 196, 241), (113, 204, 46), (219, 152, 52),
    (182, 89, 155), (156, 188, 26), (203, 192, 255), (80, 127, 255), (185, 218, 255),
]


def preview_colored(page, regions, seed=0):
    """Fill every region with a random palette color to prove the regions are closed."""
    rng = np.random.default_rng(seed)
    colors = np.array([(255, 255, 255)] + [KID_PALETTE[i] for i in
                      rng.integers(0, len(KID_PALETTE), regions.max())], np.uint8)
    fill = colors[regions]
    return (fill.astype(np.float32) * (page[..., None] / 255.0)).astype(np.uint8)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("image")
    ap.add_argument("--style", choices=["realistic", "cute"], default="realistic")
    ap.add_argument("--detail", choices=list(DETAILS), default="simple")
    ap.add_argument("--rect", type=float, nargs=4, metavar=("X0", "Y0", "X1", "Y1"),
                    help="subject box as fractions of the photo; omit if the subject fills the frame")
    ap.add_argument("--no-face", action="store_true", help="cute style without the kawaii face")
    ap.add_argument("--out", default="out")
    a = ap.parse_args()

    img = cv2.imread(a.image)
    page, regions, stats = convert(img, a.style, a.detail, a.rect, face=not a.no_face)
    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    stem = f"{Path(a.image).stem}_{stats['detail']}"
    cv2.imwrite(str(out / f"{stem}_page.png"), page)
    cv2.imwrite(str(out / f"{stem}_regions.png"), regions.astype(np.uint16))
    cv2.imwrite(str(out / f"{stem}_colored.png"), preview_colored(page, regions))
    print(json.dumps(stats, ensure_ascii=False))


if __name__ == "__main__":
    main()
