// ignore_for_file: use_build_context_synchronously
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/helper/image_cropper.dart';
import 'package:hangout/helper/image_picker.dart';
import 'package:hangout/helper/video_picker.dart';
import 'package:hangout/presentation/venue/controllers/venue_background_media/venue_background_media_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class BackgroundVideoPlayer extends StatefulWidget {
  final String path;

  final String? streamUrl;
  final String venueId;
  final String? viewerRole;

  final String? posterUrl;
  const BackgroundVideoPlayer({
    super.key,
    required this.path,
    this.streamUrl,
    required this.venueId,
    this.viewerRole,
    this.posterUrl,
  });

  @override
  State<BackgroundVideoPlayer> createState() => _BackgroundVideoPlayerState();
}

class _BackgroundVideoPlayerState extends State<BackgroundVideoPlayer> {
  static const Duration _attemptTimeout = Duration(minutes: 3);
  static const int _maxAttempts = 3;

  late VideoSource _source = _sourceOf(widget);
  VideoPlayback? _video;
  VideoPlayerController? get _controller => _video?.controller;
  bool _isLoading = false;
  bool _hasError = false;
  int _attempt = 0;
  bool _isMuted = false;

  static VideoSource _sourceOf(BackgroundVideoPlayer w) =>
      VideoSource.of(w.path, streamUrl: w.streamUrl);

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant BackgroundVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) return;
    _controller?.pause();
    _video?.dispose();
    _video = null;
    _source = _sourceOf(widget);
    _attempt = 0;
    if (_hasPath) {
      _initController();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  bool get _hasPath => widget.path.isNotEmpty;

  void _initController() {
    if (!_hasPath) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _video = _source.load(
      videoPlayerOptions: VideoPlayerOptions(),
      timeout: _attemptTimeout,
      onReady: (controller) async {
        await controller.setLooping(true);
        await controller.setVolume(_isMuted ? 0 : 1);
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
        await controller.play();
      },
      onError: _onAttemptFailed,
    );
  }

  Future<void> _onAttemptFailed(Object e, StackTrace st) async {
    log(
      'BackgroundVideoPlayer: init failed (attempt ${_attempt + 1}/$_maxAttempts) — $e\n$st',
    );
    _video?.dispose();
    _video = null;
    _source = _source.fallback ?? _source;
    if (!mounted) return;
    _attempt++;
    if (_attempt < _maxAttempts) {
      await Future.delayed(Duration(seconds: _attempt));
      if (!mounted) return;
      _initController();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _retry() {
    _attempt = 0;
    _initController();
  }

  Future<void> _toggleMute() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final next = !_isMuted;
    setState(() => _isMuted = next);
    await c.setVolume(next ? 0 : 1);
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final visible = info.visibleFraction >= 0.1;
    if (visible && !c.value.isPlaying) {
      c.play();
    } else if (!visible && c.value.isPlaying) {
      c.pause();
    }
  }

  @override
  void dispose() {
    _controller?.pause();
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext _) {
    final initialized = _controller?.value.isInitialized ?? false;
    return BlocProvider(
      create: (context) => VenueBackgroundMediaBloc(),
      child: Positioned.fill(
        child: VisibilityDetector(
          key: ValueKey('venue-cover-${widget.venueId}-${widget.path}'),
          onVisibilityChanged: _onVisibilityChanged,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (initialized)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                _placeholder(),
              PositionedDirectional(
                top: 10,
                end: 10,
                start: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                
                    BackButton(),
                
                    Row(
                      children: [
                        if (initialized)
                          _MuteButton(isMuted: _isMuted, onTap: _toggleMute),
                        if (initialized &&
                            userHasOnVenue(
                              context,
                              VenuePerm.mediaUpload,
                              widget.venueId,
                            ))
                          const SizedBox(width: 8),
                        if (userHasOnVenue(
                          context,
                          VenuePerm.mediaUpload,
                          widget.venueId,
                        ))
                          _CoverEditButton(venueId: widget.venueId),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    final c = context.c;
    final poster = widget.posterUrl;
    if (poster != null && poster.isNotEmpty) {
      final mq = MediaQuery.of(context);
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: poster,
            fit: BoxFit.cover,
            memCacheWidth: (mq.size.width * mq.devicePixelRatio).round(),
            placeholder: (_, _) => ColoredBox(color: c.mediaSurface),
            errorWidget: (_, _, _) => ColoredBox(color: c.mediaSurface),
          ),
          if (_hasError)
            Center(
              child: TextButton.icon(
                onPressed: _retry,
                icon: Icon(
                  Icons.refresh,
                  color: c.onMediaSurface.withValues(alpha: 0.7),
                  size: 18,
                ),
                label: Text(
                  LocaleKeys.venue_background_button_retry.tr(),
                  style: TextStyle(
                    color: c.onMediaSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      color: c.mediaSurface,
      child: Center(
        child: _isLoading
            ? SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: c.onMediaSurface.withValues(alpha: 0.7),
                  strokeWidth: 2,
                ),
              )
            : _hasError
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    color: c.onMediaSurface.withValues(alpha: 0.38),
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _retry,
                    icon: Icon(
                      Icons.refresh,
                      color: c.onMediaSurface.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    label: Text(
                      LocaleKeys.venue_background_button_retry.tr(),
                      style: TextStyle(
                        color: c.onMediaSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              )
            : Icon(
                Icons.photo_library_outlined,
                color: c.onMediaSurface.withValues(alpha: 0.24),
                size: 48,
              ),
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onTap;
  const _MuteButton({required this.isMuted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _CoverEditButton extends StatelessWidget {
  final String venueId;
  const _CoverEditButton({required this.venueId});

  Future<void> _pickAndUpload(BuildContext context) async {
    final bloc = context.read<VenueBackgroundMediaBloc>();
    final c = context.c;
    final choice = await showModalBottomSheet<_CoverPick>(
      context: context,
      backgroundColor: c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final sc = sheetContext.c;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sc.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.image, color: sc.onSurface),
                title: Text(
                  LocaleKeys.venue_background_badge_image.tr(),
                  style: TextStyle(color: sc.onSurface),
                ),
                onTap: () => Navigator.of(sheetContext).pop(_CoverPick.image),
              ),
              ListTile(
                leading: Icon(Icons.movie, color: sc.onSurface),
                title: Text(
                  LocaleKeys.venue_background_badge_video.tr(),
                  style: TextStyle(color: sc.onSurface),
                ),
                onTap: () => Navigator.of(sheetContext).pop(_CoverPick.video),
              ),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _CoverPick.image:
        final file = await pickImage();
        if (file == null || !context.mounted) return;
        final cropped = await cropImageWithUi(file, 16 / 9);
        if (cropped == null) return;
        bloc.add(UpdateVenueCover(venueId: venueId, file: cropped));
        break;

      case _CoverPick.video:
        final file = await pickVideo();
        if (file == null) return;
        bloc.add(UpdateVenueCover(venueId: venueId, file: file));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VenueBackgroundMediaBloc, VenueBackgroundMediaState>(
      listenWhen: (_, s) => s is VenueBackgroundMediaLoaded,
      listener: (context, _) {
        context.read<VenueBloc>().add(GetVenueDetails(venueId));
      },
      child: BlocBuilder<VenueBackgroundMediaBloc, VenueBackgroundMediaState>(
        buildWhen: (_, s) =>
            s is VenueBackgroundMediaLoading ||
            s is VenueBackgroundMediaLoaded ||
            s is VenueBackgroundMediaError ||
            s is VenueBackgroundMediaInitial,
        builder: (context, state) {
          final c = context.c;
          final busy = state is VenueBackgroundMediaLoading;
          return Material(
            color: c.scrimSubtle,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy ? null : () => _pickAndUpload(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: c.onMediaSurface,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.edit, color: c.onMediaSurface, size: 18),
                    const SizedBox(width: 5),
                    Text(
                      LocaleKeys.venue_background_change_cover.tr(),
                      style: TextStyle(color: c.onMediaSurface),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _CoverPick { image, video }
