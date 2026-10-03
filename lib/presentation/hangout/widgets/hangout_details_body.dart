import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_comments_bottom_sheet.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_details_comments_section.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_actions_bar.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_hero.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_organizer_chip.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_people_strip.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_status_line.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_media_index_indicator.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_join_ui_state.dart';
import 'package:hangout/presentation/post/widgets/media_double_tap_like.dart';
import 'package:video_player/video_player.dart';

class HangoutDetailsBody extends StatelessWidget {
  final HangoutResponse hangout;
  final VenueResponse? venue;
  final List<HangoutMediaResponse> media;
  final PageController mediaController;
  final List<VideoPlayerController?> videoControllers;
  final Set<int> manuallyPaused;
  final void Function(int index, bool nowPaused) onUserPauseChanged;
  final VoidCallback onTogglePlay;
  final double mediaAspectRatio;
  final bool likedByMe;
  final int likesCount;
  final HangoutJoinUiState? joinState;
  final bool joinInFlight;
  final VoidCallback onLike;
  final VoidCallback onJoin;
  final VoidCallback onShare;
  final VoidCallback onReport;
  final VoidCallback onVenueTap;
  final ValueChanged<String> onProfileTap;
  final VoidCallback onMenu;
  final VoidCallback? onAddMedia;

  const HangoutDetailsBody({
    super.key,
    required this.hangout,
    required this.venue,
    required this.media,
    required this.mediaController,
    required this.videoControllers,
    required this.manuallyPaused,
    required this.onUserPauseChanged,
    required this.onTogglePlay,
    required this.mediaAspectRatio,
    required this.likedByMe,
    required this.likesCount,
    required this.joinState,
    required this.joinInFlight,
    required this.onLike,
    required this.onJoin,
    required this.onShare,
    required this.onReport,
    required this.onVenueTap,
    required this.onProfileTap,
    required this.onMenu,
    this.onAddMedia,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final screenWidth = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imgWidth = (screenWidth * dpr).toInt();
    final scheduled = DateTime.tryParse(hangout.scheduledAt)?.toLocal();
    final isPast =
        scheduled != null && scheduled.isBefore(DateTime.now());
    final organizerUser = _organizerUserOf(hangout);
    final organizerVenue = _organizerVenueOf(hangout, venue);
    final feedBranch = _feedBranchOf(hangout.branch);
    final feedMedia = media.map(_toFeedMediaItem).toList(growable: false);
    final attendees = hangout.acceptedInvitees
        .map(_toFeedAttendee)
        .toList(growable: false);
    final pending = hangout.pendingInvitees
        .map(_toFeedAttendee)
        .toList(growable: false);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      TablerIcons.chevron_right,
                      color: c.onSurface,
                    ),
                  ),
                  Expanded(
                    child: organizerUser != null
                        ? HangoutFeedOrganizerChip(
                            user: organizerUser,
                            createdLabel:
                                formatRelativeTime(hangout.createdAt),
                            onTap: () => onProfileTap(organizerUser.username),
                          )
                        : Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 4),
                            child: Text(
                              formatRelativeTime(hangout.createdAt),
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: onMenu,
                    icon: Icon(
                      TablerIcons.dots_vertical,
                      color: c.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        SliverToBoxAdapter(
          child: MediaDoubleTapLike(
            onDoubleTapLike: () {
              if (likedByMe) return;
              onLike();
            },
            child: HangoutFeedHero(
              media: feedMedia,
              mediaController: mediaController,
              videoControllers: videoControllers,
              aspectRatio: mediaAspectRatio,
              memCacheWidth: imgWidth,
              scheduledAt: scheduled,
              joinState: joinState,
              joinInFlight: joinInFlight,
              onJoin: onJoin,
              onTogglePlay: onTogglePlay,
              isPast: isPast,
              manuallyPaused: manuallyPaused,
              onUserPauseChanged: onUserPauseChanged,
              venue: organizerVenue,
              branch: feedBranch,
              onVenueTap: onVenueTap,
              onAddMedia: onAddMedia,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: HangoutMediaIndexIndicator(
            controller: mediaController,
            count: feedMedia.length,
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HangoutFeedStatusLine(
                  scheduledLabel: _scheduledLabel(context, scheduled),
                  joinPolicy: hangout.joinPolicy,
                  isPast: isPast,
                ),
                if (hangout.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  Text(
                    hangout.description!,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                if (attendees.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  HangoutFeedPeopleStrip(
                    label: LocaleKeys.hangout_going_strip_title.tr(),
                    icon: TablerIcons.users_group,
                    people: attendees,
                    dimmed: false,
                    onTapPerson: (a) => onProfileTap(a.username),
                  ),
                ],
                if (pending.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  HangoutFeedPeopleStrip(
                    label: LocaleKeys.hangout_awaiting_strip_title.tr(),
                    icon: TablerIcons.hourglass_low,
                    people: pending,
                    dimmed: true,
                    onTapPerson: (a) => onProfileTap(a.username),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: HangoutFeedActionsBar(
            likedByMe: likedByMe,
            likesCount: likesCount,
            commentsCount: hangout.commentsCount,
            onLike: onLike,
            onComment: () => showHangoutCommentsBottomSheet(
              context: context,
              hangoutId: hangout.id,
            ),
            onShare: onShare,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        HangoutDetailsCommentsSection(hangoutId: hangout.id),
      ],
    );
  }
}

String _scheduledLabel(BuildContext context, DateTime? scheduled) {
  if (scheduled == null) return '';
  final locale = context.locale.toString();
  final day = DateFormat('EEEE', locale).format(scheduled);
  final time = DateFormat('h:mm a', locale).format(scheduled);
  final date = DateFormat('d MMM', locale).format(scheduled);
  return '$day · $date · $time';
}

HangoutOrganizerUser? _organizerUserOf(HangoutResponse h) {
  if (h.organizerId.isEmpty) return null;
  return HangoutOrganizerUser(
    id: h.organizerId,
    username: h.organizerUsername,
    avatarUrl: h.organizerAvatarUrl,
  );
}

HangoutOrganizerVenue _organizerVenueOf(
  HangoutResponse h,
  VenueResponse? v,
) {
  return HangoutOrganizerVenue(
    id: h.venueId,
    nameAr: v?.nameAr.isNotEmpty == true ? v!.nameAr : h.venueNameAr,
    nameEn: v?.nameEn.isNotEmpty == true ? v!.nameEn : h.venueNameEn,
    district: v?.districtNameAr,
    logoUrl: v?.logoUrl,
  );
}

HangoutFeedBranch? _feedBranchOf(HangoutBranch? b) {
  if (b == null) return null;
  return HangoutFeedBranch(
    id: b.id,
    labelAr: b.labelAr,
    labelEn: b.labelEn,
    addressAr: b.addressAr,
    addressEn: b.addressEn,
    isPrimary: b.isPrimary,
  );
}

FeedMediaItem _toFeedMediaItem(HangoutMediaResponse m) => FeedMediaItem(
      type: m.mediaType,
      url: m.url,
      aspectRatio: m.aspectRatio,
      thumbnailUrl: m.thumbnailUrl,
      streamUrl: m.streamUrl,
    );

HangoutAttendee _toFeedAttendee(HangoutAttendeeSummary a) => HangoutAttendee(
      id: a.id,
      username: a.username,
      displayName: a.displayName,
      avatarUrl: a.avatarUrl,
    );
