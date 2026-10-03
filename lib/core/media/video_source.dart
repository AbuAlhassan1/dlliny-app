import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

typedef VideoControllerFactory =
    VideoPlayerController Function(
      VideoSource source, {
      VideoPlayerOptions? videoPlayerOptions,
    });

@immutable
class VideoSource {
  const VideoSource._(this.uri, this.formatHint, [this.fallback]);

  factory VideoSource.of(String url, {String? streamUrl}) {
    final original = VideoSource._(Uri.parse(url), null);
    final stream = streamUrl?.trim() ?? '';
    if (stream.isEmpty) return original;
    return VideoSource._(
      Uri.parse(stream),
      VideoFormat.hls,
      url.trim().isEmpty ? null : original,
    );
  }

  static const Duration streamStartTimeout = Duration(seconds: 20);

  final Uri uri;

  final VideoFormat? formatHint;

  final VideoSource? fallback;

  bool get isStream => formatHint == VideoFormat.hls;

  VideoPlayerController createController({
    VideoPlayerOptions? videoPlayerOptions,
  }) => controllerFactory(this, videoPlayerOptions: videoPlayerOptions);

  Future<VideoPlayerController> initializeWithFallback({
    VideoPlayerOptions? videoPlayerOptions,
    Duration? timeout,
  }) async {
    final controller = createController(videoPlayerOptions: videoPlayerOptions);
    try {
      await _initialize(controller, _limitFor(timeout));
      return controller;
    } catch (error) {
      unawaited(controller.dispose());
      final original = fallback;
      if (original == null) rethrow;
      _logFallback(error);
      return original.initializeWithFallback(
        videoPlayerOptions: videoPlayerOptions,
        timeout: timeout,
      );
    }
  }

  VideoPlayback load({
    required FutureOr<void> Function(VideoPlayerController controller) onReady,
    void Function(Object error, StackTrace stackTrace)? onError,
    VideoPlayerOptions? videoPlayerOptions,
    Duration? timeout,
  }) => VideoPlayback._(
    this,
    onReady: onReady,
    onError: onError,
    videoPlayerOptions: videoPlayerOptions,
    timeout: timeout,
  );

  @visibleForTesting
  static VideoControllerFactory controllerFactory = networkController;

  static VideoPlayerController networkController(
    VideoSource source, {
    VideoPlayerOptions? videoPlayerOptions,
  }) => VideoPlayerController.networkUrl(
    source.uri,
    formatHint: source.formatHint,
    videoPlayerOptions: videoPlayerOptions,
  );

  Duration? _limitFor(Duration? timeout) {
    if (!isStream) return timeout;
    return timeout != null && timeout < streamStartTimeout
        ? timeout
        : streamStartTimeout;
  }

  static Future<void> _initialize(
    VideoPlayerController controller,
    Duration? limit,
  ) {
    final initialized = controller.initialize();
    return limit == null ? initialized : initialized.timeout(limit);
  }

  void _logFallback(Object error) => developer.log(
    'Stream $uri failed ($error); playing the original ${fallback?.uri}',
    name: 'VideoSource',
  );

  @override
  bool operator ==(Object other) =>
      other is VideoSource &&
      other.uri == uri &&
      other.formatHint == formatHint &&
      other.fallback == fallback;

  @override
  int get hashCode => Object.hash(uri, formatHint, fallback);

  @override
  String toString() => 'VideoSource($uri${isStream ? ', hls' : ''})';
}

class VideoPlayback {
  VideoPlayback._(
    VideoSource source, {
    required this.onReady,
    this.onError,
    this.videoPlayerOptions,
    this.timeout,
  }) : _source = source,
       _controller = source.createController(
         videoPlayerOptions: videoPlayerOptions,
       ) {
    unawaited(_start());
  }

  final FutureOr<void> Function(VideoPlayerController controller) onReady;

  final void Function(Object error, StackTrace stackTrace)? onError;

  final VideoPlayerOptions? videoPlayerOptions;

  final Duration? timeout;

  VideoSource _source;
  VideoPlayerController _controller;

  VideoPlayerController? _replacement;
  bool _watchingStream = false;
  bool _disposed = false;

  VideoPlayerController get controller => _controller;

  VideoSource get source => _source;

  bool get isDisposed => _disposed;

  bool get _canFallBack => _source.fallback != null;

  Future<void> _start() async {
    final first = _controller;
    try {
      await VideoSource._initialize(first, _source._limitFor(timeout));
    } catch (error, stackTrace) {
      if (_disposed) return;
      if (_canFallBack) {
        await _fallBack(error, started: false);
      } else {
        _fail(_source, error, stackTrace);
      }
      return;
    }
    if (_disposed) return;
    if (_canFallBack) _watchStream();
    await onReady(first);
  }

  void _watchStream() {
    _watchingStream = true;
    _controller.addListener(_onStreamValue);
  }

  void _stopWatchingStream() {
    if (!_watchingStream) return;
    _watchingStream = false;
    _controller.removeListener(_onStreamValue);
  }

  void _onStreamValue() {
    final value = _controller.value;
    if (value.position > Duration.zero) {
      _stopWatchingStream();
    } else if (value.hasError) {
      _stopWatchingStream();
      unawaited(
        _fallBack(
          value.errorDescription ?? 'error before the first frame',
          started: true,
        ),
      );
    }
  }

  Future<void> _fallBack(Object streamError, {required bool started}) async {
    final stream = _source;
    final original = stream.fallback!;
    stream._logFallback(streamError);
    final failed = _controller;
    final replacement = original.createController(
      videoPlayerOptions: videoPlayerOptions,
    );
    if (started) {
      _replacement = replacement;
    } else {
      _controller = replacement;
      _source = original;
      unawaited(failed.dispose());
    }
    try {
      await VideoSource._initialize(replacement, timeout);
    } catch (error, stackTrace) {
      if (_disposed) return;
      if (started) {
        _replacement = null;
        unawaited(replacement.dispose());
      }
      _fail(original, error, stackTrace);
      return;
    }
    if (_disposed) return;
    if (started) {
      _replacement = null;
      _controller = replacement;
      _source = original;
    }
    try {
      await onReady(replacement);
    } finally {
      if (started) unawaited(failed.dispose());
    }
  }

  void _fail(VideoSource failed, Object error, StackTrace stackTrace) {
    final report = onError;
    if (report != null) {
      report(error, stackTrace);
    } else {
      developer.log(
        'Video ${failed.uri} failed to load: $error',
        name: 'VideoSource',
      );
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _stopWatchingStream();
    unawaited(_controller.dispose());
    final replacement = _replacement;
    _replacement = null;
    if (replacement != null) unawaited(replacement.dispose());
  }
}

bool isVideoCover({String? coverUrl, String? coverStreamUrl}) {
  if (coverStreamUrl != null && coverStreamUrl.trim().isNotEmpty) {
    return true;
  }
  if (coverUrl == null || coverUrl.isEmpty) return false;
  final path = coverUrl.split('?').first.split('#').first.toLowerCase();
  return _videoExtensions.any(path.endsWith);
}

const _videoExtensions = ['.mp4', '.mov', '.m4v', '.webm'];
