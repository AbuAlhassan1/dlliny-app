import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/respond_invitation_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/hangout/share/hangout_share_service.dart';
import 'package:hangout/presentation/hangout/bloc/hangout_details_bloc.dart';
import 'package:hangout/presentation/hangout/controllers/comments/hangout_comments_bloc.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_actions_sheet.dart';
import 'package:hangout/presentation/hangout/widgets/hangout_details_body.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_join_ui_state.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

class HangoutDetailsPageWrapper extends StatelessWidget {
  final String hangoutId;
  final String? seedViewerInvitationStatus;
  final String? seedViewerInvitationId;
  final bool? seedLikedByMe;
  final int? seedLikesCount;

  const HangoutDetailsPageWrapper({
    super.key,
    required this.hangoutId,
    this.seedViewerInvitationStatus,
    this.seedViewerInvitationId,
    this.seedLikedByMe,
    this.seedLikesCount,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              HangoutDetailsBloc()..add(LoadHangoutDetails(hangoutId)),
        ),
        BlocProvider(
          create: (_) =>
              HangoutCommentsBloc()..add(GetHangoutComments(hangoutId)),
        ),
      ],
      child: _HangoutDetailsView(
        hangoutId: hangoutId,
        seedViewerInvitationStatus: seedViewerInvitationStatus,
        seedViewerInvitationId: seedViewerInvitationId,
        seedLikedByMe: seedLikedByMe,
        seedLikesCount: seedLikesCount,
      ),
    );
  }
}

class _HangoutDetailsView extends StatefulWidget {
  final String hangoutId;
  final String? seedViewerInvitationStatus;
  final String? seedViewerInvitationId;
  final bool? seedLikedByMe;
  final int? seedLikesCount;

  const _HangoutDetailsView({
    required this.hangoutId,
    this.seedViewerInvitationStatus,
    this.seedViewerInvitationId,
    this.seedLikedByMe,
    this.seedLikesCount,
  });

  @override
  State<_HangoutDetailsView> createState() => _HangoutDetailsViewState();
}

