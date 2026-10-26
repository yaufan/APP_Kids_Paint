import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// TEED, a tiny edge detector (MIT license, Xavier Soria Poma,
/// https://github.com/xavysp/TEED): 58,910 learned weights that find the
/// outlines a person would draw in a photo, and skip most texture.
///
/// A plain Dart port of `prototypes/lineart/teed_numpy.py`, so it runs on
/// every phone without native code or a network. Maps are stored row by
/// row with their channels side by side (height x width x channels).
class Teed {
  Teed._(this._t);

  /// Reads `assets/models/teed.bin` (written by `prototypes/lineart/export_teed.py`).
  factory Teed.decode(Uint8List bytes) => Teed._(readTensors(bytes));

  final Map<String, Tensor> _t;

  /// BGR channel means the network was trained with.
  static const meanBgr = [104.007, 116.669, 122.679];

  /// Runs the network on [bgr]: [width] x [height] x 3, already minus
  /// [meanBgr]; both sides multiples of 8. Returns its four maps of edge
  /// logits, each [width] x [height]: three scales and their fusion.
  List<Float32List> run(Float32List bgr, int width, int height) {
    assert(width % 8 == 0 && height % 8 == 0 && bgr.length == width * height * 3);
    final x = FeatureMap(height, width, 3, bgr);
    final block1 = _doubleConv('block_1', x, stride: 2);
    final block1Side = _conv('side_1.conv', block1, stride: 2);
    final block2 = _doubleConv('block_2', block1, act: false);
    final block2Down = _maxPool(block2);
    final block2Add = _add(block2Down, block1Side);
    final block3Pre = _conv('pre_dense_3.conv', block2Down);
    var d = _conv('dblock_3.denselayer1.conv1', _smish(_copy(block2Add)), pad: 2);
    d = _conv('dblock_3.denselayer1.conv2', _smish(d));
    final block3 = _add(d, block3Pre)..scale(0.5);
    final outs = [_upBlock('up_block_1', block1, 1), _upBlock('up_block_2', block2, 1), _upBlock('up_block_3', block3, 2)];

    // Double fusion: two depthwise convolutions over the three scales.
    final cat = FeatureMap(height, width, 3);
    for (var i = 0, n = height * width; i < n; i++) {
      cat.data[3 * i] = outs[0].data[i];
      cat.data[3 * i + 1] = outs[1].data[i];
      cat.data[3 * i + 2] = outs[2].data[i];
    }
    final a1 = _conv('block_cat.DWconv1', _smish(cat), pad: 1, groups: 3);
    final a2 = _conv('block_cat.DWconv2', _smish(_copy(a1)), pad: 1, groups: 24);
    final fused = Float32List(height * width);
    for (var i = 0; i < fused.length; i++) {
      var s = 0.0;
      for (var c = 0; c < 24; c++) {
        s += a1.data[i * 24 + c] + a2.data[i * 24 + c];
      }
      fused[i] = smish(s);
    }
    return [for (final o in outs) o.data, fused];
  }

  FeatureMap _doubleConv(String name, FeatureMap x, {int stride = 1, bool act = true}) {
    final y = _smish(_conv('$name.conv1', x, stride: stride, pad: 1));
    final z = _conv('$name.conv2', y, pad: 1);
    return act ? _smish(z) : z;
  }

  FeatureMap _upBlock(String name, FeatureMap x, int upScale) {
    const pads = [0, 0, 1, 3, 7];
    for (var i = 0; i < upScale; i++) {
      x = _smish(_conv('$name.features.${3 * i}', x));
      x = _convTranspose('$name.features.${3 * i + 2}', x, pads[upScale]);
    }
    return x;
  }

  FeatureMap _conv(String name, FeatureMap x, {int stride = 1, int pad = 0, int groups = 1}) {
    final w = _t['$name.weight']!, b = _t['$name.bias']!;
    return groups == 1 ? conv2d(x, w, b, stride: stride, pad: pad) : depthwiseConv2d(x, w, b, pad: pad, groups: groups);
  }

  FeatureMap _convTranspose(String name, FeatureMap x, int pad) => convTranspose2d(x, _t['$name.weight']!, _t['$name.bias']!, pad: pad);
}

/// A learned array and its shape, as PyTorch stores it.
class Tensor {
  Tensor(this.shape, this.data);

  final List<int> shape;
  final Float32List data;
}

/// Height x width x channels, channels side by side.
class FeatureMap {
  FeatureMap(this.height, this.width, this.channels, [Float32List? data]) : data = data ?? Float32List(height * width * channels);

