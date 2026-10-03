import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/thumbhash.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/utils/gallery_filters.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:image/image.dart' as img;

typedef GalleryImageProviderBuilder =
    ImageProvider Function(String url, {int? cacheWidth});

ImageProvider cdnGalleryImageProvider(String url, {int? cacheWidth}) =>
    ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      CachedNetworkImageProvider(url),
    );

class GalleryImageScope extends InheritedWidget {
  final GalleryImageProviderBuilder builder;

  const GalleryImageScope({
    super.key,
    required this.builder,
    required super.child,
  });

  static GalleryImageProviderBuilder of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<GalleryImageScope>()
          ?.builder ??
      cdnGalleryImageProvider;

  @override
  bool updateShouldNotify(GalleryImageScope oldWidget) =>
      builder != oldWidget.builder;
}

String galleryHeroTag(GalleryPhotoDto photo) => 'venue-gallery-${photo.id}';

class GalleryPlaceholder {
  final ImageProvider image;
  final Color average;
  const GalleryPlaceholder(this.image, this.average);
}

final LinkedHashMap<String, GalleryPlaceholder?> _placeholders =
    LinkedHashMap();
const int _placeholderCacheSize = 96;

GalleryPlaceholder? galleryPlaceholder(String? hash) {
  if (hash == null || hash.isEmpty) return null;
  if (_placeholders.containsKey(hash)) {
    final hit = _placeholders.remove(hash);
    _placeholders[hash] = hit;
    return hit;
  }
  final decoded = _decodePlaceholder(hash);
  _placeholders[hash] = decoded;
  if (_placeholders.length > _placeholderCacheSize) {
    _placeholders.remove(_placeholders.keys.first);
  }
  return decoded;
}

GalleryPlaceholder? _decodePlaceholder(String hash) {
  try {
    final padded = hash.padRight((hash.length + 3) ~/ 4 * 4, '=');
    final bytes = base64Decode(padded);
    final avg = thumbHashToAverageRGBA(bytes);
    final decoded = thumbHashToRGBA(bytes);
    final png = img.encodePng(
      img.Image.fromBytes(
        width: decoded.width,
        height: decoded.height,
        bytes: decoded.rgba.buffer,
        numChannels: 4,
      ),
    );
    return GalleryPlaceholder(
      MemoryImage(Uint8List.fromList(png)),
      Color.fromARGB(
        255,
        (avg.r * 255).round(),
        (avg.g * 255).round(),
        (avg.b * 255).round(),
      ),
    );
  } catch (_) {
    return null;
  }
}

int? galleryCoverDecodeWidth(GalleryPhotoDto photo, Size box, double dpr) {
  if (!box.width.isFinite || box.width <= 0) return null;
  final coverHeight = box.height.isFinite && box.height > 0
      ? box.height * layoutRatio(photo)
      : 0.0;
  final px = (math.max(box.width, coverHeight) * dpr).ceil();
  return photo.width > 0 ? math.min(photo.width, px) : px;
}

String galleryPhotoSemanticLabel(
  GalleryPhotoDto photo, {
  required int index,
  required int total,
}) {
  final position = LocaleKeys.venue_gallery_viewer_counter.tr(
    namedArgs: {'index': '${index + 1}', 'total': '$total'},
  );
  final tags = knownTags(photo.tags).map(galleryTagLabel).join('، ');
  return tags.isEmpty ? position : '$tags · $position';
}

class GalleryPhotoImage extends StatelessWidget {
  final GalleryPhotoDto photo;

  final int? cacheWidth;

  const GalleryPhotoImage({super.key, required this.photo, this.cacheWidth});

  @override
  Widget build(BuildContext context) {
    final placeholder = galleryPlaceholder(photo.placeholderHash);
    final provider = GalleryImageScope.of(context)(
      photo.url,
      cacheWidth: cacheWidth,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: placeholder?.average ?? context.c.surfaceMuted),
        if (placeholder != null)
          Image(
            image: placeholder.image,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        Image(
          image: provider,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: child,
            );
          },
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class GalleryPhotoTile extends StatelessWidget {
  final GalleryPhotoDto photo;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  final bool hero;

  final Widget? overlay;

  final String? semanticLabel;

  const GalleryPhotoTile({
    super.key,
    required this.photo,
    this.borderRadius = BorderRadius.zero,
    this.onTap,
    this.hero = false,
    this.overlay,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel;
    final overlay = this.overlay;
    Widget tile = LayoutBuilder(
      builder: (context, constraints) {
        final width = galleryCoverDecodeWidth(
          photo,
          constraints.biggest,
          MediaQuery.devicePixelRatioOf(context),
        );
        Widget image = GalleryPhotoImage(photo: photo, cacheWidth: width);
        if (hero) image = Hero(tag: galleryHeroTag(photo), child: image);
        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (overlay != null)
                label == null ? overlay : ExcludeSemantics(child: overlay),
              if (onTap != null)
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
            ],
          ),
        );
      },
    );
    if (label != null) {
      tile = Semantics(
        container: true,
        button: onTap != null,
        image: onTap == null,
        label: label,
        child: tile,
      );
    }
    return tile;
  }
}
