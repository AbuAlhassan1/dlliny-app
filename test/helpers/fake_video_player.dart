import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/services.dart' show PlatformException;
import 'package:hangout/core/media/video_source.dart';
import 'package:video_player/video_player.dart';

enum FakeInit {
  succeed,

  fail,

  hang,
}

class FakeVideoPlayerController extends VideoPlayerController {
  FakeVideoPlayerController(
    this.source, {
    this.init = FakeInit.succeed,
    super.videoPlayerOptions,
  }) : super.networkUrl(source.uri, formatHint: source.formatHint);

  final VideoSource source;

  final FakeInit init;

  bool disposed = false;

  @override
  Future<void> initialize() async {
    switch (init) {
      case FakeInit.succeed:
        value = value.copyWith(
          isInitialized: true,
          duration: const Duration(seconds: 8),
          size: const Size(1080, 1920),
        );
      case FakeInit.fail:
        throw PlatformException(
          code: 'VideoError',
          message: 'Video player had error: ${source.uri} unreachable',
        );
      case FakeInit.hang:
        await Completer<void>().future;
    }
  }

  void reportError(String description) {
    value = VideoPlayerValue.erroneous(description);
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async => value = value.copyWith(isPlaying: false);

  @override
  Future<void> setLooping(bool looping) async =>
      value = value.copyWith(isLooping: looping);

  @override
  Future<void> setVolume(double volume) async =>
      value = value.copyWith(volume: volume);

  @override
  Future<void> seekTo(Duration position) async =>
      value = value.copyWith(position: position);

  @override
  Future<void> setPlaybackSpeed(double speed) async =>
      value = value.copyWith(playbackSpeed: speed);

  @override
  Future<Duration?> get position async => value.position;

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

class VideoPlayerRecorder {
  VideoPlayerRecorder({this.initFor});

  VideoPlayerRecorder.failingStreams()
    : initFor = ((source) =>
          source.isStream ? FakeInit.fail : FakeInit.succeed);

  final FakeInit Function(VideoSource source)? initFor;

  final List<FakeVideoPlayerController> created = [];

  List<(String, VideoFormat?)> get opened => [
    for (final c in created) (c.dataSource, c.formatHint),
  ];

  void install() {
    VideoSource.controllerFactory = (source, {videoPlayerOptions}) {
      final controller = FakeVideoPlayerController(
        source,
        init: initFor?.call(source) ?? FakeInit.succeed,
        videoPlayerOptions: videoPlayerOptions,
      );
      created.add(controller);
      return controller;
    };
  }

  void uninstall() {
    VideoSource.controllerFactory = VideoSource.networkController;
  }
}