  final int height;
  final int width;
  final int channels;
  final Float32List data;

  void scale(double k) {
    for (var i = 0; i < data.length; i++) {
      data[i] *= k;
    }
  }
}

/// Tensors from a `TEED` file: b"TEED", version 1, count, then per tensor
/// a name, a shape and little-endian float32 data.
Map<String, Tensor> readTensors(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  if (ascii.decode(bytes.sublist(0, 4)) != 'TEED' || view.getUint32(4, Endian.little) != 1) {
    throw const FormatException('not a TEED weights file');
  }
  final count = view.getUint32(8, Endian.little);
  var at = 12;
  final out = <String, Tensor>{};
  for (var i = 0; i < count; i++) {
    final nameLength = view.getUint16(at, Endian.little);
    final name = utf8.decode(bytes.sublist(at + 2, at + 2 + nameLength));
    at += 2 + nameLength;
    final rank = view.getUint8(at++);
    final shape = [for (var r = 0; r < rank; r++) view.getUint32(at + 4 * r, Endian.little)];
    at += 4 * rank;
    final n = shape.fold(1, (a, b) => a * b);
    final data = Float32List(n);
    for (var k = 0; k < n; k++) {
      data[k] = view.getFloat32(at + 4 * k, Endian.little);
    }
    at += 4 * n;
    out[name] = Tensor(shape, data);
  }
  return out;
}

/// Smish activation, x * tanh(ln(1 + sigmoid(x))): with s = sigmoid(x) and
/// a = (1 + s)^2, tanh(ln(1 + s)) = (a - 1) / (a + 1).
double smish(double x) {
  final s = 1 / (1 + math.exp(-x));
  final a = (1 + s) * (1 + s);
  return x * (a - 1) / (a + 1);
}

FeatureMap _smish(FeatureMap x) {
  final d = x.data;
  for (var i = 0; i < d.length; i++) {
    d[i] = smish(d[i]);
  }
  return x;
}

FeatureMap _copy(FeatureMap x) => FeatureMap(x.height, x.width, x.channels, Float32List.fromList(x.data));

FeatureMap _add(FeatureMap a, FeatureMap b) {
  assert(a.data.length == b.data.length);
  final out = FeatureMap(a.height, a.width, a.channels);
  for (var i = 0; i < out.data.length; i++) {
    out.data[i] = a.data[i] + b.data[i];
  }
  return out;
}

/// 3 x 3 max pooling, stride 2, padding 1.
FeatureMap _maxPool(FeatureMap x) {
  final oh = (x.height - 1) ~/ 2 + 1, ow = (x.width - 1) ~/ 2 + 1, c = x.channels;
  final out = FeatureMap(oh, ow, c);
  for (var oy = 0; oy < oh; oy++) {
    for (var ox = 0; ox < ow; ox++) {
      final o = (oy * ow + ox) * c;
      for (var ch = 0; ch < c; ch++) {
        var m = double.negativeInfinity;
        for (var ky = -1; ky <= 1; ky++) {
          final iy = 2 * oy + ky;
          if (iy < 0 || iy >= x.height) continue;
          for (var kx = -1; kx <= 1; kx++) {
            final ix = 2 * ox + kx;
            if (ix < 0 || ix >= x.width) continue;
            m = math.max(m, x.data[(iy * x.width + ix) * c + ch]);
          }
        }
        out.data[o + ch] = m;
      }
    }
  }
  return out;
}

