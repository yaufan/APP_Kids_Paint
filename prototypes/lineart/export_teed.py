"""Export TEED's weights for the app, plus a small reference for its tests.

  python export_teed.py path/to/TEED/checkpoints/BIPED/5/5_model.pth

Writes app/assets/models/teed.bin (every tensor, float32, little endian)
and app/test/fixtures/teed_reference.bin (a random input and the four
outputs of teed_numpy.py for it), so the Dart port can be checked against
this NumPy version.

teed.bin: b"TEED", uint32 version (1), uint32 tensor count, then per tensor
uint16 name length, name (utf-8), uint8 rank, uint32 dims[rank], float32 data.
"""
import struct
import sys
from pathlib import Path

import numpy as np

from teed_numpy import TEED

APP = Path(__file__).resolve().parents[2] / "app"


def write_tensors(path, tensors):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "wb") as f:
        f.write(b"TEED" + struct.pack("<II", 1, len(tensors)))
        for name, a in tensors.items():
            a = np.ascontiguousarray(a, "<f4")
            raw = name.encode()
            f.write(struct.pack("<H", len(raw)) + raw + struct.pack("<B", a.ndim))
            f.write(struct.pack(f"<{a.ndim}I", *a.shape))
            f.write(a.tobytes())
    print(path, path.stat().st_size, "bytes")


def main():
    net = TEED(sys.argv[1])
    write_tensors(APP / "assets/models/teed.bin", net.p)
    rng = np.random.default_rng(7)
    x = rng.uniform(-110, 140, (3, 24, 32)).astype(np.float32)  # BGR minus mean, 24x32
    outs = net.forward(x)
    ref = {"input": x, **{f"out{i}": o for i, o in enumerate(outs)}}
    write_tensors(APP / "test/fixtures/teed_reference.bin", ref)


if __name__ == "__main__":
    main()
