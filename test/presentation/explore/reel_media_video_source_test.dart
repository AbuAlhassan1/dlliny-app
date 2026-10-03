import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/presentation/explore/widgets/reel/reel_media.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/fake_video_player.dart';

const _original = 'https://media.dlliny.com/posts/7f3a/clip.mp4';
const _stream =
    'https://video.dlliny.com/0b8e4c52-9f5e-4d3a-a1f0-6c2d7e9b1a44/playlist.m3u8';

void main() {
  late VideoPlayerRecorder players;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    players = VideoPlayerRecorder()..install();
  });

  void usePlayers(FakeInit Function(VideoSource source) initFor) {
    players.uninstall();
    players = VideoPlayerRecorder(initFor: initFor)..install();
  }

  tearDown(() {
    players.uninstall();
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
  });

  Future<void> pumpReel(WidgetTester tester, List<FeedMediaItem> media) async {
    final pages = PageController();
    addTearDown(pages.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: Themes.darkTheme,
        home: BlocProvider(
          create: (_) => VideoBloc(),
          child: Scaffold(
            body: ReelMedia(
              media: media,
              isActive: true,
              controller: pages,
              onDoubleTapLike: () {},
              sourceId: 'post-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a reel whose video has a Bunny stream plays it as HLS', (
    tester,
  ) async {
    await pumpReel(tester, const [
      FeedMediaItem(type: 'video', url: _original, streamUrl: _stream),
    ]);

    final player = players.created.single;
    expect(player.dataSource, _stream);
    expect(player.formatHint, VideoFormat.hls);
    expect(player.value.isPlaying, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(player),
    );
  });

  testWidgets('a reel whose stream is not ready plays the original file', (
    tester,
  ) async {
    await pumpReel(tester, const [
      FeedMediaItem(type: 'video', url: _original),
    ]);

    final player = players.created.single;
    expect(player.dataSource, _original);
    expect(player.formatHint, isNull);
    expect(player.value.isPlaying, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(player),
    );
  });

  testWidgets('each video slide of a carousel picks its own source', (
    tester,
  ) async {
    await pumpReel(tester, const [
      FeedMediaItem(type: 'video', url: _original, streamUrl: _stream),
      FeedMediaItem(
        type: 'video',
        url: 'https://media.dlliny.com/posts/7f3a/second.mov',
      ),
    ]);

    expect(players.created.map((p) => (p.dataSource, p.formatHint)), [
      (_stream, VideoFormat.hls),
      ('https://media.dlliny.com/posts/7f3a/second.mov', null),
    ]);
  });

  testWidgets('scrolling the reel away releases its players', (tester) async {
    await pumpReel(tester, const [
      FeedMediaItem(type: 'video', url: _original, streamUrl: _stream),
    ]);
    final player = players.created.single;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(player.disposed, isTrue);
  });

  group('when the stream won\'t play', () {
    const reel = [
      FeedMediaItem(type: 'video', url: _original, streamUrl: _stream),
    ];

    testWidgets('a stream that fails to load gives way to the original', (
      tester,
    ) async {
      usePlayers((s) => s.isStream ? FakeInit.fail : FakeInit.succeed);

      await pumpReel(tester, reel);

      expect(players.opened, [(_stream, VideoFormat.hls), (_original, null)]);
      final [stream, original] = players.created;
      expect(stream.disposed, isTrue);
      expect(original.value.isPlaying, isTrue);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(original),
      );
      expect(find.byIcon(TablerIcons.video_off), findsNothing);
    });

    testWidgets('a stream that errors before its first frame is replaced by '
        'the original', (tester) async {
      await pumpReel(tester, reel);
      final stream = players.created.single;

      stream.reportError('Segment 0 returned 403');
      await tester.pump();
      await tester.pump();

      expect(players.opened, [(_stream, VideoFormat.hls), (_original, null)]);
      final original = players.created.last;
      expect(stream.disposed, isTrue);
      expect(original.value.isPlaying, isTrue);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(original),
      );
    });

    testWidgets('when the original fails too, the slide shows it is '
        'unavailable — after one try each', (tester) async {
      usePlayers((_) => FakeInit.fail);

      await pumpReel(tester, reel);
      await tester.pump();

      expect(players.opened, [(_stream, VideoFormat.hls), (_original, null)]);
      expect(players.created.every((p) => p.disposed), isTrue);
      expect(find.byIcon(TablerIcons.video_off), findsOneWidget);
      expect(find.byType(VideoPlayer), findsNothing);
    });

    testWidgets('a failing original never tries a stream', (tester) async {
      usePlayers((_) => FakeInit.fail);

      await pumpReel(tester, const [
        FeedMediaItem(type: 'video', url: _original),
      ]);
      await tester.pump();

      expect(players.opened, [(_original, null)]);
      expect(find.byIcon(TablerIcons.video_off), findsOneWidget);
    });
  });
}