/// A convolution with weights (out, in, k, k), four output channels at a
/// time when their number allows it.
FeatureMap conv2d(FeatureMap x, Tensor weight, Tensor bias, {int stride = 1, int pad = 0}) {
  final outC = weight.shape[0], inC = weight.shape[1], k = weight.shape[2];
  assert(inC == x.channels);
  final oh = (x.height + 2 * pad - k) ~/ stride + 1, ow = (x.width + 2 * pad - k) ~/ stride + 1;
  final out = FeatureMap(oh, ow, outC);
  final w = weight.data, src = x.data, dst = out.data;
  final iw = x.width, ih = x.height;

  if (outC % 4 != 0) {
    for (var oy = 0; oy < oh; oy++) {
      for (var ox = 0; ox < ow; ox++) {
        for (var o = 0; o < outC; o++) {
          var s = bias.data[o];
          for (var ky = 0; ky < k; ky++) {
            final iy = oy * stride - pad + ky;
            if (iy < 0 || iy >= ih) continue;
            for (var kx = 0; kx < k; kx++) {
              final ix = ox * stride - pad + kx;
              if (ix < 0 || ix >= iw) continue;
              final at = (iy * iw + ix) * inC;
              for (var c = 0; c < inC; c++) {
                s += src[at + c] * w[((o * inC + c) * k + ky) * k + kx];
              }
            }
          }
          dst[(oy * ow + ox) * outC + o] = s;
        }
      }
    }
    return out;
  }

  // Weights regrouped as [tap][in][out / 4] so the inner loop multiplies one
  // input value by four output channels at once.
  final o4 = outC ~/ 4;
  final wq = Float32x4List(k * k * inC * o4);
  for (var ky = 0; ky < k; ky++) {
    for (var kx = 0; kx < k; kx++) {
      for (var c = 0; c < inC; c++) {
        for (var q = 0; q < o4; q++) {
          double at(int o) => w[((o * inC + c) * k + ky) * k + kx];
          wq[((ky * k + kx) * inC + c) * o4 + q] = Float32x4(at(4 * q), at(4 * q + 1), at(4 * q + 2), at(4 * q + 3));
        }
      }
    }
  }
  final bq = Float32x4List.view(Float32List.fromList(bias.data).buffer);
  final dq = Float32x4List.view(dst.buffer);
  if (o4 % 4 == 0) {
    // 16, 32 or 48 channels: sixteen at a time in local variables, which
    // stay in registers (about twice as fast as accumulating in memory).
    for (var oy = 0; oy < oh; oy++) {
      for (var ox = 0; ox < ow; ox++) {
        for (var q0 = 0; q0 < o4; q0 += 4) {
          var a0 = bq[q0], a1 = bq[q0 + 1], a2 = bq[q0 + 2], a3 = bq[q0 + 3];
          for (var ky = 0; ky < k; ky++) {
            final iy = oy * stride - pad + ky;
            if (iy < 0 || iy >= ih) continue;
            for (var kx = 0; kx < k; kx++) {
              final ix = ox * stride - pad + kx;
              if (ix < 0 || ix >= iw) continue;
              final at = (iy * iw + ix) * inC;
              var wAt = (ky * k + kx) * inC * o4 + q0;
              for (var c = 0; c < inC; c++) {
                final v = Float32x4.splat(src[at + c]);
                a0 += v * wq[wAt];
                a1 += v * wq[wAt + 1];
                a2 += v * wq[wAt + 2];
                a3 += v * wq[wAt + 3];
                wAt += o4;
              }
            }
          }
          final o = (oy * ow + ox) * o4 + q0;
          dq[o] = a0;
          dq[o + 1] = a1;
          dq[o + 2] = a2;
          dq[o + 3] = a3;
        }
      }
    }
    return out;
  }
  final acc = Float32x4List(o4);
  for (var oy = 0; oy < oh; oy++) {
    for (var ox = 0; ox < ow; ox++) {
      for (var q = 0; q < o4; q++) {
        acc[q] = bq[q];
      }
      for (var ky = 0; ky < k; ky++) {
        final iy = oy * stride - pad + ky;
        if (iy < 0 || iy >= ih) continue;
        for (var kx = 0; kx < k; kx++) {
          final ix = ox * stride - pad + kx;
          if (ix < 0 || ix >= iw) continue;
          final at = (iy * iw + ix) * inC;
          var wAt = (ky * k + kx) * inC * o4;
          for (var c = 0; c < inC; c++) {
            final v = Float32x4.splat(src[at + c]);
            for (var q = 0; q < o4; q++) {
              acc[q] += v * wq[wAt + q];
            }
            wAt += o4;
          }
        }
      }
      final o = (oy * ow + ox) * o4;
      for (var q = 0; q < o4; q++) {
        dq[o + q] = acc[q];
      }
    }
  }
  return out;
}

