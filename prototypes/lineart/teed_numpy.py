"""TEED (Tiny and Efficient Edge Detector, MIT license) in plain NumPy.

Reads the PyTorch checkpoint without PyTorch and runs the forward pass, so
the edges can be compared with DexiNed here and used as the reference for
the app's Dart port. Architecture: https://github.com/xavysp/TEED (ted.py).
"""
import pickle
import sys
import zipfile
from collections import OrderedDict
from pathlib import Path

import numpy as np

MEAN_BGR = np.array([104.007, 116.669, 122.679], np.float32)


# ---------------------------------------------------------------- checkpoint

def load_state_dict(path):
    """A torch.save()'d state dict as {name: float32 array}, without torch."""
    z = zipfile.ZipFile(path)
    root = z.namelist()[0].split("/")[0]

    class Storage:
        def __init__(self, dtype):
            self.dtype = dtype

    class Unpickler(pickle.Unpickler):
        def find_class(self, module, name):
            if module == "torch._utils" and name == "_rebuild_tensor_v2":
                def rebuild(storage, offset, size, stride, *_):
                    item = storage.itemsize
                    return np.lib.stride_tricks.as_strided(
                        storage[offset:], shape=size, strides=[s * item for s in stride]).copy()
                return rebuild
            if module == "torch" and name.endswith("Storage"):
                return {"FloatStorage": np.float32, "LongStorage": np.int64}[name]
            if module == "collections" and name == "OrderedDict":
                return OrderedDict
            return super().find_class(module, name)

        def persistent_load(self, pid):
            _, dtype, key, _, numel = pid
            data = z.read(f"{root}/data/{key}")
            return np.frombuffer(data, dtype=dtype, count=numel)

    return Unpickler(z.open(f"{root}/data.pkl")).load()


# ---------------------------------------------------------------- layers

def smish(x):
    return x * np.tanh(np.log1p(1 / (1 + np.exp(-x))))


def conv2d(x, w, b, stride=1, pad=0, groups=1):
    """x: (C, H, W); w: (O, C/groups, k, k)."""
    c, h, wd = x.shape
    o, cg, k, _ = w.shape
    xp = np.pad(x, ((0, 0), (pad, pad), (pad, pad)))
    oh = (h + 2 * pad - k) // stride + 1
    ow = (wd + 2 * pad - k) // stride + 1
    out = np.zeros((o, oh, ow), np.float32)
    og = o // groups
    for g in range(groups):
        xs = xp[g * cg:(g + 1) * cg]
        ws = w[g * og:(g + 1) * og]
        for dy in range(k):
            for dx in range(k):
                patch = xs[:, dy:dy + stride * oh:stride, dx:dx + stride * ow:stride]
                out[g * og:(g + 1) * og] += np.einsum("oc,chw->ohw", ws[:, :, dy, dx], patch)
    return out + b[:, None, None]


def conv_transpose2d(x, w, b, stride, pad):
    """x: (C, H, W); w: (C, O, k, k), as in torch.nn.ConvTranspose2d."""
    c, h, wd = x.shape
    _, o, k, _ = w.shape
    full_h, full_w = (h - 1) * stride + k, (wd - 1) * stride + k
    out = np.zeros((o, full_h, full_w), np.float32)
    for dy in range(k):
        for dx in range(k):
            out[:, dy:dy + stride * h:stride, dx:dx + stride * wd:stride] += np.einsum("co,chw->ohw", w[:, :, dy, dx], x)
    out = out[:, pad:full_h - pad, pad:full_w - pad]
    return out + b[:, None, None]


def maxpool3s2(x):
    c, h, w = x.shape
    xp = np.pad(x, ((0, 0), (1, 1), (1, 1)), constant_values=-np.inf)
    oh, ow = (h - 1) // 2 + 1, (w - 1) // 2 + 1
    out = np.full((c, oh, ow), -np.inf, np.float32)
    for dy in range(3):
        for dx in range(3):
            out = np.maximum(out, xp[:, dy:dy + 2 * oh:2, dx:dx + 2 * ow:2])
    return out


# ---------------------------------------------------------------- network

class TEED:
    def __init__(self, checkpoint):
        self.p = {k: v.astype(np.float32) for k, v in load_state_dict(checkpoint).items()}

    def conv(self, name, x, **kw):
        return conv2d(x, self.p[name + ".weight"], self.p[name + ".bias"], **kw)

    def double_conv(self, name, x, stride=1, act=True):
        x = smish(self.conv(name + ".conv1", x, stride=stride, pad=1))
        x = self.conv(name + ".conv2", x, pad=1)
        return smish(x) if act else x

    def up_block(self, name, x, up_scale):
        pad = [0, 0, 1, 3, 7][up_scale]
        for i in range(up_scale):
            x = smish(self.conv(f"{name}.features.{3 * i}", x))
            t = f"{name}.features.{3 * i + 2}"
            x = conv_transpose2d(x, self.p[t + ".weight"], self.p[t + ".bias"], 2, pad)
        return x

    def forward(self, x):
        """x: (3, H, W) BGR minus MEAN_BGR, H and W multiples of 8. Returns the 4 logit maps."""
        block_1 = self.double_conv("block_1", x, stride=2)
        block_1_side = self.conv("side_1.conv", block_1, stride=2)
        block_2 = self.double_conv("block_2", block_1, act=False)
        block_2_down = maxpool3s2(block_2)
        block_2_add = block_2_down + block_1_side
        block_3_pre = self.conv("pre_dense_3.conv", block_2_down)
        d = self.conv("dblock_3.denselayer1.conv1", smish(block_2_add), pad=2)
        d = self.conv("dblock_3.denselayer1.conv2", smish(d))
        block_3 = 0.5 * (d + block_3_pre)
        outs = [self.up_block("up_block_1", block_1, 1),
                self.up_block("up_block_2", block_2, 1),
                self.up_block("up_block_3", block_3, 2)]
        cat = np.concatenate(outs, 0)
        a1 = self.conv("block_cat.DWconv1", smish(cat), pad=1, groups=3)
        a2 = self.conv("block_cat.DWconv2", smish(a1), pad=1, groups=24)
        fused = smish((a2 + a1).sum(0, keepdims=True))
        return outs + [fused]


def edge_map(net, bgr, long_side=640):
    """Edge probability (0..1) per pixel of a BGR uint8 image, from the fused output."""
    import cv2
    h, w = bgr.shape[:2]
    s = long_side / max(h, w)
    size = (max(8, round(w * s / 8) * 8), max(8, round(h * s / 8) * 8))
    x = cv2.resize(bgr, size, interpolation=cv2.INTER_AREA).astype(np.float32) - MEAN_BGR
    fused = net.forward(x.transpose(2, 0, 1))[-1][0]
    return cv2.resize(1 / (1 + np.exp(-fused)), (w, h))


if __name__ == "__main__":
    import cv2
    net = TEED(sys.argv[1])
    print({k: v.shape for k, v in net.p.items()})
    print("params", sum(v.size for v in net.p.values()))
    for path in sys.argv[2:]:
        img = cv2.imread(path)
        e = edge_map(net, img)
        out = Path(path).with_suffix(".teed.png")
        cv2.imwrite(str(out), np.round(255 * (1 - e)).astype(np.uint8))
        print(out)
