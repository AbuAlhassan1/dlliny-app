import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:video_player/video_player.dart';

class ReelBlurredBackdrop extends StatelessWidget {
  final String? url;

  const ReelBlurredBackdrop({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final surface = context.c.mediaSurface;
    if (url == null || url!.isEmpty) {
      return SizedBox.expand(child: ColoredBox(color: surface));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            memCacheWidth: 200,
            placeholder: (_, _) => ColoredBox(color: surface),
            errorWidget: (_, _, _) => ColoredBox(color: surface),
          ),
        ),
        ColoredBox(color: surface.withValues(alpha: 0.35)),
      ],
    );
  }
}

class ReelMediaForeground extends StatelessWidget {
  final FeedMediaItem media;

  final VideoPlayerController? controller;

  final bool failed;

  final int memCacheWidth;

  const ReelMediaForeground({
    super.key,
    required this.media,
    required this.controller,
    required this.memCacheWidth,
    this.failed = false,
  });

  bool get _isVideo => media.type == 'video';

  double get _mediaAspect {
    final ar = media.aspectRatio;
    return (ar != null && ar.isFinite && ar > 0) ? ar : 9 / 16;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(child: _foreground(c));
  }

  Widget _foreground(AppColors c) {
    if (_isVideo) {
      final vc = controller;
      if (vc == null || !vc.value.isInitialized) {
        if (failed) {
          return Icon(
            TablerIcons.video_off,
            color: c.onMediaSurface.withValues(alpha: 0.5),
            size: 36,
          );
        }
        final spinner = SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: c.onMediaSurface,
          ),
        );
        final poster = media.thumbnailUrl;
        if (poster != null && poster.isNotEmpty) {
          return AspectRatio(
            aspectRatio: _mediaAspect,
            child: CachedNetworkImage(
              imageUrl: poster,
              fit: BoxFit.cover,
              memCacheWidth: memCacheWidth,
              placeholder: (_, _) => Center(child: spinner),
              errorWidget: (_, _, _) => Center(child: spinner),
            ),
          );
        }
        return spinner;
      }
      return AspectRatio(
        aspectRatio: vc.value.aspectRatio,
        child: VideoPlayer(vc),
      );
    }

    return AspectRatio(
      aspectRatio: _mediaAspect,
      child: CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.contain,
        memCacheWidth: memCacheWidth,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) => Center(
          child: Icon(
            TablerIcons.photo_off,
            color: c.onMediaSurface.withValues(alpha: 0.38),
            size: 36,
          ),
        ),
      ),
    );
  }
}
