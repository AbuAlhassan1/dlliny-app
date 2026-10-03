import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:hangout/presentation/hangout/share/hangout_share_service.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_actions_sheet.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_comments_bottom_sheet.dart';
import 'package:hangout/presentation/hub/controllers/my_hangouts/my_hub_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:hangout/presentation/shared/widgets/hangout_card_chrome.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HangoutPostCard extends StatefulWidget {
  final HangoutFeedItem item;
  const HangoutPostCard({super.key, required this.item});

  @override
  State<HangoutPostCard> createState() => _HangoutPostCardState();
}

class _HangoutPostCardState extends State<HangoutPostCard>
    with WidgetsBindingObserver {
  static const double _radius = 40;
  static const double _playThreshold = 0.6;

  final ApiService _api = serviceLocator.get<ApiService>();
  late bool _liked = widget.item.likedByMe;
  late int _likes = widget.item.likesCount;
  bool _likeInFlight = false;

  List<FeedMediaItem> get _media => widget.item.media;
  final PageController _mediaController = PageController();
  late List<VideoPlayback?> _videos;
  bool _videosInitialized = false;
  int _currentMediaIndex = 0;
  double _visibleFraction = 0;
  final Set<int> _manuallyPaused = {};

  HangoutFeedItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videos = List<VideoPlayback?>.filled(
      _media.length,
      null,
      growable: false,
    );
    _mediaController.addListener(_onMediaPageChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mediaController.removeListener(_onMediaPageChanged);
    _releaseVideos();
    _mediaController.dispose();
    super.dispose();
  }

  void _onMediaPageChanged() {
    final page = _mediaController.page?.round() ?? 0;
    if (page == _currentMediaIndex) return;
    setState(() => _currentMediaIndex = page);
    _syncPlayback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPlayback();
      return;
    }
    for (final video in _videos) {
      final c = video?.controller;
      if (c != null && c.value.isInitialized && c.value.isPlaying) c.pause();
    }
  }

  void _initVideos() {
    if (_videosInitialized) return;
    _videosInitialized = true;
    for (int i = 0; i < _media.length; i++) {
      final m = _media[i];
      if (m.type != 'video') continue;
      _videos[i] = VideoSource.of(m.url, streamUrl: m.streamUrl).load(
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
      final isActive = shouldPlay &&
          i == _currentMediaIndex &&
          !_manuallyPaused.contains(i);
      if (isActive) {
        c.setVolume(muted ? 0 : 1);
        if (!c.value.isPlaying) c.play();
      } else if (c.value.isPlaying) {
        c.pause();
      }
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    _visibleFraction = info.visibleFraction;
    if (info.visibleFraction > 0.1 && !_videosInitialized) {
      _initVideos();
    } else if (info.visibleFraction == 0 && _videosInitialized) {
      _releaseVideos();
    }
    _syncPlayback();
  }

  void _onUserPauseChanged(int index, bool nowPaused) {
    setState(() {
      if (nowPaused) {
        _manuallyPaused.add(index);
      } else {
        _manuallyPaused.remove(index);
      }
    });
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HangoutDetailsPageWrapper(
          hangoutId: _item.id,
          seedViewerInvitationStatus: _item.viewerInvitation?.status,
          seedViewerInvitationId: _item.viewerInvitation?.id,
          seedLikedByMe: _liked,
          seedLikesCount: _likes,
        ),
      ),
    );
  }

  void _openComments() {
    showHangoutCommentsBottomSheet(context: context, hangoutId: _item.id);
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _likes = (_likes + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
      _likeInFlight = true;
    });
    try {
      final res = wasLiked
          ? await _api.unlikeHangout(_item.id)
          : await _api.likeHangout(_item.id);
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
      _liked = wasLiked;
      _likes = (_likes + (wasLiked ? 1 : -1)).clamp(0, 1 << 31);
    });
    appToast.error(LocaleKeys.common_operation_failed.tr());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mq = MediaQuery.of(context);
    final memWidth = ((mq.size.width - 30) * mq.devicePixelRatio).round();

    final currentIsVideo =
        _media.isNotEmpty && _media[_currentMediaIndex].type == 'video';

    return BlocListener<VideoBloc, VideoBlocState>(
      listenWhen: (_, curr) => curr is VideoToggledSound,
      listener: (_, _) => _syncPlayback(),
      child: VisibilityDetector(
        key: Key('hub-hangout-${_item.id}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: GestureDetector(
          onTap: _openDetails,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: AspectRatio(
              aspectRatio: _cardAspect(_item),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _MediaCarousel(
                    media: _media,
                    controller: _mediaController,
                    videoControllers: [for (final v in _videos) v?.controller],
                    memWidth: memWidth,
                    manuallyPaused: _manuallyPaused,
                    onUserPauseChanged: _onUserPauseChanged,
                    onTogglePlay: () => setState(() {}),
                  ),

                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x8C000000),
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0xC2000000),
                            ],
                            stops: [0.0, 0.28, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    end: 12,
                    child: HangoutCardAuthorRow(
                      item: _item,
                      onMore: () => _openActions(context, _item),
                      onShareInstagram: () =>
                          openHangoutStoryEditor(context, _item.id),
                    ),
                  ),

                  if (currentIsVideo)
                    PositionedDirectional(
                      top: 84,
                      end: 12,
                      child: HangoutCardMuteButton(
                        controller: _videos[_currentMediaIndex]?.controller,
                      ),
                    ),

                  PositionedDirectional(
                    start: 12,
                    end: 12,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_media.length > 1) ...[
                          HangoutCardMediaDots(
                            controller: _mediaController,
                            count: _media.length,
                          ),
                          const SizedBox(height: 10),
                        ],
                        HangoutCardBottomBlock(
                          item: _item,
                          liked: _liked,
                          likesCount: _likes,
                          onLike: _toggleLike,
                          onComment: _openComments,
                          onPeople: _openDetails,
                        ),
                      ],
                    ),
                  ),

                  if (_item.status == 'cancelled')
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: c.background.withValues(alpha: 0.45),
                        ),
                      ),
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

