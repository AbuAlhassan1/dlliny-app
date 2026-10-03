import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_date_tile.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_hero_venue_chip.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_join_pill.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_media_carousel.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_join_ui_state.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_media_add_box.dart';
import 'package:video_player/video_player.dart';


class HangoutFeedHero extends StatelessWidget {
  final List<FeedMediaItem> media;
  final PageController mediaController;
  final List<VideoPlayerController?> videoControllers;
  final double aspectRatio;
  final int memCacheWidth;
  final DateTime? scheduledAt;
  final HangoutJoinUiState? joinState;
  final bool joinInFlight;
  final VoidCallback onJoin;
  final VoidCallback onTogglePlay;
  final bool isPast;
  final Set<int> manuallyPaused;
  final void Function(int index, bool nowPaused) onUserPauseChanged;

  final HangoutOrganizerVenue? venue;
  final HangoutFeedBranch? branch;
  final VoidCallback? onVenueTap;

  final VoidCallback? onAddMedia;

  const HangoutFeedHero({
    super.key,
    required this.media,
    required this.mediaController,
    required this.videoControllers,
    required this.aspectRatio,
    required this.memCacheWidth,
    required this.scheduledAt,
    required this.joinState,
    required this.joinInFlight,
    required this.onJoin,
    required this.onTogglePlay,
    required this.isPast,
    required this.manuallyPaused,
    required this.onUserPauseChanged,
    this.venue,
    this.branch,
    this.onVenueTap,
    this.onAddMedia,
  });

  @override
  Widget build(BuildContext context) {
    final hasMedia = media.isNotEmpty;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        children: [
          if (hasMedia)
            HangoutFeedMediaCarousel(
              media: media,
              controller: mediaController,
              videoControllers: videoControllers,
              memCacheWidth: memCacheWidth,
              onTogglePlay: onTogglePlay,
              manuallyPaused: manuallyPaused,
              onUserPauseChanged: onUserPauseChanged,
            )
          else
            const _NoMediaHero(),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.55],
                  ),
                ),
              ),
            ),
          ),
          
          const PositionedDirectional(
            top: 12,
            start: 12,
            child: _HangoutBadge(),
          ),
          if (onAddMedia != null)
            PositionedDirectional(
              top: 12,
              end: 12,
              child: HangoutMediaAddBox(onAddMedia: onAddMedia!),
            ),
          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final reservedForPill = joinState != null ? 110.0 : 0.0;
                final venueMax =
                    (constraints.maxWidth - 64 - reservedForPill - 16)
                        .clamp(80.0, 280.0);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    HangoutFeedDateTile(
                      scheduledAt: scheduledAt,
                      isPast: isPast,
                    ),
                    if (venue != null && onVenueTap != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: HangoutFeedHeroVenueChip(
                          venue: venue!,
                          branch: branch,
                          onTap: onVenueTap!,
                          maxWidth: venueMax,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (joinState != null)
                      HangoutFeedJoinPill(
                        state: joinState!,
                        loading: joinInFlight,
                        onTap: onJoin,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoMediaHero extends StatelessWidget {
  const _NoMediaHero();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.primary.withValues(alpha: 0.92),
            c.primary.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          TablerIcons.calendar_event,
          color: c.onPrimary.withValues(alpha: 0.55),
          size: 58,
        ),
      ),
    );
  }
}

class _HangoutBadge extends StatelessWidget {
  const _HangoutBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(TablerIcons.calendar_event, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                LocaleKeys.hangout_label.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
