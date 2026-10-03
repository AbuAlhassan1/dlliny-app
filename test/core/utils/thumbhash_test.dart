import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/utils/thumbhash.dart';

Uint8List _twoColour(int w, int h, List<int> left, List<int> right) {
  final rgba = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = x < w ~/ 2 ? left : right;
      final i = (y * w + x) * 4;
      rgba
        ..[i] = c[0]
        ..[i + 1] = c[1]
        ..[i + 2] = c[2]
        ..[i + 3] = 255;
    }
  }
  return rgba;
}

List<double> _meanRgb(ThumbHashImage image) {
  var r = 0.0, g = 0.0, b = 0.0;
  final n = image.width * image.height;
  for (var i = 0; i < n; i++) {
    r += image.rgba[i * 4];
    g += image.rgba[i * 4 + 1];
    b += image.rgba[i * 4 + 2];
  }
  return [r / n, g / n, b / n];
}

void main() {
  group('rgbaToThumbHash → thumbHashToRGBA', () {
    test('a 2-colour image round-trips to its mean colour', () {
      final hash = rgbaToThumbHash(
        100,
        75,
        _twoColour(100, 75, [220, 40, 40], [40, 40, 220]),
      );
      final decoded = thumbHashToRGBA(hash);
      expect(decoded.width, 32);
      expect(decoded.height, 23);

      final mean = _meanRgb(decoded);
      expect(mean[0], closeTo(130, 20));
      expect(mean[1], closeTo(40, 20));
      expect(mean[2], closeTo(130, 20));

      final left = decoded.rgba.sublist(12 * 32 * 4, 12 * 32 * 4 + 4);
      final right = decoded.rgba.sublist(
        (12 * 32 + 31) * 4,
        (12 * 32 + 32) * 4,
      );
      expect(left[0], greaterThan(left[2]));
      expect(right[2], greaterThan(right[0]));

      final avg = thumbHashToAverageRGBA(hash);
      expect(avg.r * 255, closeTo(130, 20));
      expect(avg.b * 255, closeTo(130, 20));
      expect(avg.a, 1);
    });

    test('keeps the approximate aspect ratio', () {
      final portrait = rgbaToThumbHash(
        75,
        100,
        _twoColour(75, 100, [10, 200, 10], [200, 200, 10]),
      );
      expect(thumbHashToApproximateAspectRatio(portrait), closeTo(0.75, 0.05));
      final decoded = thumbHashToRGBA(portrait);
      expect(decoded.width, 23);
      expect(decoded.height, 32);
    });

    test('an image with transparency sets the alpha channel', () {
      final rgba = _twoColour(40, 40, [255, 255, 255], [0, 0, 0]);
      for (var i = 3; i < rgba.length; i += 8) {
        rgba[i] = 0;
      }
      final decoded = thumbHashToRGBA(rgbaToThumbHash(40, 40, rgba));
      final alphas = [
        for (var i = 3; i < decoded.rgba.length; i += 4) decoded.rgba[i],
      ];
      expect(alphas.any((a) => a < 255), isTrue);
    });

    test('rejects a source larger than 100×100 (the reference rule)', () {
      expect(
        () => rgbaToThumbHash(100, 133, Uint8List(100 * 133 * 4)),
        throwsArgumentError,
      );
    });
  });

  test('decodes the backend fixture hash', () {
    final bytes = base64Decode('3OcRJYB4d3h/iIeHeEh3eIhw+j2w');
    final decoded = thumbHashToRGBA(bytes);
    expect(decoded.width, greaterThan(0));
    expect(decoded.height, greaterThan(0));
    expect(decoded.rgba.length, decoded.width * decoded.height * 4);
  });

  test('a truncated hash throws instead of rendering garbage', () {
    expect(
      () => thumbHashToRGBA(Uint8List.fromList([1, 2, 3])),
      throwsA(anything),
    );
  });
}
