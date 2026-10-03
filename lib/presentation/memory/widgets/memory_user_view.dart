import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_viewer/memory_viewer_bloc.dart';
import 'package:hangout/presentation/memory/widgets/engagement/memory_engagement_widget.dart';
import 'package:hangout/presentation/memory/widgets/memory_header.dart';
import 'package:hangout/presentation/memory/widgets/memory_options_sheet.dart';
import 'package:hangout/presentation/memory/widgets/memory_reply_bar.dart';
import 'package:hangout/presentation/memory/widgets/memory_tap_zones.dart';
import 'package:hangout/presentation/memory/widgets/mention_overlay_layer.dart';
import 'package:video_player/video_player.dart';

class MemoryUserView extends StatelessWidget {
  final MemoryTrayBucket bucket;
  final bool isActiveBucket;
  final VoidCallback onClose;
  final Animation<double>? activeAnimation;
  final VideoPlayerController? activeVideoController;

  const MemoryUserView({
    super.key,
    required this.bucket,
    required this.isActiveBucket,
    required this.onClose,
    this.activeAnimation,
    this.activeVideoController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MemoryViewerBloc, MemoryViewerState>(
      buildWhen: (prev, curr) =>
          isActiveBucket &&
          (prev.memoryIndex != curr.memoryIndex ||
              prev.isPaused != curr.isPaused ||
              prev.buckets != curr.buckets),
      builder: (context, state) {
        final memoryIndex = isActiveBucket ? state.memoryIndex : 0;
        final safeIndex = memoryIndex.clamp(0, bucket.memories.length - 1);
        final memory = bucket.memories[safeIndex];

        return Stack(
          fit: StackFit.expand,
          children: [
            _MemoryContent(
              memory: memory,
              videoController: isActiveBucket ? activeVideoController : null,
            ),
            const _GradientOverlay(begin: Alignment.topCenter),
            const _GradientOverlay(begin: Alignment.bottomCenter),

            MemoryTapZones(
              onTapLeft: () =>
                  context.read<MemoryViewerBloc>().add(PreviousMemory()),
              onTapRight: () =>
                  context.read<MemoryViewerBloc>().add(NextMemory()),
              onLongPressStart: () => context
                  .read<MemoryViewerBloc>()
                  .add(PausedToggled(paused: true)),
              onLongPressEnd: () => context
                  .read<MemoryViewerBloc>()
                  .add(PausedToggled(paused: false)),
            ),

            MentionOverlayLayer(mentions: memory.mentions),

            if (memory.engagement != null)
              MemoryEngagementWidget(
                key: ValueKey('engagement-${memory.id}'),
                memory: memory,
              ),

            MemoryHeader(
              owner: bucket.owner,
              memoryCount: bucket.memories.length,
              currentIndex: safeIndex,
              isPaused: isActiveBucket && state.isPaused,
              createdAt: memory.createdAt,
              onClose: onClose,
              onMore: () =>
                  showMemoryOptionsSheet(context, memory: memory),
              animation: isActiveBucket ? activeAnimation : null,
            ),

            if (!memory.mine)
              MemoryReplyBar(
                key: ValueKey('reply-${memory.id}'),
                memory: memory,
                owner: bucket.owner,
              ),
          ],
        );
      },
    );
  }
}

class _MemoryContent extends StatelessWidget {
  final MemoryResponse memory;
  final VideoPlayerController? videoController;

  const _MemoryContent({required this.memory, this.videoController});

  @override
  Widget build(BuildContext context) {
    switch (memory.contentType) {
      case MemoryContentType.photo:
        final url = memory.mediaUrl ?? memory.mediaThumbnailUrl;
        if (url == null || url.isEmpty) {
          return const _PlaceholderContent(
            icon: TablerIcons.photo,
            label: 'لا توجد صورة',
          );
        }
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, _) =>
              ColoredBox(color: context.c.mediaSurface),
          errorWidget: (_, _, _) => const _PlaceholderContent(
            icon: TablerIcons.alert_triangle,
            label: 'تعذر تحميل الصورة',
          ),
        );
      case MemoryContentType.video:
        return _VideoContent(
          memory: memory,
          controller: videoController,
        );
      case MemoryContentType.text:
        return _TextCardContent(memory: memory);
    }
  }
}

class _VideoContent extends StatelessWidget {
  final MemoryResponse memory;
  final VideoPlayerController? controller;
  const _VideoContent({required this.memory, this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    final isReady = controller != null && controller!.value.isInitialized;
    if (!isReady) {
      final poster = memory.mediaThumbnailUrl;
      if (poster != null && poster.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: poster,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, _) => ColoredBox(color: t.mediaSurface),
          errorWidget: (_, _, _) => ColoredBox(color: t.mediaSurface),
        );
      }
      return ColoredBox(color: t.mediaSurface);
    }
    final c = controller!;
    return Center(
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: VideoPlayer(c),
      ),
    );
  }
}

class _TextCardContent extends StatelessWidget {
  final MemoryResponse memory;
  const _TextCardContent({required this.memory});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bg = _parseHex(memory.backgroundColor, c.mediaSurface);
    final fg = _parseHex(memory.textColor, c.onMediaSurface);
    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 96),
          child: Center(
            child: Text(
              memory.textContent ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _parseHex(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(cleaned.length == 6 ? (0xFF000000 | value) : value);
}

class _PlaceholderContent extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderContent({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.mediaSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: c.onMediaSurface.withValues(alpha: 0.24),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: c.onMediaSurface.withValues(alpha: 0.54),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  final AlignmentGeometry begin;
  const _GradientOverlay({required this.begin});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: Alignment.center,
            colors: [
              context.c.scrimSubtle,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
