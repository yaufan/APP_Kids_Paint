"""Turn an illustration of one subject on a plain background into a coloring page.

1. Cut the subject out with Segment Anything (segment.py): shadows and the
   floor stay out.
2. Find its edges with TEED (the edge network the app uses, here in NumPy:
   prototypes/lineart/teed_numpy.py), after smoothing fur and texture away.
3. Split it where the edges are clear: basins of the edge map, merged
   across soft borders (shading) and merged when too small or thin to
   color. The panda's black legs, the clownfish's white bands and the
   giraffe's big spots have sharp borders and stay their own patches.
4. Add the clearest edges that do not close a patch: an eye, a fold.
5. Draw a closed outline (a little thicker) and the inside lines (thin) on
   a 600 x 800 page, the subject as big as fits.

    python3 to_page.py in.png out.png [--flip] [--strength 0.3] [--min-area 900] [--detail 0.5] [--min-width 5]
"""
import argparse
import sys
from pathlib import Path

import cv2
import numpy as np
from skimage.morphology import skeletonize

sys.path.insert(0, str(Path(__file__).resolve().parents[3] / "prototypes" / "lineart"))
import teed_numpy  # noqa: E402

import segment  # noqa: E402

PAGE_W, PAGE_H = 600, 800
FIT = (40, 90, 560, 730)  # where the subject goes on the page
OUTLINE, INNER = 5.5, 3.2  # line widths in page pixels
TEED_WEIGHTS = Path(__file__).resolve().parents[3] / "app" / "assets" / "models" / "teed.bin"

_net = None


def teed():
    """The app's TEED weights, read from its asset file."""
    global _net
    if _net is None:
        import struct
        data = TEED_WEIGHTS.read_bytes()
        count = struct.unpack_from("<I", data, 8)[0]
        at, p = 12, {}
        for _ in range(count):
            n = struct.unpack_from("<H", data, at)[0]
            name = data[at + 2:at + 2 + n].decode()
            at += 2 + n
            rank = data[at]
            at += 1
            shape = struct.unpack_from(f"<{rank}I", data, at)
            at += 4 * rank
            size = int(np.prod(shape))
            p[name] = np.frombuffer(data, "<f4", size, at).reshape(shape).astype(np.float32)
            at += 4 * size
        net = teed_numpy.TEED.__new__(teed_numpy.TEED)
        net.p = p
        _net = net
    return _net


def edges(img):
    """TEED edge strength (0..1), as the app computes it."""
    x = cv2.bilateralFilter(cv2.medianBlur(img, 5), 9, 40, 5)
    outs = teed().forward((x.astype(np.float32) - teed_numpy.MEAN_BGR).transpose(2, 0, 1))  # OpenCV images are BGR already
    with np.errstate(over="ignore"):
        e = np.mean([1 / (1 + np.exp(-o[0])) for o in outs], 0)
    return (e - e.min()) / max(1e-6, e.max() - e.min())


def _borders(labels):
    """Pixels next to a pixel of another label."""
    e = np.zeros(labels.shape, bool)
    dx = labels[:, 1:] != labels[:, :-1]
    dy = labels[1:] != labels[:-1]
    e[:, 1:] |= dx
    e[:, :-1] |= dx
    e[1:] |= dy
    e[:-1] |= dy
    return e


