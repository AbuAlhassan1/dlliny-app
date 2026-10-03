import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_blurred_media.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_play_badge.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ReelMedia extends StatefulWidget {
  final List<FeedMediaItem> media;
  final bool isActive;

  final PageController controller;
  final VoidCallback onDoubleTapLike;
  final String sourceId;

  final ValueNotifier<VideoPlayerController?>? activeVideo;

  const ReelMedia({
    super.key,
    required this.media,
    required this.isActive,
    required this.controller,
    required this.onDoubleTapLike,
    required this.sourceId,
    this.activeVideo,
  });

  @override
  State<ReelMedia> createState() => _ReelMediaState();
}

class _ReelMediaState extends State<ReelMedia> with WidgetsBindingObserver {
  static const double _playThreshold = 0.6;

  late List<VideoPlayback?> _videos;
  bool _videosInitialized = false;

  late int _currentMediaIndex;
  double _visibleFraction = 0;
  final Set<int> _manuallyPaused = {};
  final Set<int> _failedIndices = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentMediaIndex = widget.controller.initialPage.clamp(
      0,
      widget.media.isEmpty ? 0 : widget.media.length - 1,
    );
    widget.controller.addListener(_onMediaPageChanged);
    _videos = List<VideoPlayback?>.filled(
      widget.media.length,
      null,
      growable: false,
    );
  }

  @override
  void didUpdateWidget(covariant ReelMedia old) {
    super.didUpdateWidget(old);
    if (widget.isActive != old.isActive) _syncPlayback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onMediaPageChanged);
    _releaseVideos();
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
    final page = widget.controller.page?.round() ?? 0;
    if (page == _currentMediaIndex) return;
    setState(() => _currentMediaIndex = page);
    _syncPlayback();
  }

  void _initVideos() {
    if (_videosInitialized) return;
    _videosInitialized = true;
    for (int i = 0; i < widget.media.length; i++) {
      final m = widget.media[i];
      if (m.type != 'video' || m.url.isEmpty) continue;
      _videos[i] = VideoSource.of(m.url, streamUrl: m.streamUrl).load(
        onReady: (c) async {
          if (!mounted) return;
          await c.setLooping(true);
          if (!mounted) return;
          setState(() {});
          _syncPlayback();
        },
        onError: (_, _) {
          _videos[i]?.dispose();
          _videos[i] = null;
          if (!mounted) return;
          setState(() => _failedIndices.add(i));
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
    _failedIndices.clear();
  }

  void _syncPlayback() {
    if (!mounted) return;
    final shouldPlay = widget.isActive && _visibleFraction >= _playThreshold;
    final muted = context.read<VideoBloc>().state.isMuted;
    for (int i = 0; i < _videos.length; i++) {
      final c = _videos[i]?.controller;
      if (c == null || !c.value.isInitialized) continue;
      final active = shouldPlay &&
          i == _currentMediaIndex &&
          !_manuallyPaused.contains(i);
      if (active) {
        c.setVolume(muted ? 0 : 1);
        if (!c.value.isPlaying) c.play();
      } else if (c.value.isPlaying) {
        c.pause();
      }
    }
    _syncActiveVideo();
  }

  void _syncActiveVideo() {
    final notifier = widget.activeVideo;
    if (notifier == null) return;
    final vc = _currentController;
    notifier.value = (vc != null && vc.value.isInitialized) ? vc : null;
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

  void _onTapSlide(int index) {
    final c = _videos[index]?.controller;
    if (c == null || !c.value.isInitialized) return;
    final wasPlaying = c.value.isPlaying;
    setState(() {
      if (wasPlaying) {
        c.pause();
        _manuallyPaused.add(index);
      } else {
        c.play();
        _manuallyPaused.remove(index);
      }
    });
  }

  VideoPlayerController? get _currentController {
    if (_currentMediaIndex < 0 || _currentMediaIndex >= _videos.length) {
      return null;
    }
    return _videos[_currentMediaIndex]?.controller;
  }

  String? _backdropUrlFor(FeedMediaItem m) =>
      m.type == 'video' ? m.thumbnailUrl : m.url;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final media = widget.media;
    if (media.isEmpty) {
      return ColoredBox(color: c.mediaSurface);
    }

    final memWidth =
        (MediaQuery.of(context).size.width *
                MediaQuery.of(context).devicePixelRatio)
            .round();
    final current = media[_currentMediaIndex];
    final currentIsVideo = current.type == 'video';
    final showPauseBadge =
        currentIsVideo && _manuallyPaused.contains(_currentMediaIndex);
    final backdropUrl = _backdropUrlFor(current);

    return BlocListener<VideoBloc, VideoBlocState>(
      listenWhen: (_, curr) => curr is VideoToggledSound,
      listener: (_, _) => _syncPlayback(),
      child: VisibilityDetector(
        key: ValueKey('reel-media-${widget.sourceId}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: ReelBlurredBackdrop(
                  key: ValueKey(backdropUrl ?? 'idx-$_currentMediaIndex'),
                  url: backdropUrl,
                ),
              ),
            ),
            PageView.builder(
              controller: widget.controller,
              physics: media.length > 1
                  ? const BouncingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              itemCount: media.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTapSlide(index),
                  onDoubleTap: widget.onDoubleTapLike,
                  child: ReelMediaForeground(
                    media: media[index],
                    controller: _videos[index]?.controller,
                    failed: _failedIndices.contains(index),
                    memCacheWidth: memWidth,
                  ),
                );
              },
            ),
            if (showPauseBadge) const ReelPlayBadge(),
          ],
        ),
      ),
    );
  }
}
