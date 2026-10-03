import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/presentation/venue/utils/cover_palette.dart';

Uint8List _pixels(List<(int, int, int, int, int)> runs) {
  final bytes = <int>[];
  for (final (count, r, g, b, a) in runs) {
    for (var i = 0; i < count; i++) {
      bytes.addAll([r, g, b, a]);
    }
  }
  return Uint8List.fromList(bytes);
}

double _hue(Color c) => HSLColor.fromColor(c).hue;
double _lightness(Color c) => HSLColor.fromColor(c).lightness;
double _saturation(Color c) => HSLColor.fromColor(c).saturation;

void main() {
  test('returns the distinct hues of a two-tone image', () {
    final colors = dominantBackdropColors(
      _pixels([(500, 200, 30, 30, 255), (500, 30, 60, 200, 255)]),
    );

    expect(colors, hasLength(2));
    expect(colors.map(_hue), containsAll([closeTo(0, 5), closeTo(229, 5)]));
  });

  test('a small vivid accent leads over a large grey area', () {
    final colors = dominantBackdropColors(
      _pixels([
        (700, 120, 120, 120, 255),
        (650, 100, 100, 100, 255),
        (120, 240, 120, 20, 255),
      ]),
    );

    expect(colors, hasLength(2));
    expect(_hue(colors.first), closeTo(30, 8));
  });

  test('boosts saturation of muted but colored tones', () {
    const dustyTeal = Color.fromARGB(255, 90, 140, 130);
    final colors = dominantBackdropColors(_pixels([(400, 90, 140, 130, 255)]));

    expect(
      _saturation(colors.first),
      greaterThan(_saturation(dustyTeal) * 1.8),
    );
    expect(_hue(colors.first), closeTo(_hue(dustyTeal), 1));
  });

  test('single-tone colored images pair with a neighbouring hue', () {
    final colors = dominantBackdropColors(_pixels([(400, 90, 40, 160, 255)]));

    expect(colors, hasLength(2));
    expect((_hue(colors[1]) - _hue(colors[0])) % 360, closeTo(35, 1));
  });

  test('keeps colors out of the near-white and near-black extremes', () {
    final colors = dominantBackdropColors(
      _pixels([(500, 250, 250, 245, 255), (500, 5, 5, 10, 255)]),
    );

    for (final c in colors) {
      expect(_lightness(c), inInclusiveRange(0.37, 0.63));
    }
  });

  test('near-white and near-black stay neutral instead of gaining a tint', () {
    final colors = dominantBackdropColors(
      _pixels([(500, 250, 250, 245, 255), (500, 5, 5, 10, 255)]),
    );

    for (final c in colors) {
      expect(_saturation(c), 0);
    }
    expect(isMutedPalette(colors), isTrue);
  });

  test('isMutedPalette only flags palettes with no real color', () {
    expect(isMutedPalette(const [Color(0xFF777777), Color(0xFF555555)]), isTrue);
    expect(isMutedPalette(const [Color(0xFF777777), Color(0xFFCC5522)]), isFalse);
  });

  test('ignores transparent pixels and returns nothing when all are', () {
    expect(dominantBackdropColors(_pixels([(300, 255, 0, 0, 0)])), isEmpty);
    expect(dominantBackdropColors(Uint8List(0)), isEmpty);
  });

  test('never returns more than maxColors', () {
    final colors = dominantBackdropColors(
      _pixels([
        (100, 220, 20, 20, 255),
        (100, 20, 220, 20, 255),
        (100, 20, 20, 220, 255),
        (100, 220, 220, 20, 255),
      ]),
      maxColors: 3,
    );

    expect(colors, hasLength(3));
  });
}
