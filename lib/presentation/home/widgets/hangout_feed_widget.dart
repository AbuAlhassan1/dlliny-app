import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/widgets/media_double_tap_like.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/respond_invitation_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_actions_sheet.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_comments_bottom_sheet.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_actions_bar.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_cancelled_stub.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_hero.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_organizer_chip.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_people_strip.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_status_line.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_media_index_indicator.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_join_ui_state.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/shared/widgets/author_preview_popup.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wave_divider/wave_divider.dart';

class HangoutFeedWidget extends StatefulWidget {
  final HangoutFeedItem item;
  const HangoutFeedWidget({super.key, required this.item});

  @override
  State<HangoutFeedWidget> createState() => _HangoutFeedWidgetState();
}

class _HangoutFeedWidgetState extends State<HangoutFeedWidget>
    with WidgetsBindingObserver {
  static const double _playThreshold = 0.6;
  late List<FeedMediaItem> _media = widget.item.media;
  late List<VideoPlayback?> _videos;
  final PageController _mediaController = PageController();
  bool _videosInitialized = false;

  int _currentMediaIndex = 0;
  double _visibleFraction = 0;
  final Set<int> _manuallyPaused = {};
  late bool _likedByMe = widget.item.likedByMe;
  late int _likesCount = widget.item.likesCount;
  bool _likeInFlight = false;
  bool _cancelledLocally = false;
  late String? _viewerInvitationStatus =
      widget.item.viewerInvitation?.status;
  late final String? _viewerInvitationId = widget.item.viewerInvitation?.id;
  bool _joinInFlight = false;
  double? _mediaAspect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videos = List<VideoPlayback?>.filled(
      _media.length,
      null,
      growable: false,
    );
    _resolveFirstMediaAspect();
    _mediaController.addListener(_onMediaPageChanged);
  }

  void _onMediaPageChanged() {
    final page = _mediaController.page?.round() ?? 0;
    if (page == _currentMediaIndex) return;
    _currentMediaIndex = page;
    _syncPlayback();
  }

  void _resolveFirstMediaAspect() {
    final items = _media;
    if (items.isEmpty) return;
    final first = items.first.aspectRatio;
    if (first != null && first.isFinite && first > 0) {
      _mediaAspect = first;
    }
  }

  Future<void> _reloadMedia() async {
    final api = serviceLocator.get<ApiService>();
    try {
      final res = await api.getHangoutMedia(widget.item.id);
      if (!mounted || !res.success || res.data == null) return;
      final ordered = [...res.data!]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final media = ordered
          .map((m) => FeedMediaItem(
                type: m.mediaType,
                url: m.url,
                aspectRatio: m.aspectRatio,
                thumbnailUrl: m.thumbnailUrl,
                streamUrl: m.streamUrl,
              ))
          .toList();
      _releaseVideos();
      final firstAr = media.isNotEmpty ? media.first.aspectRatio : null;
      setState(() {
        _media = media;
        _videos = List<VideoPlayback?>.filled(
          _media.length,
          null,
          growable: false,
        );
        _manuallyPaused.clear();
        _mediaAspect = (firstAr != null && firstAr.isFinite && firstAr > 0)
            ? firstAr
            : null;
      });
      if (_visibleFraction > 0.1) _initVideos();
    } on DioException catch (_) {
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mediaController.removeListener(_onMediaPageChanged);
    _releaseVideos();
    _mediaController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPlayback();
      return;
    }
    for (final video in _videos) {
      final c = video?.controller;
      if (c != null && c.value.isInitialized && c.value.isPlaying) {
        c.pause();
      }
    }
  }

  void _initVideos() {
    if (_videosInitialized) return;
    _videosInitialized = true;
    for (int i = 0; i < _media.length; i++) {
      final mediaItem = _media[i];
      if (mediaItem.type == 'video') {
        _videos[i] = VideoSource.of(
          mediaItem.url,
          streamUrl: mediaItem.streamUrl,
        ).load(
          onReady: (c) async {
            if (!mounted) return;
            await c.setLooping(true);
            if (!mounted) return;
            setState(() {});
            _syncPlayback();
          },
        );
      }
    }
  }

  void _releaseVideos() {
    if (!_videosInitialized) return;
    for (int i = 0; i < _videos.length; i++) {
      _videos[i]?.dispose();
      _videos[i] = null;
    }
    _videosInitialized = false;
    _manuallyPaused.clear();
  }

  void _syncPlayback() {
    if (!mounted) return;
    final shouldPlay = _visibleFraction >= _playThreshold;
    final muted = context.read<VideoBloc>().state.isMuted;
    for (int i = 0; i < _videos.length; i++) {
      final c = _videos[i]?.controller;
      if (c == null || !c.value.isInitialized) continue;
      final isActive =
          shouldPlay && i == _currentMediaIndex && !_manuallyPaused.contains(i);
      if (isActive) {
        c.setVolume(muted ? 0 : 1);
        if (!c.value.isPlaying) c.play();
      } else if (c.value.isPlaying) {
        c.pause();
      }
    }
  }

  late final DateTime? _scheduledAt =
      DateTime.tryParse(widget.item.scheduledAt)?.toLocal();

  String get _scheduledLabel {
    final dt = _scheduledAt;
    if (dt == null) return widget.item.scheduledAt;
    final locale = context.locale.toString();
    final day = DateFormat('EEEE', locale).format(dt);
    final time = DateFormat('h:mm a', locale).format(dt);
    final date = DateFormat('d MMM', locale).format(dt);
    return '$day · $date · $time';
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight) return;
    final api = serviceLocator.get<ApiService>();
    final wasLiked = _likedByMe;
    setState(() {
      _likedByMe = !wasLiked;
      _likesCount = (_likesCount + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
      _likeInFlight = true;
    });
    try {
      final res = wasLiked
          ? await api.unlikeHangout(widget.item.id)
          : await api.likeHangout(widget.item.id);
      if (!res.success) throw Exception(res.error);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409 || status == 404) {
      } else {
        _rollbackLike(wasLiked);
      }
    } catch (_) {
      _rollbackLike(wasLiked);
    } finally {
      if (mounted) setState(() => _likeInFlight = false);
    }
  }

  void _rollbackLike(bool wasLiked) {
    if (!mounted) return;
    setState(() {
      _likedByMe = wasLiked;
      _likesCount = (_likesCount + (wasLiked ? 1 : -1)).clamp(0, 1 << 31);
    });
    appToast.error(LocaleKeys.common_operation_failed.tr());
  }

  bool get _canAddMedia {
    if (_isMyHangout) return true;
    return _viewerInvitationStatus == 'accepted';
  }

  bool get _isMyHangout {
    if (widget.item.mine) return true;

    final myId = context.read<MyProfileBloc>().user?.id;
    final organizerUserId = widget.item.organizerUser?.id;
    if (myId != null &&
        organizerUserId != null &&
        organizerUserId == myId) {
      return true;
    }

    final venueId = widget.item.organizerVenue?.id;
    if (venueId == null) return false;
    final access = context.read<AccessBloc>().myAccess?.data;
    if (access == null) return false;
    bool managesVenue(v) => v.venueId == venueId;
    for (final biz in access.businesses) {
      for (final v in biz.venues) {
        if (managesVenue(v)) return true;
      }
    }
    for (final v in access.orphanVenues) {
      if (managesVenue(v)) return true;
    }
    return false;
  }

  HangoutJoinUiState? get _joinUiState {
    if (_isMyHangout) return null;
    if (widget.item.status != 'confirmed') return null;
    final scheduled = _scheduledAt;
    if (scheduled != null && scheduled.isBefore(DateTime.now())) return null;

    final status = _viewerInvitationStatus;
    if (status == 'accepted') return HangoutJoinUiState.joined;
    if (status == 'declined') return null;
    if (status == 'pending') return HangoutJoinUiState.canJoin;
    if (widget.item.joinPolicy == 'OPEN') return HangoutJoinUiState.canJoin;
    return null;
  }

  Future<void> _onJoinPressed() async {
    if (_joinInFlight) return;
    if (_joinUiState != HangoutJoinUiState.canJoin) return;

    final api = serviceLocator.get<ApiService>();
    final prevStatus = _viewerInvitationStatus;
    setState(() {
      _viewerInvitationStatus = 'accepted';
      _joinInFlight = true;
    });

    try {
      final invitationId = _viewerInvitationId;
      if (prevStatus == 'pending' && invitationId != null) {
        final res = await api.respondToInvitation(
          invitationId,
          const RespondInvitationRequest(status: 'accepted'),
        );
        if (!res.success) throw Exception(res.error);
      } else {
        final res = await api.joinHangout(widget.item.id);
        if (!res.success) throw Exception(res.error);
      }
    } on DioException catch (_) {
      _rollbackJoin(prevStatus);
    } catch (_) {
      _rollbackJoin(prevStatus);
    } finally {
      if (mounted) setState(() => _joinInFlight = false);
    }
  }

  void _rollbackJoin(String? prevStatus) {
    if (!mounted) return;
    setState(() => _viewerInvitationStatus = prevStatus);
    appToast.error(LocaleKeys.hangout_join_failed.tr());
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HangoutDetailsPageWrapper(
          hangoutId: widget.item.id,
          seedViewerInvitationStatus: _viewerInvitationStatus,
          seedViewerInvitationId: _viewerInvitationId,
          seedLikedByMe: _likedByMe,
          seedLikesCount: _likesCount,
        ),
      ),
    );
  }

  void _openVenue(String venueId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VenuePageWrapper(venueId: venueId)),
    );
  }

  void _openProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePageWrapper(username: username),
      ),
    );
  }

  void _openComments() {
    showHangoutCommentsBottomSheet(
      context: context,
      hangoutId: widget.item.id,
    );
  }

  void _openShare() {
    openShareSheet(
      context,
      resourceType: SharedResourceType.hangout,
      resourceId: widget.item.id,
      headlineLabel: LocaleKeys.hangout_share_headline.tr(),
    );
  }

  Future<void> _openActions() async {
    final result = await showHangoutActionsSheet(
      context,
      hangoutId: widget.item.id,
      isMine: _isMyHangout,
      scheduledAt: _scheduledAt,
      onMediaUploaded: _reloadMedia,
    );
    if ((result == HangoutActionResult.cancelled ||
            result == HangoutActionResult.deleted) &&
        mounted) {
      setState(() => _cancelledLocally = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cancelledLocally) {
      return HangoutFeedCancelledStub(title: widget.item.title);
    }

    final c = context.c;
    final screenWidth = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final imgWidth = (screenWidth * dpr).toInt();
    final scheduled = _scheduledAt;
    final isPast =
        scheduled != null && scheduled.isBefore(DateTime.now());
    final venue = widget.item.venue ?? widget.item.organizerVenue;
    final user = widget.item.organizerUser;

    return BlocListener<VideoBloc, VideoBlocState>(
      listenWhen: (_, curr) => curr is VideoToggledSound,
      listener: (_, _) => _syncPlayback(),
      child: VisibilityDetector(
      key: Key('hangout-${widget.item.id}'),
      onVisibilityChanged: (info) {
        _visibleFraction = info.visibleFraction;
        if (info.visibleFraction > 0.1 && !_videosInitialized) {
          _initVideos();
        } else if (info.visibleFraction == 0 && _videosInitialized) {
          _releaseVideos();
        }
        _syncPlayback();
      },
      child: Container(
        padding: const EdgeInsets.only(top: 5),
        margin: const EdgeInsets.only(bottom: 15),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _openDetails,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 15,
                    end: 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: user != null
                            ? HangoutFeedOrganizerChip(
                                user: user,
                                createdLabel: formatRelativeTime(
                                  widget.item.createdAt,
                                ),
                                onTap: () => _openProfile(user.username),
                                onLongPress: () => showAuthorPreviewPopup(
                                  context,
                                  imageUrl: user.avatarUrl,
                                  name: user.displayName?.isNotEmpty == true
                                      ? user.displayName!
                                      : user.username,
                                  subtitle: '@${user.username}',
                                  rolePill: LocaleKeys
                                      .hangout_role_pill_organizer
                                      .tr(),
                                  onOpenProfile: () =>
                                      _openProfile(user.username),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 0,
                                ),
                                child: Text(
                                  formatRelativeTime(widget.item.createdAt),
                                  style: TextStyle(
                                    color: c.onSurfaceSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                      ),
                      IconButton(
                        onPressed: _openActions,
                        icon: Icon(
                          TablerIcons.dots_vertical,
                          color: c.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                MediaDoubleTapLike(
                  onDoubleTapLike: () {
                    if (_likedByMe) return;
                    _toggleLike();
                  },
                  child: HangoutFeedHero(
                    media: _media,
                    mediaController: _mediaController,
                    videoControllers: [for (final v in _videos) v?.controller],
                    aspectRatio: _mediaAspect ??
                        (_media.isEmpty ? 16 / 9 : 4 / 3),
                    memCacheWidth: imgWidth,
                    scheduledAt: scheduled,
                    joinState: _joinUiState,
                    joinInFlight: _joinInFlight,
                    onJoin: _onJoinPressed,
                    onTogglePlay: () => setState(() {}),
                    isPast: isPast,
                    manuallyPaused: _manuallyPaused,
                    onUserPauseChanged: (i, nowPaused) {
                      setState(() {
                        if (nowPaused) {
                          _manuallyPaused.add(i);
                        } else {
                          _manuallyPaused.remove(i);
                        }
                      });
                    },
                    venue: venue,
                    branch: widget.item.branch,
                    onVenueTap:
                        venue == null ? null : () => _openVenue(venue.id),
                    onAddMedia: _canAddMedia
                        ? () => runAddHangoutMedia(
                              context,
                              widget.item.id,
                              onUploaded: _reloadMedia,
                            )
                        : null,
                  ),
                ),

                HangoutMediaIndexIndicator(
                  controller: _mediaController,
                  count: _media.length,
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HangoutFeedStatusLine(
                        scheduledLabel: _scheduledLabel,
                        joinPolicy: widget.item.joinPolicy,
                        isPast: isPast,
                      ),
                      if (widget.item.title?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.item.title!,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 17,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (widget.item.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.item.description!,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (widget.item.attendees.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        HangoutFeedPeopleStrip(
                          label: LocaleKeys.hangout_going_strip_title.tr(),
                          icon: TablerIcons.users_group,
                          people: widget.item.attendees,
                          dimmed: false,
                          onTapPerson: (a) => _openProfile(a.username),
                        ),
                      ],
                      if (widget.item.pendingInvitees.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        HangoutFeedPeopleStrip(
                          label: LocaleKeys.hangout_awaiting_strip_title.tr(),
                          icon: TablerIcons.hourglass_low,
                          people: widget.item.pendingInvitees,
                          dimmed: true,
                          onTapPerson: (a) => _openProfile(a.username),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                
                HangoutFeedActionsBar(
                  likedByMe: _likedByMe,
                  likesCount: _likesCount,
                  commentsCount: widget.item.commentsCount,
                  onLike: _toggleLike,
                  onComment: _openComments,
                  onShare: _openShare,
                ),
                
                const SizedBox(height: 15),
                
                WaveDivider(
                  color: c.onSurface,
                  padding: EdgeInsets.zero,
                  thickness: 1,
                  waveHeight: 5,
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
