import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/respond_invitation_request.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_heart_burst.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_media.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_scrim_layer.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_actions_sheet.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_comments_bottom_sheet.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_feed_join_pill.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_join_ui_state.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/shared/widgets/hangout_card_chrome.dart';
import 'package:video_player/video_player.dart';

class HangoutReelCard extends StatefulWidget {
  final HangoutFeedItem item;
  final bool isActive;

  const HangoutReelCard({
    super.key,
    required this.item,
    this.isActive = true,
  });

  @override
  State<HangoutReelCard> createState() => _HangoutReelCardState();
}

class _HangoutReelCardState extends State<HangoutReelCard> with SingleTickerProviderStateMixin {
  final ApiService _api = serviceLocator.get<ApiService>();
  late final AnimationController _heartBurst;
  final PageController _mediaController = PageController();
  final ValueNotifier<VideoPlayerController?> _activeVideo =
      ValueNotifier(null);
  late bool _likedByMe = widget.item.likedByMe;
  late int _likesCount = widget.item.likesCount;
  bool _likeInFlight = false;
  late String? _viewerInvitationStatus = widget.item.viewerInvitation?.status;
  late final String? _viewerInvitationId = widget.item.viewerInvitation?.id;
  bool _joinInFlight = false;
  late final DateTime? _scheduledAt = DateTime.tryParse(widget.item.scheduledAt)?.toLocal();

  @override
  void initState() {
    super.initState();
    _heartBurst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _heartBurst.dispose();
    _mediaController.dispose();
    _activeVideo.dispose();
    super.dispose();
  }

  bool get _isMyHangout {
    if (widget.item.mine) return true;
    final myId = context.read<MyProfileBloc>().user?.id;
    final organizerUserId = widget.item.organizerUser?.id;
    if (myId != null && organizerUserId != null && organizerUserId == myId) {
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

  void _onDoubleTapLike() {
    _heartBurst
      ..reset()
      ..forward();
    if (!_likedByMe) _toggleLike();
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight) return;
    final wasLiked = _likedByMe;
    setState(() {
      _likedByMe = !wasLiked;
      _likesCount = (_likesCount + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
      _likeInFlight = true;
    });
    try {
      final res = wasLiked
          ? await _api.unlikeHangout(widget.item.id)
          : await _api.likeHangout(widget.item.id);
      if (!res.success) throw Exception(res.error);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 409 && status != 404) _rollbackLike(wasLiked);
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

  Future<void> _onJoinPressed() async {
    if (_joinInFlight) return;
    if (_joinUiState != HangoutJoinUiState.canJoin) return;

    final prevStatus = _viewerInvitationStatus;
    setState(() {
      _viewerInvitationStatus = 'accepted';
      _joinInFlight = true;
    });
    try {
      final invitationId = _viewerInvitationId;
      if (prevStatus == 'pending' && invitationId != null) {
        final res = await _api.respondToInvitation(
          invitationId,
          const RespondInvitationRequest(status: 'accepted'),
        );
        if (!res.success) throw Exception(res.error);
      } else {
        final res = await _api.joinHangout(widget.item.id);
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

  void _openComments() {
    showHangoutCommentsBottomSheet(
      context: context,
      hangoutId: widget.item.id,
    );
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

  Future<void> _openActions() async {
    await showHangoutActionsSheet(
      context,
      hangoutId: widget.item.id,
      isMine: _isMyHangout,
      scheduledAt: _scheduledAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMedia = widget.item.media.isNotEmpty;
    final mq = MediaQuery.of(context);
    final joinState = _joinUiState;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasMedia)
          ReelMedia(
            media: widget.item.media,
            isActive: widget.isActive,
            controller: _mediaController,
            activeVideo: _activeVideo,
            sourceId: 'hangout-${widget.item.id}',
            onDoubleTapLike: _onDoubleTapLike,
          )
        else
          _EmptyHangoutCanvas(onDoubleTapLike: _onDoubleTapLike),
        const ReelScrimLayer(),
        ReelHeartBurst(animation: _heartBurst),

        PositionedDirectional(
          top: mq.padding.top + 8,
          start: 12,
          end: 12,
          child: HangoutCardAuthorRow(
            item: widget.item,
            onMore: _openActions,
          ),
        ),

        PositionedDirectional(
          top: mq.padding.top + 80,
          end: 12,
          child: ValueListenableBuilder<VideoPlayerController?>(
            valueListenable: _activeVideo,
            builder: (context, activeVideo, _) => activeVideo == null
                ? const SizedBox.shrink()
                : HangoutCardMuteButton(controller: activeVideo),
          ),
        ),

        PositionedDirectional(
          start: 12,
          end: 12,
          bottom: mq.padding.bottom + 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.item.media.length > 1) ...[
                HangoutCardMediaDots(
                  controller: _mediaController,
                  count: widget.item.media.length,
                ),
                const SizedBox(height: 10),
              ],
              HangoutCardBottomBlock(
                item: widget.item,
                liked: _likedByMe,
                likesCount: _likesCount,
                onLike: _toggleLike,
                onComment: _openComments,
                onPeople: _openDetails,
                trailing: joinState == null
                    ? null
                    : HangoutFeedJoinPill(
                        state: joinState,
                        loading: _joinInFlight,
                        onTap: _onJoinPressed,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHangoutCanvas extends StatelessWidget {
  final VoidCallback onDoubleTapLike;
  const _EmptyHangoutCanvas({required this.onDoubleTapLike});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: onDoubleTapLike,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              c.mediaSurface,
              Color.alphaBlend(
                c.onMediaSurface.withValues(alpha: 0.06),
                c.mediaSurface,
              ),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            TablerIcons.calendar_event,
            color: c.onMediaSurface.withValues(alpha: 0.25),
            size: 64,
          ),
        ),
      ),
    );
  }
}
