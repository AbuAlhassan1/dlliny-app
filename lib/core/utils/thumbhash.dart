import 'dart:math' as math;
import 'dart:typed_data';

class ThumbHashImage {
  final int width;
  final int height;
  final Uint8List rgba;

  const ThumbHashImage(this.width, this.height, this.rgba);
}

Uint8List rgbaToThumbHash(int w, int h, Uint8List rgba) {
  if (w > 100 || h > 100) {
    throw ArgumentError("${w}x$h doesn't fit in 100x100");
  }
  if (w < 1 || h < 1 || rgba.length < w * h * 4) {
    throw ArgumentError('invalid ${w}x$h RGBA buffer');
  }

  var avgR = 0.0, avgG = 0.0, avgB = 0.0, avgA = 0.0;
  for (var i = 0, j = 0; i < w * h; i++, j += 4) {
    final alpha = rgba[j + 3] / 255;
    avgR += alpha / 255 * rgba[j];
    avgG += alpha / 255 * rgba[j + 1];
    avgB += alpha / 255 * rgba[j + 2];
    avgA += alpha;
  }
  if (avgA > 0) {
    avgR /= avgA;
    avgG /= avgA;
    avgB /= avgA;
  }

  final hasAlpha = avgA < w * h;
  final lLimit = hasAlpha ? 5 : 7;
  final lx = math.max(1, (lLimit * w / math.max(w, h)).round());
  final ly = math.max(1, (lLimit * h / math.max(w, h)).round());
  final l = List<double>.filled(w * h, 0);
  final p = List<double>.filled(w * h, 0);
  final q = List<double>.filled(w * h, 0);
  final a = List<double>.filled(w * h, 0);

  for (var i = 0, j = 0; i < w * h; i++, j += 4) {
    final alpha = rgba[j + 3] / 255;
    final r = avgR * (1 - alpha) + alpha / 255 * rgba[j];
    final g = avgG * (1 - alpha) + alpha / 255 * rgba[j + 1];
    final b = avgB * (1 - alpha) + alpha / 255 * rgba[j + 2];
    l[i] = (r + g + b) / 3;
    p[i] = (r + g) / 2 - b;
    q[i] = r - g;
    a[i] = alpha;
  }

  ({double dc, List<double> ac, double scale}) encodeChannel(
    List<double> channel,
    int nx,
    int ny,
  ) {
    var dc = 0.0, scale = 0.0;
    final ac = <double>[];
    final fx = List<double>.filled(w, 0);
    for (var cy = 0; cy < ny; cy++) {
      for (var cx = 0; cx * ny < nx * (ny - cy); cx++) {
        var f = 0.0;
        for (var x = 0; x < w; x++) {
          fx[x] = math.cos(math.pi / w * cx * (x + 0.5));
        }
        for (var y = 0; y < h; y++) {
          final fy = math.cos(math.pi / h * cy * (y + 0.5));
          for (var x = 0; x < w; x++) {
            f += channel[x + y * w] * fx[x] * fy;
          }
        }
        f /= w * h;
        if (cx > 0 || cy > 0) {
          ac.add(f);
          scale = math.max(scale, f.abs());
        } else {
          dc = f;
        }
      }
    }
    if (scale > 0) {
      for (var i = 0; i < ac.length; i++) {
        ac[i] = 0.5 + 0.5 / scale * ac[i];
      }
    }
    return (dc: dc, ac: ac, scale: scale);
  }

  final lc = encodeChannel(l, math.max(3, lx), math.max(3, ly));
  final pc = encodeChannel(p, 3, 3);
  final qc = encodeChannel(q, 3, 3);
  final ac = hasAlpha ? encodeChannel(a, 5, 5) : null;

  final isLandscape = w > h;
  final header24 =
      (63 * lc.dc).round() |
      ((31.5 + 31.5 * pc.dc).round() << 6) |
      ((31.5 + 31.5 * qc.dc).round() << 12) |
      ((31 * lc.scale).round() << 18) |
      ((hasAlpha ? 1 : 0) << 23);
  final header16 =
      (isLandscape ? ly : lx) |
      ((63 * pc.scale).round() << 3) |
      ((63 * qc.scale).round() << 9) |
      ((isLandscape ? 1 : 0) << 15);
  final acStart = hasAlpha ? 6 : 5;
  final channels = [lc.ac, pc.ac, qc.ac, if (ac != null) ac.ac];
  final acCount = channels.fold<int>(0, (n, c) => n + c.length);
  final hash = Uint8List(acStart + (acCount + 1) ~/ 2);
  hash[0] = header24 & 255;
  hash[1] = (header24 >> 8) & 255;
  hash[2] = header24 >> 16;
  hash[3] = header16 & 255;
  hash[4] = header16 >> 8;
  if (ac != null) {
    hash[5] = (15 * ac.dc).round() | ((15 * ac.scale).round() << 4);
  }

  var acIndex = 0;
  for (final channel in channels) {
    for (final f in channel) {
      hash[acStart + (acIndex >> 1)] |=
          (15 * f).round() << ((acIndex & 1) << 2);
      acIndex++;
    }
  }
  return hash;
}

