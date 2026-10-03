import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:video_player/video_player.dart';

class HangoutFeedMediaCarousel extends StatelessWidget {
  final List<FeedMediaItem> media;
  final PageController controller;
  final List<VideoPlayerController?> videoControllers;
  final int memCacheWidth;
  final VoidCallback onTogglePlay;

  final Set<int> manuallyPaused;

  final void Function(int index, bool nowPaused) onUserPauseChanged;

  const HangoutFeedMediaCarousel({
    super.key,
    required this.media,
    required this.controller,
    required this.videoControllers,
    required this.memCacheWidth,
    required this.onTogglePlay,
    required this.manuallyPaused,
    required this.onUserPauseChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: c.mediaSurface)),
        PageView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          itemCount: media.length,
          itemBuilder: (context, index) {
            final item = media[index];
            if (item.type == 'video') {
              final vc = videoControllers[index];
              if (vc == null || !vc.value.isInitialized) {
                final poster = item.thumbnailUrl;
                final placeholder = ColoredBox(
                  color: c.mediaSurface,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        TablerIcons.player_play_filled,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
                if (poster == null || poster.isEmpty) return placeholder;
                return CachedNetworkImage(
                  imageUrl: poster,
                  fit: BoxFit.cover,
                  memCacheWidth: memCacheWidth,
                  placeholder: (context, url) => placeholder,
                  errorWidget: (context, url, error) => placeholder,
                );
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final wasPlaying = vc.value.isPlaying;
                  if (wasPlaying) {
                    vc.pause();
                  } else {
                    vc.play();
                  }
                  onUserPauseChanged(index, wasPlaying);
                  onTogglePlay();
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: vc.value.size.width,
                        height: vc.value.size.height,
                        child: VideoPlayer(vc),
                      ),
                    ),
                    if (manuallyPaused.contains(index))
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            TablerIcons.player_play_filled,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }
            if (item.type == 'image') {
              return CachedNetworkImage(
                imageUrl: item.url,
                fit: BoxFit.cover,
                memCacheWidth: memCacheWidth,
                placeholder: (context, url) => Shimmer(
                  duration: const Duration(milliseconds: 900),
                  color: c.onMediaSurface,
                  colorOpacity: 0.1,
                  child: ColoredBox(color: c.mediaSurface),
                ),
                errorWidget: (context, url, error) => ColoredBox(
                  color: c.mediaSurface,
                  child: Icon(Icons.error_outline, color: c.onMediaSurface),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        if (media.length > 1)
          PositionedDirectional(
            top: 12,
            end: 12,
            child: _MediaCounterChip(
              controller: controller,
              total: media.length,
            ),
          ),
      ],
    );
  }
}

class _MediaCounterChip extends StatefulWidget {
  final PageController controller;
  final int total;
  const _MediaCounterChip({required this.controller, required this.total});

  @override
  State<_MediaCounterChip> createState() => _MediaCounterChipState();
}

class _MediaCounterChipState extends State<_MediaCounterChip> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = widget.controller.page?.round() ?? 0;
    if (page != _page) setState(() => _page = page);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_page + 1}/${widget.total}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
