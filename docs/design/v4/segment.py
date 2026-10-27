"""Cut a subject out of its picture with Segment Anything (SAM, base,
Apache 2.0: https://huggingface.co/facebook/sam-vit-base), prompted with
the box around everything that differs from the plain background. Unlike
a color key it leaves out soft shadows and the floor, and keeps white fur
on a pale background.

    python3 segment.py in.png mask.png
"""
import sys

import cv2
import numpy as np

MODEL = "facebook/sam-vit-base"

_sam = None


def _model():
    global _sam
    if _sam is None:
        import os

        import torch
        from transformers import SamModel, SamProcessor
        if os.environ.get("SAM_THREADS"):
            torch.set_num_threads(int(os.environ["SAM_THREADS"]))
        _sam = SamModel.from_pretrained(MODEL).eval(), SamProcessor.from_pretrained(MODEL)
    return _sam


def _border(a):
    return np.concatenate([a[:4].reshape(-1, *a.shape[2:]), a[-4:].reshape(-1, *a.shape[2:]),
                           a[:, :4].reshape(-1, *a.shape[2:]), a[:, -4:].reshape(-1, *a.shape[2:])])


def difference(img):
    """How far each pixel's color is from the background's. The background
    is a smooth gradient fitted to the picture's border (a quadratic in x
    and y), so a sky that gets lighter across does not stand out."""
    h, w = img.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    xx, yy = xx / w - 0.5, yy / h - 0.5
    terms = np.stack([np.ones_like(xx), xx, yy, xx * xx, xx * yy, yy * yy], axis=-1)
    a, colors = _border(terms), _border(img.astype(np.float32))
    fit, *_ = np.linalg.lstsq(a, colors, rcond=None)
    # A robust fit: refit without the border pixels that are far off (a tail tip).
    keep = np.linalg.norm(a @ fit - colors, axis=1) < 25
    if keep.sum() > 100:
        fit, *_ = np.linalg.lstsq(a[keep], colors[keep], rcond=None)
    return np.linalg.norm(cv2.GaussianBlur(img, (5, 5), 0).astype(np.float32) - terms @ fit, axis=2)


def rough(img):
    """Pixels that clearly differ from the background color."""
    return cv2.morphologyEx((difference(img) > 38).astype(np.uint8), cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))


def _clean(m):
    h, w = m.shape
    n, cc, stats, _ = cv2.connectedComponentsWithStats(m, connectivity=8)
    if n > 1:
        # The biggest piece, plus pieces nearly as big (a tail tip, a far wing).
        areas = stats[1:, cv2.CC_STAT_AREA]
        keep = [i + 1 for i, a in enumerate(areas) if a >= 0.04 * areas.max()]
        m = np.isin(cc, keep).astype(np.uint8) * 255
    flood = m.copy()
    cv2.floodFill(flood, np.zeros((h + 2, w + 2), np.uint8), (0, 0), 255)
    m = m | cv2.bitwise_not(flood)  # fill holes
    # No specks along the edge; thin parts (legs, rotor blades) stay.
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)))
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5)))
    return np.where(cv2.GaussianBlur(m, (0, 0), 1.5) >= 128, 255, 0).astype(np.uint8)


def mask(img):
    """The subject's silhouette (uint8 0/255, same size) of a BGR image."""
    import torch
    r = rough(img)
    ys, xs = np.nonzero(r)
    box = [[[float(xs.min()), float(ys.min()), float(xs.max()), float(ys.max())]]]
    model, proc = _model()
    inputs = proc(img[:, :, ::-1].copy(), input_boxes=box, return_tensors="pt")
    with torch.no_grad():
        out = model(**inputs, multimask_output=True)
    masks = proc.image_processor.post_process_masks(out.pred_masks, inputs["original_sizes"], inputs["reshaped_input_sizes"])[0][0].numpy()
    # SAM makes three guesses. Some are the background (they reach the
    # picture's edge); of the others, the tightest that still holds most of
    # what stands out (the subject without its shadow and floor).
    scores = out.iou_scores[0, 0].numpy()
    found = [(m, sc) for m, sc in zip(masks, scores) if _border(m).mean() < 0.2] or list(zip(masks, scores))
    cover = [(m & (r > 0)).sum() / max(1, r.sum()) for m, _ in found]
    good = [m for (m, _), c in zip(found, cover) if c >= 0.75]
    fair = [(sc, i) for i, ((m, sc), c) in enumerate(zip(found, cover)) if c >= 0.4]
    if good:
        # SAM's surest guess, or a tighter one that only leaves out
        # something at the bottom: a shadow, the floor.
        m = max(((sc, i) for i, ((_, sc), c) in enumerate(zip(found, cover)) if c >= 0.75))
        m = found[m[1]][0]
        for t in sorted(good, key=lambda t: -t.sum()):
            left_out = m & ~t
            if t.sum() >= m.sum() or left_out.sum() < 0.01 * m.sum():
                continue
            ys = np.nonzero(m)[0]
            if np.nonzero(left_out)[0].mean() > ys.min() + 0.7 * (ys.max() - ys.min()):
                m = t
    elif fair:
        m = found[max(fair)[1]][0]  # what stands out has a shadow: SAM's surest guess
    else:
        m = found[int(np.argmax(cover))][0]
    return _clean(m.astype(np.uint8) * 255)


if __name__ == "__main__":
    cv2.imwrite(sys.argv[2], mask(cv2.imread(sys.argv[1])))