def patches(e, mask, strength=0.3, min_area=900, min_width=5):
    """The subject split where its edges are clear (int32 labels, -1
    outside): basins of the edge map (watershed), merged across borders
    whose mean edge is weaker than [strength], then patches smaller than
    [min_area] or thinner than [min_width] px merged into the neighbor
    they share most border with."""
    from skimage import graph
    from skimage.morphology import h_minima
    from skimage.segmentation import watershed

    es = cv2.GaussianBlur(e.astype(np.float32), (0, 0), 1.2)
    _, markers = cv2.connectedComponents((h_minima(es, 0.04) > 0).astype(np.uint8) & mask.astype(np.uint8), connectivity=8)
    basins = watershed(es, markers, mask=mask)
    rag = graph.rag_boundary(basins, es)
    if 0 in rag:
        rag.remove_node(0)  # outside: never merged into

    def weight(g, src, dst, n):
        # The merged border's mean edge: both borders, weighted by length.
        a = g[src].get(n, {"weight": 0.0, "count": 0})
        b = g[dst].get(n, {"weight": 0.0, "count": 0})
        count = a["count"] + b["count"]
        return {"count": count, "weight": (a["weight"] * a["count"] + b["weight"] * b["count"]) / max(1, count)}

    labels = graph.merge_hierarchical(basins, rag, thresh=strength, rag_copy=False, in_place_merge=True,
                                      merge_func=lambda g, src, dst: None, weight_func=weight)
    labels = np.where(mask, labels, -1).astype(np.int32)

    labels = _merge_small(labels, min_area, min_width)
    # Smooth borders: each pixel takes the label most of its neighbors have;
    # that can leave crumbs, which go too.
    votes = np.full(labels.shape, -1.0, np.float32)
    smooth = labels.copy()
    for i in range(labels.max() + 1):
        v = cv2.GaussianBlur((labels == i).astype(np.float32), (0, 0), 3.0)
        better = mask & (v > votes)
        smooth[better], votes[better] = i, v[better]
    return _merge_small(smooth, min_area, min_width)


def _pieces(labels):
    """Labels renumbered 0.. so that each is one connected piece (-1 stays)."""
    out = np.full(labels.shape, -1, np.int32)
    n = 0
    for i in np.unique(labels[labels >= 0]):
        count, cc = cv2.connectedComponents((labels == i).astype(np.uint8), connectivity=4)
        out[cc > 0] = cc[cc > 0] - 1 + n
        n += count - 1
    return out


