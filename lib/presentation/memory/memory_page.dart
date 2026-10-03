import 'dart:async';
import 'dart:developer';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_viewer/memory_viewer_bloc.dart';
import 'package:hangout/presentation/memory/widgets/memory_user_view.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class MemoryPage extends StatelessWidget {
  final List<MemoryTrayBucket> buckets;
  final int initialBucketIndex;

  const MemoryPage({
    super.key,
    required this.buckets,
    this.initialBucketIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemoryViewerBloc>(
      create: (_) => MemoryViewerBloc(
        repository: serviceLocator.get<MemoryRepository>(),
        trayBloc: serviceLocator.get<MemoryTrayBloc>(),
        buckets: buckets,
        initialBucketIndex: initialBucketIndex,
      )..add(ViewerOpened()),
      child: const _MemoryViewerSurface(),
    );
  }
}

class _MemoryViewerSurface extends StatefulWidget {
  const _MemoryViewerSurface();

  @override
  State<_MemoryViewerSurface> createState() => _MemoryViewerSurfaceState();
}

class _MemoryViewerSurfaceState extends State<_MemoryViewerSurface>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _staticMemoryDuration = Duration(seconds: 5);
  static const Duration _maxVideoDuration = Duration(seconds: 60);

  late final PageController _bucketController;
  late final AnimationController _progress;

  VideoPlayerController? _video;
  AudioPlayer? _audio;

  String? _activeMemoryId;

  String? _completionFiredFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final initial = context.read<MemoryViewerBloc>().state.bucketIndex;
    _bucketController = PageController(initialPage: initial);

    _progress = AnimationController(vsync: this, duration: _staticMemoryDuration)
      ..addStatusListener(_onProgressStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _configureForActiveMemory();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.removeStatusListener(_onProgressStatus);
    _progress.dispose();
    _video?.dispose();
    _audio?.dispose();
    _bucketController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final blocPaused = context.read<MemoryViewerBloc>().state.isPaused;
      if (!blocPaused) _playControllers();
    } else {
      _pauseControllers();
    }
  }

  void _onClose() {
    context.read<MemoryViewerBloc>().add(ViewerClosed());
    Navigator.of(context).pop();
  }

  Future<void> _configureForActiveMemory() async {
    final state = context.read<MemoryViewerBloc>().state;
    final memory = state.currentMemory;
    if (_activeMemoryId == memory.id) return;
    _activeMemoryId = memory.id;
    _completionFiredFor = null;

    final pausedAtStart = state.isPaused;

    _progress.stop();
    _progress.value = 0;

    final prevVideo = _video;
    _video = null;
    setState(() {});
    await prevVideo?.dispose();

    final prevAudio = _audio;
    _audio = null;
    unawaited(prevAudio?.dispose() ?? Future<void>.value());

    if (memory.contentType == MemoryContentType.video) {
      await Future.wait([
        _prepareVideo(memory),
        _prepareAudio(memory, pausedAtStart: pausedAtStart),
      ]);
    } else {
      _progress.duration = _staticMemoryDuration;
      _maybeStart();
      await _prepareAudio(memory, pausedAtStart: pausedAtStart);
    }
  }

  Future<void> _prepareAudio(
    MemoryResponse memory, {
    required bool pausedAtStart,
  }) async {
    final url = memory.audioUrl;
    if (url == null || url.isEmpty) return;

    final memoryId = memory.id;
    final player = AudioPlayer();
    try {
      await player.setUrl(url);
    } catch (e) {
      log('memory: audio init failed for $memoryId: $e');
      await player.dispose();
      return;
    }
    if (!mounted || _activeMemoryId != memoryId) {
      await player.dispose();
      return;
    }
    await player.setLoopMode(LoopMode.off);
    _audio = player;

    final stillPaused = !mounted
        ? true
        : context.read<MemoryViewerBloc>().state.isPaused;
    if (!pausedAtStart && !stillPaused) {
      await player.play();
    }
  }

  Future<void> _prepareVideo(MemoryResponse memory) async {
    final url = memory.mediaUrl;
    if (url == null || url.isEmpty) {
      _progress.duration = _staticMemoryDuration;
      _maybeStart();
      return;
    }

    final memoryId = memory.id;
    final VideoPlayerController controller;
    try {
      controller = await VideoSource.of(
        url,
        streamUrl: memory.mediaStreamUrl,
      ).initializeWithFallback();
    } catch (e) {
      log('memory: video initialize failed for $memoryId: $e');
      if (!mounted || _activeMemoryId != memoryId) return;
      _progress.duration = _staticMemoryDuration;
      _maybeStart();
      return;
    }

    if (!mounted || _activeMemoryId != memoryId) {
      await controller.dispose();
      return;
    }

    await controller.setLooping(false);
    final natural = controller.value.duration;
    final clamped = natural > _maxVideoDuration ? _maxVideoDuration : natural;
    _progress.duration = clamped.inMilliseconds > 0 ? clamped : _staticMemoryDuration;
    _video = controller;
    setState(() {});

    _maybeStart();
  }

  void _maybeStart() {
    final paused = context.read<MemoryViewerBloc>().state.isPaused;
    if (paused) return;
    _playControllers();
  }

  void _playControllers() {
    if (_progress.status != AnimationStatus.forward &&
        _progress.status != AnimationStatus.completed) {
      _progress.forward();
    }
    final video = _video;
    if (video != null && video.value.isInitialized && !video.value.isPlaying) {
      video.play();
    }
    final audio = _audio;
    if (audio != null && !audio.playing) {
      unawaited(audio.play());
    }
  }

  void _pauseControllers() {
    if (_progress.isAnimating) _progress.stop();
    final video = _video;
    if (video != null && video.value.isInitialized && video.value.isPlaying) {
      video.pause();
    }
    final audio = _audio;
    if (audio != null && audio.playing) {
      unawaited(audio.pause());
    }
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final id = _activeMemoryId;
    if (id == null || _completionFiredFor == id) return;
    _completionFiredFor = id;
    if (!mounted) return;
    context.read<MemoryViewerBloc>().add(NextMemory());
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      onDismissed: _onClose,
      direction: DismissiblePageDismissDirection.down,
      isFullScreen: true,
      child: Scaffold(
        backgroundColor: context.c.background,
        body: MultiBlocListener(
          listeners: [
            BlocListener<MemoryViewerBloc, MemoryViewerState>(
              listenWhen: (prev, curr) =>
                  curr.status == MemoryViewerStatus.shouldClose &&
                  prev.status != MemoryViewerStatus.shouldClose,
              listener: (_, _) => _onClose(),
            ),
            BlocListener<MemoryViewerBloc, MemoryViewerState>(
              listenWhen: (prev, curr) =>
                  prev.bucketIndex != curr.bucketIndex ||
                  prev.memoryIndex != curr.memoryIndex ||
                  prev.buckets != curr.buckets,
              listener: (_, _) => _configureForActiveMemory(),
            ),
            BlocListener<MemoryViewerBloc, MemoryViewerState>(
              listenWhen: (prev, curr) => prev.isPaused != curr.isPaused,
              listener: (_, state) =>
                  state.isPaused ? _pauseControllers() : _playControllers(),
            ),
          ],
          child: BlocBuilder<MemoryViewerBloc, MemoryViewerState>(
            buildWhen: (prev, curr) =>
                prev.bucketIndex != curr.bucketIndex ||
                prev.buckets.length != curr.buckets.length,
            builder: (context, state) {
              _syncControllerToBloc(state.bucketIndex);
              return PageView.builder(
                controller: _bucketController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) =>
                    context.read<MemoryViewerBloc>().add(BucketSwiped(i)),
                itemCount: state.buckets.length,
                itemBuilder: (context, bucketIdx) {
                  final isActive = bucketIdx == state.bucketIndex;
                  return MemoryUserView(
                    bucket: state.buckets[bucketIdx],
                    isActiveBucket: isActive,
                    onClose: _onClose,
                    activeAnimation: isActive ? _progress : null,
                    activeVideoController: isActive ? _video : null,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _syncControllerToBloc(int desiredIndex) {
    if (!_bucketController.hasClients) return;
    final current =
        _bucketController.page?.round() ?? _bucketController.initialPage;
    if (current == desiredIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_bucketController.hasClients) return;
      _bucketController.animateToPage(
        desiredIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }
}
