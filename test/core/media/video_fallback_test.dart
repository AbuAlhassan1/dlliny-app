import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:video_player/video_player.dart';

import '../../helpers/fake_video_player.dart';

const _original = 'https://media.dlliny.com/posts/7f3a/clip.mp4';
const _stream =
    'https://video.dlliny.com/0b8e4c52-9f5e-4d3a-a1f0-6c2d7e9b1a44/playlist.m3u8';

final _streamSource = VideoSource.of(_original, streamUrl: _stream);
final _originalSource = VideoSource.of(_original);

const _openedStream = (_stream, VideoFormat.hls);
const _openedOriginal = (_original, null);

void main() {
  late VideoPlayerRecorder players;

  void installPlayers(VideoPlayerRecorder recorder) {
    players = recorder..install();
    addTearDown(players.uninstall);
  }

  final ready = <VideoPlayerController>[];
  final errors = <Object>[];

  setUp(() {
    ready.clear();
    errors.clear();
  });

  VideoPlayback load(VideoSource source, {Duration? timeout}) {
    final playback = source.load(
      onReady: ready.add,
      onError: (error, _) => errors.add(error),
      timeout: timeout,
    );
    addTearDown(playback.dispose);
    return playback;
  }

  group('VideoPlayback', () {
    test('a stream that initializes plays — nothing falls back', () async {
      installPlayers(VideoPlayerRecorder());

      final playback = load(_streamSource);
      await pumpEventQueue();

      expect(players.opened, [_openedStream]);
      expect(ready, [same(players.created.single)]);
      expect(playback.controller, same(players.created.single));
      expect(playback.source.isStream, isTrue);
      expect(errors, isEmpty);
    });

    test(
      'a stream that fails to initialize is dropped for the original',
      () async {
        installPlayers(VideoPlayerRecorder.failingStreams());

        final playback = load(_streamSource);
        await pumpEventQueue();

        expect(players.opened, [_openedStream, _openedOriginal]);
        final [stream, original] = players.created;
        expect(stream.disposed, isTrue);
        expect(ready, [same(original)]);
        expect(playback.controller, same(original));
        expect(playback.source, _originalSource);
        expect(errors, isEmpty);
      },
    );

    test(
      'an original that fails reports it — no stream is ever tried',
      () async {
        installPlayers(VideoPlayerRecorder(initFor: (_) => FakeInit.fail));

        load(_originalSource);
        await pumpEventQueue();

        expect(players.opened, [_openedOriginal]);
        expect(ready, isEmpty);
        expect(errors, hasLength(1));
      },
    );

    test('a stream and its original both failing: one try each, then the '
        'error — no loop', () async {
      installPlayers(VideoPlayerRecorder(initFor: (_) => FakeInit.fail));

      final playback = load(_streamSource);
      await pumpEventQueue();
      await pumpEventQueue();

      expect(players.opened, [_openedStream, _openedOriginal]);
      expect(ready, isEmpty);
      expect(errors, hasLength(1));
      expect(playback.controller, same(players.created.last));
      playback.dispose();
      expect(players.created.every((p) => p.disposed), isTrue);
    });

    test('a stream that errors before its first frame is swapped for the '
        'original once that one is ready', () async {
      installPlayers(VideoPlayerRecorder());

      final playback = load(_streamSource);
      await pumpEventQueue();
      final stream = players.created.single;

      stream.reportError('Segment 0 returned 403');
      await pumpEventQueue();

      expect(players.opened, [_openedStream, _openedOriginal]);
      final original = players.created.last;
      expect(ready, [same(stream), same(original)]);
      expect(playback.controller, same(original));
      expect(stream.disposed, isTrue);
      expect(errors, isEmpty);
    });

    test('an error once the stream has played is left to the screen', () async {
      installPlayers(VideoPlayerRecorder());

      final playback = load(_streamSource);
      await pumpEventQueue();
      final stream = players.created.single;

      await stream.seekTo(const Duration(milliseconds: 400));
      stream.reportError('connection lost');
      await pumpEventQueue();

      expect(players.opened, [_openedStream]);
      expect(playback.controller, same(stream));
      expect(stream.disposed, isFalse);
    });

    test(
      'disposed mid-load: nothing is called back, nothing falls back',
      () async {
        installPlayers(VideoPlayerRecorder.failingStreams());

        load(_streamSource).dispose();
        await pumpEventQueue();

        expect(players.opened, [_openedStream]);
        expect(players.created.single.disposed, isTrue);
        expect(ready, isEmpty);
        expect(errors, isEmpty);
      },
    );

    testWidgets('a stream that never starts gives way after '
        'streamStartTimeout', (tester) async {
      installPlayers(
        VideoPlayerRecorder(
          initFor: (s) => s.isStream ? FakeInit.hang : FakeInit.succeed,
        ),
      );

      final playback = load(_streamSource);
      await tester.pump(
        VideoSource.streamStartTimeout - const Duration(seconds: 1),
      );
      expect(players.opened, [_openedStream]);
      expect(ready, isEmpty);

      await tester.pump(const Duration(seconds: 2));
      expect(players.opened, [_openedStream, _openedOriginal]);
      expect(ready, [same(players.created.last)]);
      expect(playback.controller, same(players.created.last));
    });

    testWidgets('the original keeps the caller\'s own timeout', (tester) async {
      installPlayers(
        VideoPlayerRecorder(
          initFor: (s) => s.isStream ? FakeInit.fail : FakeInit.hang,
        ),
      );

      load(_streamSource, timeout: const Duration(minutes: 3));
      await tester.pump(const Duration(minutes: 2));
      expect(players.opened, [_openedStream, _openedOriginal]);
      expect(errors, isEmpty);

      await tester.pump(const Duration(minutes: 1, seconds: 1));
      expect(errors.single, isA<Exception>());
      expect(ready, isEmpty);
    });
  });

  group('initializeWithFallback', () {
    test('returns the stream\'s player when the stream initializes', () async {
      installPlayers(VideoPlayerRecorder());

      final controller = await _streamSource.initializeWithFallback();

      expect(players.opened, [_openedStream]);
      expect(controller, same(players.created.single));
      expect(controller.value.isInitialized, isTrue);
    });

    test('returns the original\'s player when the stream fails, disposing the '
        'stream\'s', () async {
      installPlayers(VideoPlayerRecorder.failingStreams());

      final controller = await _streamSource.initializeWithFallback();

      expect(players.opened, [_openedStream, _openedOriginal]);
      expect(controller, same(players.created.last));
      expect(players.created.first.disposed, isTrue);
    });

    test('throws once the original fails too — after one try each', () async {
      installPlayers(VideoPlayerRecorder(initFor: (_) => FakeInit.fail));

      await expectLater(
        _streamSource.initializeWithFallback(),
        throwsA(isA<Exception>()),
      );

      expect(players.opened, [_openedStream, _openedOriginal]);
      expect(players.created.every((p) => p.disposed), isTrue);
    });

    test(
      'an original that fails throws without trying anything else',
      () async {
        installPlayers(VideoPlayerRecorder(initFor: (_) => FakeInit.fail));

        await expectLater(
          _originalSource.initializeWithFallback(),
          throwsA(isA<Exception>()),
        );

        expect(players.opened, [_openedOriginal]);
        expect(players.created.single.disposed, isTrue);
      },
    );
  });
}