ThumbHashImage thumbHashToRGBA(Uint8List hash) {
  final header24 = hash[0] | (hash[1] << 8) | (hash[2] << 16);
  final header16 = hash[3] | (hash[4] << 8);
  final lDc = (header24 & 63) / 63;
  final pDc = ((header24 >> 6) & 63) / 31.5 - 1;
  final qDc = ((header24 >> 12) & 63) / 31.5 - 1;
  final lScale = ((header24 >> 18) & 31) / 31;
  final hasAlpha = (header24 >> 23) != 0;
  final pScale = ((header16 >> 3) & 63) / 63;
  final qScale = ((header16 >> 9) & 63) / 63;
  final isLandscape = (header16 >> 15) != 0;
  final lx = math.max(3, isLandscape ? (hasAlpha ? 5 : 7) : header16 & 7);
  final ly = math.max(3, isLandscape ? header16 & 7 : (hasAlpha ? 5 : 7));
  final aDc = hasAlpha ? (hash[5] & 15) / 15 : 1.0;
  final aScale = hasAlpha ? (hash[5] >> 4) / 15 : 0.0;

  final acStart = hasAlpha ? 6 : 5;
  var acIndex = 0;
  List<double> decodeChannel(int nx, int ny, double scale) {
    final ac = <double>[];
    for (var cy = 0; cy < ny; cy++) {
      for (var cx = cy > 0 ? 0 : 1; cx * ny < nx * (ny - cy); cx++) {
        final nibble =
            (hash[acStart + (acIndex >> 1)] >> ((acIndex & 1) << 2)) & 15;
        acIndex++;
        ac.add((nibble / 7.5 - 1) * scale);
      }
    }
    return ac;
  }

  final lAc = decodeChannel(lx, ly, lScale);
  final pAc = decodeChannel(3, 3, pScale * 1.25);
  final qAc = decodeChannel(3, 3, qScale * 1.25);
  final aAc = hasAlpha ? decodeChannel(5, 5, aScale) : const <double>[];

  final ratio = thumbHashToApproximateAspectRatio(hash);
  if (!ratio.isFinite || ratio <= 0) {
    throw const FormatException('ThumbHash: invalid dimensions');
  }
  final w = math.max(1, (ratio > 1 ? 32 : 32 * ratio).round());
  final h = math.max(1, (ratio > 1 ? 32 / ratio : 32).round());
  final rgba = Uint8List(w * h * 4);
  final fx = List<double>.filled(math.max(lx, hasAlpha ? 5 : 3), 0);
  final fy = List<double>.filled(math.max(ly, hasAlpha ? 5 : 3), 0);
  for (var y = 0, i = 0; y < h; y++) {
    for (var x = 0; x < w; x++, i += 4) {
      var l = lDc, p = pDc, q = qDc, a = aDc;

      for (var cx = 0; cx < fx.length; cx++) {
        fx[cx] = math.cos(math.pi / w * (x + 0.5) * cx);
      }
      for (var cy = 0; cy < fy.length; cy++) {
        fy[cy] = math.cos(math.pi / h * (y + 0.5) * cy);
      }

      for (var cy = 0, j = 0; cy < ly; cy++) {
        final fy2 = fy[cy] * 2;
        for (var cx = cy > 0 ? 0 : 1; cx * ly < lx * (ly - cy); cx++, j++) {
          l += lAc[j] * fx[cx] * fy2;
        }
      }

      for (var cy = 0, j = 0; cy < 3; cy++) {
        final fy2 = fy[cy] * 2;
        for (var cx = cy > 0 ? 0 : 1; cx < 3 - cy; cx++, j++) {
          final f = fx[cx] * fy2;
          p += pAc[j] * f;
          q += qAc[j] * f;
        }
      }

      if (hasAlpha) {
        for (var cy = 0, j = 0; cy < 5; cy++) {
          final fy2 = fy[cy] * 2;
          for (var cx = cy > 0 ? 0 : 1; cx < 5 - cy; cx++, j++) {
            a += aAc[j] * fx[cx] * fy2;
          }
        }
      }

      final b = l - 2 / 3 * p;
      final r = (3 * l - b + q) / 2;
      final g = r - q;
      rgba[i] = _channel(r);
      rgba[i + 1] = _channel(g);
      rgba[i + 2] = _channel(b);
      rgba[i + 3] = _channel(a);
    }
  }
  return ThumbHashImage(w, h, rgba);
}

({double r, double g, double b, double a}) thumbHashToAverageRGBA(
  Uint8List hash,
) {
  final header = hash[0] | (hash[1] << 8) | (hash[2] << 16);
  final l = (header & 63) / 63;
  final p = ((header >> 6) & 63) / 31.5 - 1;
  final q = ((header >> 12) & 63) / 31.5 - 1;
  final hasAlpha = (header >> 23) != 0;
  final a = hasAlpha ? (hash[5] & 15) / 15 : 1.0;
  final b = l - 2 / 3 * p;
  final r = (3 * l - b + q) / 2;
  final g = r - q;
  return (
    r: r.clamp(0.0, 1.0),
    g: g.clamp(0.0, 1.0),
    b: b.clamp(0.0, 1.0),
    a: a,
  );
}

double thumbHashToApproximateAspectRatio(Uint8List hash) {
  final header = hash[3];
  final hasAlpha = (hash[2] & 0x80) != 0;
  final isLandscape = (hash[4] & 0x80) != 0;
  final lx = isLandscape ? (hasAlpha ? 5 : 7) : header & 7;
  final ly = isLandscape ? header & 7 : (hasAlpha ? 5 : 7);
  return lx / ly;
}

int _channel(double v) => (255 * math.min(1.0, v)).clamp(0.0, 255.0).toInt();