def _merge_small(labels, min_area, min_width):
    """Pieces smaller than [min_area] px or thinner than [min_width] px go
    into the neighbor they share most border with."""
    for _ in range(6):
        labels = _pieces(labels)
        n = labels.max() + 1
        inside = labels >= 0
        dist = cv2.distanceTransform((~_borders(labels)).astype(np.uint8), cv2.DIST_L2, 3)
        areas = np.bincount(labels[inside], minlength=n)
        width = np.zeros(n, np.float32)
        np.maximum.at(width, labels[inside], dist[inside])
        small = [i for i in np.argsort(areas) if areas[i] and (areas[i] < min_area or width[i] < min_width)]
        if not small:
            break
        for i in small:
            ys, xs = np.nonzero(labels == i)
            if not len(ys):
                continue
            y0, x0 = max(0, ys.min() - 2), max(0, xs.min() - 2)
            sub = labels[y0:ys.max() + 3, x0:xs.max() + 3]
            me = sub == i
            ring = cv2.dilate(me.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0
            around = sub[ring & ~me]
            around = around[around >= 0]
            if len(around):
                sub[me] = np.bincount(around).argmax()
    return labels


def patch_lines(labels):
    """1 px lines between patches (not along the outline)."""
    e = np.zeros(labels.shape, bool)
    a, b = labels[:, :-1], labels[:, 1:]
    e[:, :-1] |= (a != b) & (a >= 0) & (b >= 0)
    a, b = labels[:-1], labels[1:]
    e[:-1] |= (a != b) & (a >= 0) & (b >= 0)
    return skeletonize(cv2.dilate(e.astype(np.uint8), np.ones((2, 2), np.uint8)) > 0)


def stroke(center, width):
    """Anti-aliased line coverage (0..1) [width] px wide around 1 px center lines."""
    if not center.any():
        return np.zeros(center.shape, np.float32)
    dist = cv2.distanceTransform((~center).astype(np.uint8), cv2.DIST_L2, 5)
    return np.clip(width / 2 - dist + 0.5, 0, 1).astype(np.float32)


def place(img, mask, flip=False):
    """The subject cropped, flipped if asked and scaled to fit the page:
    (picture, silhouette, left, top) in page pixels."""
    ys, xs = np.nonzero(mask)
    pad = 6
    x0, y0 = max(0, xs.min() - pad), max(0, ys.min() - pad)
    x1, y1 = min(img.shape[1], xs.max() + 1 + pad), min(img.shape[0], ys.max() + 1 + pad)
    crop, cmask = img[y0:y1, x0:x1], mask[y0:y1, x0:x1]
    if flip:
        crop, cmask = crop[:, ::-1].copy(), cmask[:, ::-1].copy()
    fx0, fy0, fx1, fy1 = FIT
    s = min((fx1 - fx0) / crop.shape[1], (fy1 - fy0) / crop.shape[0])
    w, h = round(crop.shape[1] * s / 8) * 8, round(crop.shape[0] * s / 8) * 8
    big = cv2.resize(crop, (w, h), interpolation=cv2.INTER_CUBIC)
    bmask = cv2.resize(cmask, (w, h), interpolation=cv2.INTER_LINEAR) >= 128
    return big, bmask, (fx0 + fx1 - w) // 2, (fy0 + fy1 - h) // 2


def reference(img, flip=False, mask=None):
    """The subject in color where its page puts it (BGR, 600 x 800, white
    around it): what it really looks like, to color the demo's residents."""
    if mask is None:
        mask = segment.mask(img)
    big, bmask, ox, oy = place(img, mask, flip)
    out = np.full((PAGE_H, PAGE_W, 3), 255, np.uint8)
    h, w = bmask.shape
    out[oy:oy + h, ox:ox + w][bmask] = big[bmask]
    return out


def page(img, flip=False, strength=0.3, min_area=900, detail=0.5, min_width=5, mask=None):
    """The coloring page (uint8 grayscale, 600 x 800) for one subject image:
    its outline, the borders of its patches (see [patches]) and, by
    [detail] (0..1), the clearest lines that close no patch. [mask] is the
    subject's silhouette if already known."""
    if mask is None:
        mask = segment.mask(img)
    big, bmask, ox, oy = place(img, mask, flip)
    h, w = bmask.shape

    e = edges(big)
    borders = patch_lines(patches(e, bmask, strength, min_area, min_width))

    # other lines: strong edges and what continues them, thinned, long ones
    inside = cv2.erode(bmask.astype(np.uint8), np.ones((9, 9), np.uint8)) > 0
    near = cv2.dilate(borders.astype(np.uint8), np.ones((7, 7), np.uint8)) > 0
    e = np.where(inside & ~near, e, 0)
    high = 0.8 - 0.35 * detail
    low = 0.45 * high
    n, cc = cv2.connectedComponents((e > low).astype(np.uint8), connectivity=8)
    seeded = np.zeros(n, bool)
    seeded[np.unique(cc[e > high])] = True
    seeded[0] = False
    center = skeletonize(seeded[cc])
    n, cc, stats, _ = cv2.connectedComponentsWithStats(center.astype(np.uint8), connectivity=8)
    length = stats[:, cv2.CC_STAT_AREA]
    peak = np.zeros(n, np.float32)
    np.maximum.at(peak, cc[center], e[center])
    # Long lines, and short very clear ones (an eye, a nostril).
    keep = (length >= (0.12 - 0.07 * detail) * np.hypot(w, h)) | ((length >= 18) & (peak >= 0.9) & (detail >= 0.5))
    keep[0] = detail <= 0  # none at all: patches only
    center = skeletonize(cv2.GaussianBlur(keep[cc].astype(np.float32), (0, 0), 1.0) > 0.2) | borders

    # the outline: the silhouette's edge, closed
    edge = bmask & ~(cv2.erode(bmask.astype(np.uint8), np.ones((3, 3), np.uint8)) > 0)
    ink = np.maximum(stroke(center, INNER), stroke(edge, OUTLINE))

    out = np.full((PAGE_H, PAGE_W), 255, np.uint8)
    out[oy:oy + h, ox:ox + w] = np.round(255 * (1 - ink)).astype(np.uint8)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--flip", action="store_true")
    ap.add_argument("--strength", type=float, default=0.3)
    ap.add_argument("--min-area", type=int, default=900)
    ap.add_argument("--detail", type=float, default=0.5)
    ap.add_argument("--min-width", type=float, default=5)
    a = ap.parse_args()
    cv2.imwrite(a.dst, page(cv2.imread(a.src), a.flip, a.strength, a.min_area, a.detail, a.min_width))


if __name__ == "__main__":
    main()