/// A grouped 3 x 3 convolution, stride 1, where each group has one input
/// channel (weights (out, 1, k, k)).
FeatureMap depthwiseConv2d(FeatureMap x, Tensor weight, Tensor bias, {required int pad, required int groups}) {
  final outC = weight.shape[0], k = weight.shape[2], inC = x.channels, perGroup = outC ~/ groups;
  assert(inC == groups && weight.shape[1] == 1);
  final oh = x.height + 2 * pad - k + 1, ow = x.width + 2 * pad - k + 1;
  final out = FeatureMap(oh, ow, outC);
  final w = weight.data, src = x.data, dst = out.data;
  if (outC % 4 == 0 && (perGroup == 1 || perGroup % 4 == 0)) {
    // Four output channels at a time: their inputs are either four
    // neighbouring channels (one each) or one channel shared by all four.
    final o4 = outC ~/ 4;
    final wq = Float32x4List(k * k * o4);
    for (var t = 0; t < k * k; t++) {
      for (var q = 0; q < o4; q++) {
        wq[t * o4 + q] = Float32x4(w[(4 * q) * k * k + t], w[(4 * q + 1) * k * k + t], w[(4 * q + 2) * k * k + t], w[(4 * q + 3) * k * k + t]);
      }
    }
    final bq = Float32x4List.view(Float32List.fromList(bias.data).buffer);
    final dq = Float32x4List.view(dst.buffer);
    final sq = perGroup == 1 ? Float32x4List.view(src.buffer, src.offsetInBytes, src.length ~/ 4) : null;
    final acc = Float32x4List(o4);
    for (var oy = 0; oy < oh; oy++) {
      for (var ox = 0; ox < ow; ox++) {
        for (var q = 0; q < o4; q++) {
          acc[q] = bq[q];
        }
        for (var ky = 0; ky < k; ky++) {
          final iy = oy - pad + ky;
          if (iy < 0 || iy >= x.height) continue;
          for (var kx = 0; kx < k; kx++) {
            final ix = ox - pad + kx;
            if (ix < 0 || ix >= x.width) continue;
            final at = (iy * x.width + ix) * inC, tap = (ky * k + kx) * o4;
            if (sq != null) {
              final at4 = at ~/ 4;
              for (var q = 0; q < o4; q++) {
                acc[q] += sq[at4 + q] * wq[tap + q];
              }
            } else {
              for (var q = 0; q < o4; q++) {
                acc[q] += Float32x4.splat(src[at + 4 * q ~/ perGroup]) * wq[tap + q];
              }
            }
          }
        }
        final o = (oy * ow + ox) * o4;
        for (var q = 0; q < o4; q++) {
          dq[o + q] = acc[q];
        }
      }
    }
    return out;
  }
  for (var oy = 0; oy < oh; oy++) {
    for (var ox = 0; ox < ow; ox++) {
      final o = (oy * ow + ox) * outC;
      for (var ch = 0; ch < outC; ch++) {
        dst[o + ch] = bias.data[ch];
      }
      for (var ky = 0; ky < k; ky++) {
        final iy = oy - pad + ky;
        if (iy < 0 || iy >= x.height) continue;
        for (var kx = 0; kx < k; kx++) {
          final ix = ox - pad + kx;
          if (ix < 0 || ix >= x.width) continue;
          final at = (iy * x.width + ix) * inC;
          for (var ch = 0; ch < outC; ch++) {
            dst[o + ch] += src[at + ch ~/ perGroup] * w[(ch * k + ky) * k + kx];
          }
        }
      }
    }
  }
  return out;
}

/// A transposed convolution, stride 2, weights (in, out, k, k): twice the
/// size, as in torch.nn.ConvTranspose2d.
FeatureMap convTranspose2d(FeatureMap x, Tensor weight, Tensor bias, {required int pad}) {
  final inC = weight.shape[0], outC = weight.shape[1], k = weight.shape[2];
  assert(inC == x.channels);
  final oh = (x.height - 1) * 2 - 2 * pad + k, ow = (x.width - 1) * 2 - 2 * pad + k;
  final out = FeatureMap(oh, ow, outC);
  final w = weight.data, src = x.data, dst = out.data;
  for (var i = 0; i < oh * ow; i++) {
    for (var o = 0; o < outC; o++) {
      dst[i * outC + o] = bias.data[o];
    }
  }
  for (var iy = 0; iy < x.height; iy++) {
    for (var ix = 0; ix < x.width; ix++) {
      final at = (iy * x.width + ix) * inC;
      for (var ky = 0; ky < k; ky++) {
        final oy = 2 * iy - pad + ky;
        if (oy < 0 || oy >= oh) continue;
        for (var kx = 0; kx < k; kx++) {
          final ox = 2 * ix - pad + kx;
          if (ox < 0 || ox >= ow) continue;
          final o = (oy * ow + ox) * outC;
          for (var c = 0; c < inC; c++) {
            final v = src[at + c];
            for (var oc = 0; oc < outC; oc++) {
              dst[o + oc] += v * w[((c * outC + oc) * k + ky) * k + kx];
            }
          }
        }
      }
    }
  }
  return out;
}