bool _isMyHangout(BuildContext context, HangoutFeedItem item) {
  if (item.mine) return true;
  final myId = context.read<MyProfileBloc>().user?.id;
  final organizerUserId = item.organizerUser?.id;
  if (myId != null && organizerUserId != null && organizerUserId == myId) {
    return true;
  }
  final venueId = item.organizerVenue?.id;
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

Future<void> _openActions(BuildContext context, HangoutFeedItem item) async {
  final hubBloc = context.read<MyHubHangoutsBloc>();
  final result = await showHangoutActionsSheet(
    context,
    hangoutId: item.id,
    isMine: _isMyHangout(context, item),
    scheduledAt: DateTime.tryParse(item.scheduledAt)?.toLocal(),
  );
  if (result == HangoutActionResult.cancelled ||
      result == HangoutActionResult.deleted) {
    hubBloc.add(const LoadMyHubHangouts());
  }
}

class _PlayGlyph extends StatelessWidget {
  const _PlayGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.4),
      ),
      child: const Icon(
        TablerIcons.player_play_filled,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _MediaCarousel extends StatelessWidget {
  final List<FeedMediaItem> media;
  final PageController controller;
  final List<VideoPlayerController?> videoControllers;
  final int memWidth;
  final Set<int> manuallyPaused;
  final void Function(int index, bool nowPaused) onUserPauseChanged;
  final VoidCallback onTogglePlay;

  const _MediaCarousel({
    required this.media,
    required this.controller,
    required this.videoControllers,
    required this.memWidth,
    required this.manuallyPaused,
    required this.onUserPauseChanged,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (media.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surfaceElevated, c.surfaceMuted],
          ),
        ),
        child: Center(
          child: Icon(
            TablerIcons.calendar_event,
            color: c.onSurfaceMuted,
            size: 34,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: c.mediaSurface),
        PageView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          itemCount: media.length,
          itemBuilder: (context, index) {
            final item = media[index];
            if (item.type == 'video') {
              return _VideoPage(
                controller: videoControllers[index],
                thumbnailUrl: item.thumbnailUrl,
                memWidth: memWidth,
                paused: manuallyPaused.contains(index),
                onTap: () {
                  final vc = videoControllers[index];
                  if (vc == null || !vc.value.isInitialized) return;
                  final wasPlaying = vc.value.isPlaying;
                  if (wasPlaying) {
                    vc.pause();
                  } else {
                    vc.play();
                  }
                  onUserPauseChanged(index, wasPlaying);
                  onTogglePlay();
                },
              );
            }
            return CachedNetworkImage(
              imageUrl: item.url,
              fit: BoxFit.cover,
              memCacheWidth: memWidth,
              placeholder: (_, _) => ColoredBox(color: c.mediaSurface),
              errorWidget: (_, _, _) => ColoredBox(
                color: c.mediaSurface,
                child: Icon(Icons.error_outline, color: c.onMediaSurface),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _VideoPage extends StatelessWidget {
  final VideoPlayerController? controller;
  final String? thumbnailUrl;
  final int memWidth;
  final bool paused;
  final VoidCallback onTap;

  const _VideoPage({
    required this.controller,
    required this.thumbnailUrl,
    required this.memWidth,
    required this.paused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final vc = controller;
    final ready = vc != null && vc.value.isInitialized;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ready ? onTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: vc.value.size.width,
                height: vc.value.size.height,
                child: VideoPlayer(vc),
              ),
            )
          else if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: thumbnailUrl!,
              fit: BoxFit.cover,
              memCacheWidth: memWidth,
              errorWidget: (_, _, _) => ColoredBox(color: c.mediaSurface),
            )
          else
            ColoredBox(color: c.mediaSurface),
          if (paused) const Center(child: _PlayGlyph()),
        ],
      ),
    );
  }
}

double _cardAspect(HangoutFeedItem item) {
  final ar = item.media.isNotEmpty ? item.media.first.aspectRatio : null;
  if (ar != null && ar.isFinite && ar > 0) return ar.clamp(0.72, 1.1);
  return 4 / 5;
}
