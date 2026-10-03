import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';

class HangoutCardAuthorRow extends StatelessWidget {
  final HangoutFeedItem item;
  final VoidCallback onMore;

  final VoidCallback? onShareInstagram;

  const HangoutCardAuthorRow({
    super.key,
    required this.item,
    required this.onMore,
    this.onShareInstagram,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = item.organizerUser;
    final orgVenue = item.organizerVenue;

    final String name;
    final String? handle;
    final String? avatarUrl;
    final bool verified;
    if (user != null) {
      name = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : user.username;
      handle = '@${user.username}';
      avatarUrl = user.avatarUrl;
      verified = false;
    } else if (orgVenue != null) {
      name = context.pickBilingual(ar: orgVenue.nameAr, en: orgVenue.nameEn);
      handle = null;
      avatarUrl = orgVenue.logoUrl;
      verified = true;
    } else {
      name = LocaleKeys.explore_author_fallback.tr();
      handle = null;
      avatarUrl = null;
      verified = false;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Avatar(url: avatarUrl, isVenue: user == null),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'IBMPlexSansArabic',
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              TablerIcons.rosette_discount_check_filled,
                              color: c.success,
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                      if (handle != null)
                        Text(
                          handle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'IBMPlexSansArabic',
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            if (onShareInstagram != null) ...[
              _GlassIconButton(
                icon: TablerIcons.brand_instagram,
                onTap: onShareInstagram!,
              ),
              const SizedBox(width: 8),
            ],
            _GlassIconButton(icon: TablerIcons.dots, onTap: onMore),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool isVenue;
  const _Avatar({required this.url, required this.isVenue});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      isVenue ? TablerIcons.building_store : TablerIcons.user,
      color: Colors.white,
      size: 18,
    );
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: (url != null && url!.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 108,
                errorWidget: (_, _, _) => Center(child: fallback),
              ),
            )
          : Center(child: fallback),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class HangoutCardMuteButton extends StatelessWidget {
  final VideoPlayerController? controller;
  const HangoutCardMuteButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoBloc, VideoBlocState>(
      builder: (context, state) {
        final muted = state.isMuted;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final vc = controller;
            if (vc == null || !vc.value.isInitialized) return;
            context.read<VideoBloc>().add(
              VideoToggleSoundEvent(controller: vc),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Icon(
                  muted ? TablerIcons.volume_3 : TablerIcons.volume,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HangoutCardMediaDots extends StatelessWidget {
  final PageController controller;
  final int count;
  const HangoutCardMediaDots({
    super.key,
    required this.controller,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count < 2) return const SizedBox.shrink();
    return Center(
      child: SmoothPageIndicator(
        controller: controller,
        count: count,
        effect: const WormEffect(
          dotColor: Color(0x66FFFFFF),
          activeDotColor: Colors.white,
          dotHeight: 7,
          dotWidth: 7,
        ),
      ),
    );
  }
}

class HangoutCardBottomBlock extends StatelessWidget {
  final HangoutFeedItem item;
  final bool liked;
  final int likesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onPeople;
  final Widget? trailing;

  const HangoutCardBottomBlock({
    super.key,
    required this.item,
    required this.liked,
    required this.likesCount,
    required this.onLike,
    required this.onComment,
    required this.onPeople,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final venue = item.venue ?? item.organizerVenue;
    final venueName = venue == null
        ? ''
        : context.pickBilingual(ar: venue.nameAr, en: venue.nameEn);
    final title = item.title?.trim() ?? '';
    final description = item.description?.trim() ?? '';
    final caption = [
      if (title.isNotEmpty) title else if (venueName.isNotEmpty) venueName,
      if (description.isNotEmpty) description,
    ].join('\n');

    final date = DateTime.tryParse(item.scheduledAt)?.toLocal();
    final dateLabel = date == null
        ? null
        : DateFormat(
            'EEEE d MMM • h:mm a',
            context.locale.toString(),
          ).format(date);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _StatsChip(
              liked: liked,
              likesCount: likesCount,
              commentsCount: item.commentsCount,
              attendeesCount: item.attendees.length,
              onLike: onLike,
              onComment: onComment,
              onPeople: onPeople,
            ),
            const Spacer(),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            if (item.attendees.isNotEmpty)
              _InvitedBubbles(attendees: item.attendees, onTap: onPeople),
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Caption(text: caption),
        ],
        if (dateLabel != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                TablerIcons.calendar_event,
                size: 12,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSansArabic',
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption({required this.text});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      color: Colors.white,
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w600,
      fontFamily: 'IBMPlexSansArabic',
      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
    );
    final tag = base.copyWith(color: const Color(0xFF9FC4FF));

    return Text.rich(
      TextSpan(
        children: [
          for (final token in text.split(' '))
            TextSpan(
              text: '$token ',
              style: token.startsWith('#') ? tag : base,
            ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _StatsChip extends StatelessWidget {
  final bool liked;
  final int likesCount;
  final int commentsCount;
  final int attendeesCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onPeople;

  const _StatsChip({
    required this.liked,
    required this.likesCount,
    required this.commentsCount,
    required this.attendeesCount,
    required this.onLike,
    required this.onComment,
    required this.onPeople,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.black.withValues(alpha: 0.28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Stat(
                icon: liked ? TablerIcons.heart_filled : TablerIcons.heart,
                value: likesCount,
                color: liked ? c.danger : Colors.white,
                onTap: onLike,
              ),
              const SizedBox(width: 16),
              _Stat(
                icon: TablerIcons.message_circle,
                value: commentsCount,
                onTap: onComment,
              ),
              const SizedBox(width: 16),
              _Stat(
                icon: TablerIcons.users,
                value: attendeesCount,
                onTap: onPeople,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;
  final VoidCallback onTap;
  final Color color;
  const _Stat({
    required this.icon,
    required this.value,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitedBubbles extends StatelessWidget {
  final List<HangoutAttendee> attendees;
  final VoidCallback onTap;
  const _InvitedBubbles({required this.attendees, required this.onTap});

  static const int _maxShown = 3;
  static const double _size = 32;
  static const double _overlap = 11;

  @override
  Widget build(BuildContext context) {
    final shown = attendees.take(_maxShown).toList();
    final extra = attendees.length - shown.length;

    final bubbles = <Widget>[];
    for (var i = shown.length - 1; i >= 0; i--) {
      bubbles.add(
        PositionedDirectional(
          end: i * (_size - _overlap),
          child: _FloatingBubble(
            seed: i,
            child: _BubbleAvatar(attendee: shown[i]),
          ),
        ),
      );
    }
    if (extra > 0) {
      bubbles.insert(
        0,
        PositionedDirectional(
          end: shown.length * (_size - _overlap),
          child: _FloatingBubble(
            seed: shown.length,
            child: _OverflowBubble(count: extra),
          ),
        ),
      );
    }

    final faces = shown.length + (extra > 0 ? 1 : 0);
    final width = _size + (faces - 1) * (_size - _overlap);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: _size,
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: AlignmentDirectional.centerEnd,
          children: bubbles,
        ),
      ),
    );
  }
}

class _FloatingBubble extends StatefulWidget {
  final int seed;
  final Widget child;
  const _FloatingBubble({required this.seed, required this.child});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final double _phase;
  late final double _amplitudeY;
  late final double _amplitudeX;

  @override
  void initState() {
    super.initState();
    final r = math.Random(widget.seed * 2654435761 & 0x7fffffff);
    _phase = r.nextDouble() * 2 * math.pi;
    _amplitudeY = 2.5 + r.nextDouble() * 2.5;
    _amplitudeX = 1.0 + r.nextDouble() * 1.5;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4200 + (widget.seed % 4) * 350),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value * 2 * math.pi;
        final dy = math.sin(t + _phase) * _amplitudeY;
        final dx = math.cos(t + _phase) * _amplitudeX;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: widget.child,
    );
  }
}

class _BubbleAvatar extends StatelessWidget {
  final HangoutAttendee attendee;
  const _BubbleAvatar({required this.attendee});

  @override
  Widget build(BuildContext context) {
    final url = attendee.avatarUrl;
    final fallback = const Icon(
      TablerIcons.user,
      color: Colors.white,
      size: 15,
    );
    return Container(
      width: _InvitedBubbles._size,
      height: _InvitedBubbles._size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: (url != null && url.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                errorWidget: (_, _, _) => Center(child: fallback),
              ),
            )
          : Center(child: fallback),
    );
  }
}

class _OverflowBubble extends StatelessWidget {
  final int count;
  const _OverflowBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _InvitedBubbles._size,
      height: _InvitedBubbles._size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}