class _HangoutDetailsViewState extends State<_HangoutDetailsView>
    with WidgetsBindingObserver {
  final PageController _mediaController = PageController();
  late bool? _likedByMe = widget.seedLikedByMe;
  late int? _likesCount = widget.seedLikesCount;
  bool _likeInFlight = false;
  late String? _viewerInvitationStatus = widget.seedViewerInvitationStatus;
  late String? _viewerInvitationId = widget.seedViewerInvitationId;
  bool _joinInFlight = false;
  double? _mediaAspect;
  String? _aspectResolvedFor;
  List<VideoPlayback?> _videos = const [];
  bool _videosInitialized = false;
  int _currentMediaIndex = 0;
  final Set<int> _manuallyPaused = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mediaController.addListener(_onMediaPageChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mediaController.removeListener(_onMediaPageChanged);
    for (final video in _videos) {
      video?.dispose();
    }
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

  void _onMediaPageChanged() {
    final page = _mediaController.page?.round() ?? 0;
    if (page == _currentMediaIndex) return;
    _currentMediaIndex = page;
    _syncPlayback();
  }

  void _resolveFirstMediaAspect(List<HangoutMediaResponse> media) {
    if (media.isEmpty) return;
    final first = media.first;
    if (_aspectResolvedFor == first.url) return;
    _aspectResolvedFor = first.url;
    final ar = first.aspectRatio;
    if (ar != null && ar.isFinite && ar > 0) {
      setState(() => _mediaAspect = ar);
    }
    if (!_videosInitialized) {
      _videosInitialized = true;
      _videos = List<VideoPlayback?>.filled(
        media.length,
        null,
        growable: false,
      );
      for (int i = 0; i < media.length; i++) {
        final m = media[i];
        if (m.mediaType == 'video') {
          _videos[i] = VideoSource.of(m.url, streamUrl: m.streamUrl).load(
            onReady: (vc) async {
              if (!mounted) return;
              await vc.setLooping(true);
              if (!mounted) return;
              setState(() {});
              _syncPlayback();
            },
          );
        }
      }
    }
  }

  void _reloadDetails() {
    if (!mounted) return;
    for (final video in _videos) {
      video?.dispose();
    }
    _videos = const [];
    _videosInitialized = false;
    _aspectResolvedFor = null;
    context
        .read<HangoutDetailsBloc>()
        .add(LoadHangoutDetails(widget.hangoutId));
  }

  void _syncPlayback() {
    if (!mounted) return;
    for (int i = 0; i < _videos.length; i++) {
      final c = _videos[i]?.controller;
      if (c == null || !c.value.isInitialized) continue;
      final isActive =
          i == _currentMediaIndex && !_manuallyPaused.contains(i);
      if (isActive) {
        if (!c.value.isPlaying) c.play();
      } else if (c.value.isPlaying) {
        c.pause();
      }
    }
  }

  bool _canAddMedia(HangoutResponse hangout) {
    if (hangout.mine) return true;
    final status =
        _viewerInvitationStatus ?? hangout.viewerInvitation?.status;
    return status == 'accepted';
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

  void _syncFromServer(HangoutResponse hangout) {
    if (_likeInFlight || _joinInFlight) return;
    final next = <String, dynamic>{};
    if (_likedByMe == null) next['likedByMe'] = hangout.likedByMe;
    if (_likesCount == null) next['likesCount'] = hangout.likesCount;
    if (_viewerInvitationStatus == null &&
        hangout.viewerInvitation != null) {
      next['status'] = hangout.viewerInvitation!.status;
      next['id'] = hangout.viewerInvitation!.id;
    }
    if (next.isEmpty) return;
    setState(() {
      if (next.containsKey('likedByMe')) {
        _likedByMe = next['likedByMe'] as bool;
      }
      if (next.containsKey('likesCount')) {
        _likesCount = next['likesCount'] as int;
      }
      if (next.containsKey('status')) {
        _viewerInvitationStatus = next['status'] as String;
        _viewerInvitationId = next['id'] as String;
      }
    });
  }

  Future<void> _toggleLike() async {
    if (_likeInFlight || _likedByMe == null) return;
    final api = serviceLocator.get<ApiService>();
    final wasLiked = _likedByMe!;
    setState(() {
      _likedByMe = !wasLiked;
      _likesCount =
          ((_likesCount ?? 0) + (wasLiked ? -1 : 1)).clamp(0, 1 << 31);
      _likeInFlight = true;
    });
    try {
      final res = wasLiked
          ? await api.unlikeHangout(widget.hangoutId)
          : await api.likeHangout(widget.hangoutId);
      if (!res.success) throw Exception(res.error);
    } on DioException catch (_) {
      _rollbackLike(wasLiked);
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
      _likesCount =
          ((_likesCount ?? 0) + (wasLiked ? 1 : -1)).clamp(0, 1 << 31);
    });
    appToast.error(LocaleKeys.common_operation_failed.tr());
  }

  HangoutJoinUiState? _joinUiStateFor(HangoutResponse h) {
    if (h.mine) return null;
    if (h.status != 'confirmed') return null;
    final scheduled = DateTime.tryParse(h.scheduledAt)?.toLocal();
    if (scheduled != null && scheduled.isBefore(DateTime.now())) return null;
    final status = _viewerInvitationStatus;
    if (status == 'accepted') return HangoutJoinUiState.joined;
    if (status == 'declined') return null;
    if (status == 'pending') return HangoutJoinUiState.canJoin;
    if (h.joinPolicy == 'OPEN') return HangoutJoinUiState.canJoin;
    return null;
  }

  Future<void> _onJoinPressed(HangoutResponse h) async {
    if (_joinInFlight) return;
    if (_joinUiStateFor(h) != HangoutJoinUiState.canJoin) return;

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
        final res = await api.joinHangout(widget.hangoutId);
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

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: appPageGradient(context)),
          child: BlocConsumer<HangoutDetailsBloc, HangoutDetailsState>(
          listener: (context, state) {
            if (state is HangoutDetailsLoaded) {
              _syncFromServer(state.hangout);
              _resolveFirstMediaAspect(state.media);
            }
          },
          buildWhen: (prev, curr) {
            if (prev is HangoutDetailsLoaded &&
                curr is HangoutDetailsLoading) {
              return false;
            }
            return true;
          },
          builder: (context, state) {
            if (state is HangoutDetailsLoading ||
                state is HangoutDetailsInitial) {
              return Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1,
                ),
              );
            }
            if (state is HangoutDetailsError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.onSurfaceSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context
                            .read<HangoutDetailsBloc>()
                            .add(LoadHangoutDetails(widget.hangoutId)),
                        child: Text(
                          LocaleKeys.common_retry.tr(),
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final loaded = state as HangoutDetailsLoaded;
            return RefreshIndicator(
              color: c.onSurface,
              backgroundColor: c.background,
              onRefresh: () async {
                context
                    .read<HangoutDetailsBloc>()
                    .add(LoadHangoutDetails(widget.hangoutId));
                await context.read<HangoutDetailsBloc>().stream.firstWhere(
                      (s) =>
                          s is HangoutDetailsLoaded ||
                          s is HangoutDetailsError,
                    );
              },
              child: HangoutDetailsBody(
                hangout: loaded.hangout,
                venue: loaded.venue,
                media: loaded.media,
                mediaController: _mediaController,
                videoControllers: [for (final v in _videos) v?.controller],
                manuallyPaused: _manuallyPaused,
                onUserPauseChanged: _onUserPauseChanged,
                onTogglePlay: () => setState(() {}),
                mediaAspectRatio: _mediaAspect ?? 1,
                likedByMe: _likedByMe ?? loaded.hangout.likedByMe,
                likesCount: _likesCount ?? loaded.hangout.likesCount,
                joinState: _joinUiStateFor(loaded.hangout),
                joinInFlight: _joinInFlight,
                onLike: _toggleLike,
                onJoin: () => _onJoinPressed(loaded.hangout),
                onShare: () => _openShare(loaded.hangout),
                onReport: () => _onReport(loaded.hangout),
                onVenueTap: () => _openVenue(loaded.hangout.venueId),
                onProfileTap: _openProfile,
                onMenu: () => _openActions(loaded.hangout),
                onAddMedia: _canAddMedia(loaded.hangout)
                    ? () => runAddHangoutMedia(
                          context,
                          widget.hangoutId,
                          onUploaded: _reloadDetails,
                        )
                    : null,
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  void _openShare(HangoutResponse h) {
    showHangoutShareSheet(
      context,
      h,
      onShareInApp: () => openShareSheet(
        context,
        resourceType: SharedResourceType.hangout,
        resourceId: h.id,
        headlineLabel: LocaleKeys.hangout_share_headline.tr(),
      ),
    );
  }

  void _onReport(HangoutResponse h) {
    if (h.mine) {
      appToast.info(LocaleKeys.hangout_organize_self_toast.tr());
      return;
    }
    appToast.info(LocaleKeys.hangout_report_coming_soon.tr());
  }

  Future<void> _openActions(HangoutResponse h) async {
    final result = await showHangoutActionsSheet(
      context,
      hangoutId: h.id,
      isMine: h.mine,
      scheduledAt: DateTime.tryParse(h.scheduledAt)?.toLocal(),
      onMediaUploaded: _reloadDetails,
    );
    if ((result == HangoutActionResult.cancelled ||
            result == HangoutActionResult.deleted) &&
        mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openVenue(String venueId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenuePageWrapper(venueId: venueId),
      ),
    );
  }

  void _openProfile(String username) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePageWrapper(username: username),
      ),
    );
  }
}
