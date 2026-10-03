import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/venue/utils/cover_palette.dart';

class VenueCoverBackdrop extends StatefulWidget {
  final String? coverUrl;
  final String? coverMediaType;
  final String? coverThumbnailUrl;

  const VenueCoverBackdrop({
    super.key,
    required this.coverUrl,
    required this.coverMediaType,
    required this.coverThumbnailUrl,
  });

  @override
  State<VenueCoverBackdrop> createState() => _VenueCoverBackdropState();
}

class _VenueCoverBackdropState extends State<VenueCoverBackdrop> {
  List<Color>? _palette;

  bool get _isVideo => widget.coverMediaType == 'video';

  String? get _posterUrl {
    final url = _isVideo ? widget.coverThumbnailUrl : widget.coverUrl;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  @override
  void initState() {
    super.initState();
    _resolvePalette();
  }

  @override
  void didUpdateWidget(VenueCoverBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.coverMediaType != widget.coverMediaType ||
        oldWidget.coverThumbnailUrl != widget.coverThumbnailUrl) {
      _resolvePalette();
    }
  }

  void _resolvePalette() {
    final poster = _posterUrl;
    if (poster == null) {
      _palette = const [];
      return;
    }
    _palette = cachedCoverPalette(poster);
    if (_palette != null) return;

    loadCoverPalette(poster).then((colors) {
      if (!mounted || _posterUrl != poster) return;
      setState(() => _palette = colors);
    });
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.c.mediaSurface;
    final colors = switch (_palette) {
      null => null,
      final palette when palette.isEmpty || isMutedPalette(palette) =>
        _fallbackPalette(context.c.accent),
      final palette => palette,
    };

    return Stack(
      fit: StackFit.passthrough,
      children: [
        ColoredBox(color: surface),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            children: [...previous, ?current],
          ),
          child: colors == null
              ? const SizedBox.expand(key: ValueKey('loading'))
              : _BlurredGradient(
                  key: ValueKey(Object.hashAll(colors)),
                  colors: colors,
                ),
        ),
        ColoredBox(color: surface.withValues(alpha: 0.2)),
      ],
    );
  }
}

List<Color> _fallbackPalette(Color accent) {
  final hsl = HSLColor.fromColor(accent).withSaturation(1);
  return [
    hsl.withHue((hsl.hue + 90) % 360).withLightness(0.5).toColor(),
    hsl.withLightness(0.45).toColor(),
    hsl.withHue((hsl.hue + 50) % 360).withLightness(0.5).toColor(),
  ];
}

class _BlurredGradient extends StatelessWidget {
  final List<Color> colors;

  const _BlurredGradient({super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: RepaintBoundary(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: 40,
            sigmaY: 40,
            tileMode: TileMode.clamp,
          ),
          child: CustomPaint(
            painter: _GradientBlobsPainter(colors),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _GradientBlobsPainter extends CustomPainter {
  final List<Color> colors;

  _GradientBlobsPainter(this.colors);

  static const _anchors = [
    Alignment(-0.85, -0.75),
    Alignment(0.9, -0.15),
    Alignment(-0.35, 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.first, colors.last],
        ).createShader(rect),
    );

    final radius = size.longestSide * 0.55;
    for (var i = 0; i < colors.length; i++) {
      final center = _anchors[i % _anchors.length].alongSize(size);
      final bounds = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [colors[i], colors[i].withValues(alpha: 0)],
          ).createShader(bounds),
      );
    }
  }

  @override
  bool shouldRepaint(_GradientBlobsPainter oldDelegate) =>
      !listEquals(oldDelegate.colors, colors);
}
