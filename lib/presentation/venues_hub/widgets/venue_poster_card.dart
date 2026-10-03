import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:video_player/video_player.dart';

class VenuePosterCard extends StatelessWidget {
  final String venueId;
  final String nameAr;
  final String? nameEn;

  final String? coverUrl;

  final String? coverStreamUrl;
  final String? logoUrl;
  final double? avgRating;
  final int? totalRatings;

  final double? fixedWidth;

  static const double width = 158;
  static const double height = 196;

  const VenuePosterCard({
    super.key,
    required this.venueId,
    required this.nameAr,
    this.nameEn,
    this.coverUrl,
    this.coverStreamUrl,
    this.logoUrl,
    this.avgRating,
    this.totalRatings,
    this.fixedWidth,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = context.pickBilingual(ar: nameAr, en: nameEn ?? nameAr);
    final mq = MediaQuery.of(context);
    final w = fixedWidth ?? width;
    final h = w * (height / width);
    final memWidth = (w * mq.devicePixelRatio).round();
    final hasRating = avgRating != null && avgRating! > 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VenuePageWrapper(venueId: venueId)),
      ),
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _Cover(
                coverUrl: coverUrl,
                coverStreamUrl: coverStreamUrl,
                logoUrl: logoUrl,
                memWidth: memWidth,
              ),

              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xE0000000)],
                        stops: [0.42, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              if (hasRating)
                PositionedDirectional(
                  top: 8,
                  end: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          TablerIcons.star_filled,
                          color: Color(0xFFFABF00),
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          avgRating!.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              PositionedDirectional(
                start: 10,
                end: 10,
                bottom: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Logo(logoUrl: logoUrl, border: c.background),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'IBMPlexSansArabic',
                          shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatefulWidget {
  final String? coverUrl;
  final String? coverStreamUrl;
  final String? logoUrl;
  final int memWidth;
  const _Cover({
    required this.coverUrl,
    required this.coverStreamUrl,
    required this.logoUrl,
    required this.memWidth,
  });

  @override
  State<_Cover> createState() => _CoverState();
}

class _CoverState extends State<_Cover> {
  VideoPlayback? _video;
  VideoPlayerController? get _controller => _video?.controller;

  bool get _isVideo => isVideoCover(
    coverUrl: widget.coverUrl,
    coverStreamUrl: widget.coverStreamUrl,
  );

  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
  }

  @override
  void didUpdateWidget(covariant _Cover old) {
    super.didUpdateWidget(old);
    if (old.coverUrl != widget.coverUrl ||
        old.coverStreamUrl != widget.coverStreamUrl) {
      _video?.dispose();
      _video = null;
      if (_isVideo) _initVideo();
    }
  }

  void _initVideo() {
    _video = VideoSource.of(
      widget.coverUrl ?? '',
      streamUrl: widget.coverStreamUrl,
    ).load(
      onReady: (ctrl) async {
        if (!mounted) return;
        await ctrl.setLooping(true);
        await ctrl.setVolume(0);
        if (!mounted) return;
        await ctrl.play();
        if (mounted) setState(() {});
      },
      onError: (_, _) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.surfaceElevated, c.surfaceMuted],
        ),
      ),
      child: Center(
        child:
            Icon(TablerIcons.building_store, color: c.onSurfaceMuted, size: 34),
      ),
    );

    if (_isVideo) {
      final vc = _controller;
      if (vc != null && vc.value.isInitialized) {
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: vc.value.size.width,
            height: vc.value.size.height,
            child: VideoPlayer(vc),
          ),
        );
      }
      final poster =
          (widget.logoUrl != null && widget.logoUrl!.isNotEmpty)
              ? widget.logoUrl!
              : null;
      if (poster == null) return ColoredBox(color: c.surfaceMuted);
      return CachedNetworkImage(
        imageUrl: poster,
        fit: BoxFit.cover,
        memCacheWidth: widget.memWidth,
        placeholder: (_, _) => ColoredBox(color: c.surfaceMuted),
        errorWidget: (_, _, _) => placeholder,
      );
    }

    final url = (widget.coverUrl != null && widget.coverUrl!.isNotEmpty)
        ? widget.coverUrl!
        : widget.logoUrl;
    if (url == null || url.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      memCacheWidth: widget.memWidth,
      placeholder: (_, _) => ColoredBox(color: c.surfaceMuted),
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logoUrl;
  final Color border;
  const _Logo({required this.logoUrl, required this.border});

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    final url = logoUrl;
    final fallback = const Icon(
      TablerIcons.building_store,
      color: Colors.white,
      size: 16,
    );
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: (url != null && url.isNotEmpty)
          ? ClipRRect(
            borderRadius: BorderRadius.circular(size / 2),
            child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 102,
                errorWidget: (_, _, _) => Center(child: fallback),
              ),
          )
          : Center(child: fallback),
    );
  }
}
