import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:video_player/video_player.dart';

import '../../helpers/fake_video_player.dart';

const _original = 'https://media.dlliny.com/posts/7f3a/clip.mp4';
const _stream =
    'https://video.dlliny.com/0b8e4c52-9f5e-4d3a-a1f0-6c2d7e9b1a44/playlist.m3u8';

void main() {
  group('VideoSource.of picks what to play', () {
    test('the Bunny stream, as HLS, once the backend has one', () {
      final source = VideoSource.of(_original, streamUrl: _stream);

      expect(source.uri, Uri.parse(_stream));
      expect(source.formatHint, VideoFormat.hls);
      expect(source.isStream, isTrue);
    });

    test('the original, with no format hint, while the stream is null', () {
      final source = VideoSource.of(_original, streamUrl: null);

      expect(source.uri, Uri.parse(_original));
      expect(source.formatHint, isNull);
      expect(source.isStream, isFalse);
    });

    test('the original when no stream is passed at all', () {
      expect(
        VideoSource.of(_original),
        VideoSource.of(_original, streamUrl: null),
      );
    });

    test('the original when the stream is empty or blank', () {
      for (final blank in ['', '   ', '\n']) {
        final source = VideoSource.of(_original, streamUrl: blank);

        expect(source.uri, Uri.parse(_original), reason: 'streamUrl: "$blank"');
        expect(source.formatHint, isNull, reason: 'streamUrl: "$blank"');
      }
    });

    test('a stream padded with whitespace is trimmed, not discarded', () {
      final source = VideoSource.of(_original, streamUrl: '  $_stream\n');

      expect(source.uri, Uri.parse(_stream));
      expect(source.isStream, isTrue);
    });

    test('sources compare by what they play and fall back to', () {
      expect(
        VideoSource.of(_original, streamUrl: _stream),
        VideoSource.of(_original, streamUrl: _stream),
      );
      expect(
        VideoSource.of(_original, streamUrl: _stream),
        isNot(VideoSource.of(_original)),
      );
      expect(
        VideoSource.of(_original, streamUrl: _stream),
        isNot(
          VideoSource.of(
            'https://media.dlliny.com/other.mp4',
            streamUrl: _stream,
          ),
        ),
      );
    });

    test('a stream falls back to its original; an original to nothing', () {
      final stream = VideoSource.of(_original, streamUrl: _stream);

      expect(stream.fallback, VideoSource.of(_original));
      expect(stream.fallback!.isStream, isFalse);
      expect(stream.fallback!.fallback, isNull);
      expect(VideoSource.of(_original).fallback, isNull);
    });

    test('a stream without an original has nothing to fall back to', () {
      expect(VideoSource.of('', streamUrl: _stream).fallback, isNull);
      expect(VideoSource.of('  ', streamUrl: _stream).fallback, isNull);
    });
  });

  group('createController', () {
    test('builds a network player carrying the HLS hint for a stream', () {
      final controller = VideoSource.of(
        _original,
        streamUrl: _stream,
      ).createController();
      addTearDown(controller.dispose);

      expect(controller.dataSourceType, DataSourceType.network);
      expect(controller.dataSource, _stream);
      expect(controller.formatHint, VideoFormat.hls);
    });

    test('builds a network player with no hint for the original', () {
      final controller = VideoSource.of(_original).createController();
      addTearDown(controller.dispose);

      expect(controller.dataSourceType, DataSourceType.network);
      expect(controller.dataSource, _original);
      expect(controller.formatHint, isNull);
    });

    test('passes player options through', () {
      final options = VideoPlayerOptions(mixWithOthers: true);
      final controller = VideoSource.of(
        _original,
      ).createController(videoPlayerOptions: options);
      addTearDown(controller.dispose);

      expect(controller.videoPlayerOptions, same(options));
    });

    test('goes through the swappable factory', () {
      final recorder = VideoPlayerRecorder()..install();
      addTearDown(recorder.uninstall);

      final source = VideoSource.of(_original, streamUrl: _stream);
      final controller = source.createController();
      addTearDown(controller.dispose);

      expect(recorder.created, [same(controller)]);
      expect(recorder.created.single.source, source);
    });
  });

  group('isVideoCover (card payloads without coverMediaType)', () {
    test('a Bunny stream makes the cover a video, whatever the URL', () {
      for (final url in [
        'https://media.dlliny.com/venues/v-1/cover',
        'https://media.dlliny.com/venues/v-1/cover.jpg',
        null,
      ]) {
        expect(
          isVideoCover(coverUrl: url, coverStreamUrl: _stream),
          isTrue,
          reason: 'coverUrl: $url',
        );
      }
    });

    test('without a stream, a video extension still marks a video', () {
      for (final url in [
        'https://media.dlliny.com/venues/v-1/cover.mp4',
        'https://media.dlliny.com/venues/v-1/COVER.MOV',
        'https://media.dlliny.com/venues/v-1/cover.m4v',
        'https://media.dlliny.com/venues/v-1/cover.webm',
        'https://media.dlliny.com/venues/v-1/cover.mp4?v=2#t=1',
      ]) {
        expect(isVideoCover(coverUrl: url), isTrue, reason: url);
      }
    });

    test('images and missing covers are not videos', () {
      for (final url in [
        'https://media.dlliny.com/venues/v-1/cover.jpg',
        'https://media.dlliny.com/venues/v-1/cover.webp',
        'https://media.dlliny.com/venues/v-1/cover.gif',
        'https://media.dlliny.com/venues/v-1/cover',
        '',
        null,
      ]) {
        expect(isVideoCover(coverUrl: url), isFalse, reason: 'coverUrl: $url');
      }
    });

    test('a blank stream falls back to the extension', () {
      expect(
        isVideoCover(
          coverUrl: 'https://media.dlliny.com/venues/v-1/cover.jpg',
          coverStreamUrl: '  ',
        ),
        isFalse,
      );
      expect(
        isVideoCover(
          coverUrl: 'https://media.dlliny.com/venues/v-1/cover.mp4',
          coverStreamUrl: '',
        ),
        isTrue,
      );
    });
  });
}
