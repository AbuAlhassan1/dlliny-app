import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_helpers.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:video_player/video_player.dart';

class ReelActionsChip extends StatelessWidget {
  final bool liked;
  final int likesCount;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final ReelFormatter format;

  final VideoPlayerController? controller;

  const ReelActionsChip({
    super.key,
    required this.liked,
    required this.likesCount,
    required this.commentsCount,
    required this.onLike,
    required this.onComment,
    required this.format,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasVideo = controller != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: c.onMediaSurface.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChipAction(
                icon: liked ? TablerIcons.heart_filled : TablerIcons.heart,
                label: format.compact(likesCount),
                color: liked ? c.danger : c.onMediaSurface,
                onTap: onLike,
              ),
              const SizedBox(width: 16),
              _ChipAction(
                icon: TablerIcons.message,
                label: format.compact(commentsCount),
                color: c.onMediaSurface,
                onTap: onComment,
              ),
              if (hasVideo) ...[
                const SizedBox(width: 16),
                BlocBuilder<VideoBloc, VideoBlocState>(
                  builder: (context, state) {
                    final ctrl = controller!;
                    final ready = ctrl.value.isInitialized;
                    final muted = state.isMuted;
                    return _ChipAction(
                      icon: muted ? TablerIcons.volume_off : TablerIcons.volume,
                      label: null,
                      color: ready
                          ? c.onMediaSurface
                          : c.onMediaSurface.withValues(alpha: 0.4),
                      onTap: ready
                          ? () => context.read<VideoBloc>().add(
                              VideoToggleSoundEvent(controller: ctrl),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipAction extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color color;
  final VoidCallback? onTap;

  const _ChipAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: TextStyle(
                color: c.onMediaSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
