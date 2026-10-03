import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

final LinkedHashMap<String, List<Color>> _cache = LinkedHashMap();
const int _cacheLimit = 50;

List<Color>? cachedCoverPalette(String url) => _cache[url];

Future<List<Color>> loadCoverPalette(String url) async {
  final cached = _cache.remove(url);
  if (cached != null) return _cache[url] = cached;

  try {
    final image = await _decodeTiny(url);
    if (image == null) return const [];
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) return const [];
      final colors = dominantBackdropColors(bytes.buffer.asUint8List());
      if (colors.isNotEmpty) {
        _cache[url] = colors;
        if (_cache.length > _cacheLimit) _cache.remove(_cache.keys.first);
      }
      return colors;
    } finally {
      image.dispose();
    }
  } catch (_) {
    return const [];
  }
}

Future<ui.Image?> _decodeTiny(String url) {
  final completer = Completer<ui.Image?>();
  final stream = ResizeImage(
    CachedNetworkImageProvider(url),
    width: 32,
  ).resolve(ImageConfiguration.empty);

  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(info.image.clone());
      info.dispose();
    },
    onError: (_, _) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

List<Color> dominantBackdropColors(Uint8List rgba, {int maxColors = 3}) {
  final buckets = <int, _Bucket>{};
  for (var i = 0; i + 3 < rgba.length; i += 4) {
    if (rgba[i + 3] < 128) continue;
    final r = rgba[i], g = rgba[i + 1], b = rgba[i + 2];
    final key = (r >> 4) << 8 | (g >> 4) << 4 | (b >> 4);
    (buckets[key] ??= _Bucket()).add(r, g, b);
  }
  if (buckets.isEmpty) return const [];

  final ranked = buckets.values.toList()
    ..sort((a, b) => b.score.compareTo(a.score));

  final picked = <Color>[];
  for (final bucket in ranked) {
    final color = bucket.average;
    if (picked.every((p) => _distance(p, color) > _minDistance)) {
      picked.add(color);
      if (picked.length == maxColors) break;
    }
  }

  final toned = picked.map(_tone).toList();
  if (toned.length == 1) {
    final hsl = HSLColor.fromColor(toned.first);
    toned.add(
      hsl.saturation > 0
          ? hsl.withHue((hsl.hue + 35) % 360).toColor()
          : hsl.withLightness(hsl.lightness - 0.15).toColor(),
    );
  }
  return toned;
}

bool isMutedPalette(List<Color> colors) =>
    colors.every((c) => HSLColor.fromColor(c).saturation < 0.15);

const double _greyChroma = 0.08;

double _chroma(Color c) =>
    [c.r, c.g, c.b].reduce(math.max) - [c.r, c.g, c.b].reduce(math.min);

const double _minDistance = 60;

double _distance(Color a, Color b) {
  final dr = (a.r - b.r) * 255, dg = (a.g - b.g) * 255, db = (a.b - b.b) * 255;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

Color _tone(Color color) {
  var hsl = HSLColor.fromColor(color);
  hsl = _chroma(color) < _greyChroma
      ? hsl.withSaturation(0)
      : hsl.withSaturation(math.min(1, hsl.saturation * 1.35 + 0.15));
  return hsl.withLightness(hsl.lightness.clamp(0.38, 0.62)).toColor();
}

class _Bucket {
  int count = 0;
  int _r = 0, _g = 0, _b = 0;

  void add(int r, int g, int b) {
    count++;
    _r += r;
    _g += g;
    _b += b;
  }

  Color get average =>
      Color.fromARGB(255, _r ~/ count, _g ~/ count, _b ~/ count);

  double get score => count * (0.15 + _chroma(average) * 1.5);
}
