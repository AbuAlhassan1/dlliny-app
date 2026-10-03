import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/widgets/memory_progress_bars.dart';

class MemoryHeader extends StatelessWidget {
  final MemoryOwnerSummary owner;
  final int memoryCount;
  final int currentIndex;
  final bool isPaused;
  final String? createdAt;
  final VoidCallback onClose;
  final VoidCallback onMore;
  final Animation<double>? animation;

  const MemoryHeader({
    super.key,
    required this.owner,
    required this.memoryCount,
    required this.currentIndex,
    required this.isPaused,
    required this.createdAt,
    required this.onClose,
    required this.onMore,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              MemoryProgressBars(
                count: memoryCount,
                currentIndex: currentIndex,
                animation:
                    animation ?? const AlwaysStoppedAnimation<double>(0),
              ),
              const SizedBox(height: 10),
              _OwnerRow(
                owner: owner,
                createdAt: createdAt,
                isPaused: isPaused,
                onClose: onClose,
                onMore: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerRow extends StatelessWidget {
  final MemoryOwnerSummary owner;
  final String? createdAt;
  final bool isPaused;
  final VoidCallback onClose;
  final VoidCallback onMore;

  const _OwnerRow({
    required this.owner,
    required this.createdAt,
    required this.isPaused,
    required this.onClose,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        _OwnerAvatar(url: owner.avatarUrl),
        const SizedBox(width: 8),
        _NameAndTime(
          displayName: owner.displayName ?? '',
          createdAt: createdAt,
        ),
        if (isPaused)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              TablerIcons.player_pause,
              color: c.onMediaSurface,
              size: 20,
            ),
          ),
        IconButton(
          onPressed: onMore,
          icon: Icon(TablerIcons.dots, color: c.onMediaSurface),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          child: Icon(TablerIcons.x, color: c.onMediaSurface, size: 22),
        ),
      ],
    );
  }
}

class _OwnerAvatar extends StatelessWidget {
  final String? url;
  const _OwnerAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.c.onMediaSurface, width: 2),
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                errorWidget: (_, _, _) => const _FallbackAvatar(),
              )
            : const _FallbackAvatar(),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.onMediaSurface.withValues(alpha: 0.24),
      child: Icon(
        TablerIcons.user,
        color: c.onMediaSurface.withValues(alpha: 0.7),
        size: 18,
      ),
    );
  }
}

class _NameAndTime extends StatelessWidget {
  final String displayName;
  final String? createdAt;
  const _NameAndTime({required this.displayName, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onMediaSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            _formatRelative(createdAt),
            style: TextStyle(
              color: c.onMediaSurface.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRelative(String? iso) {
  if (iso == null) return '';
  final created = DateTime.tryParse(iso);
  if (created == null) return '';
  final delta = DateTime.now().toUtc().difference(created.toUtc());
  if (delta.inMinutes < 1) return 'الآن';
  if (delta.inMinutes < 60) return '${delta.inMinutes}د';
  return '${delta.inHours}س';
}
