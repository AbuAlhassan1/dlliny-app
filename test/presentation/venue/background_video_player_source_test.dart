import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/venue/widgets/background_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/fake_video_player.dart';
import '../../helpers/locale_test_helper.dart';
import '../../helpers/test_harness.dart';

const _original = 'https://media.dlliny.com/venues/v-1/cover.mp4';
const _stream =
    'https://video.dlliny.com/5d2f7a10-3c4b-4e8f-9a61-2b7c0d9e4f13/playlist.m3u8';

void main() {
  late VideoPlayerRecorder players;

  setUpAll(() => loadTestLocale('ar'));

  setUp(() async {
    await resetLocator();
    putSingleton<ApiService>(MockApiService());
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    players = VideoPlayerRecorder()..install();
  });

  tearDown(() async {
    players.uninstall();
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
    await resetLocator();
  });

  void usePlayers(FakeInit Function(VideoSource source) initFor) {
    players.uninstall();
    players = VideoPlayerRecorder(initFor: initFor)..install();
  }

  Future<void> pumpCover(WidgetTester tester, {String? streamUrl}) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AccessBloc(),
        child: MaterialApp(
          theme: Themes.lightTheme,
          home: Scaffold(
            body: Stack(
              children: [
                BackgroundVideoPlayer(
                  path: _original,
                  streamUrl: streamUrl,
                  venueId: 'v-1',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a venue video cover with a Bunny stream plays it as HLS', (
    tester,
  ) async {
    await pumpCover(tester, streamUrl: _stream);

    final player = players.created.single;
    expect(player.dataSource, _stream);
    expect(player.formatHint, VideoFormat.hls);
    expect(player.videoPlayerOptions, isNotNull);
    expect(player.value.isLooping, isTrue);
    expect(player.value.isPlaying, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(player),
    );
  });

  testWidgets('a venue video cover without a stream plays the original', (
    tester,
  ) async {
    await pumpCover(tester);

    final player = players.created.single;
    expect(player.dataSource, _original);
    expect(player.formatHint, isNull);
    expect(player.value.isPlaying, isTrue);
  });

  testWidgets('a stream arriving on a refresh does not restart the cover', (
    tester,
  ) async {
    await pumpCover(tester);
    await pumpCover(tester, streamUrl: _stream);

    final player = players.created.single;
    expect(player.dataSource, _original);
    expect(player.disposed, isFalse);
  });

  group('when the stream won\'t play', () {
    testWidgets('the first attempt hands over to the original at once', (
      tester,
    ) async {
      usePlayers((s) => s.isStream ? FakeInit.fail : FakeInit.succeed);

      await pumpCover(tester, streamUrl: _stream);
      await tester.pump();

      expect(players.opened, [(_stream, VideoFormat.hls), (_original, null)]);
      final original = players.created.last;
      expect(original.value.isPlaying, isTrue);
      expect(original.value.isLooping, isTrue);
      expect(original.videoPlayerOptions, isNotNull);
      expect(find.byIcon(Icons.refresh), findsNothing);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(original),
      );
    });

    testWidgets('the stream gets one try; the original keeps its three '
        'attempts; a retry never goes back to the stream', (tester) async {
      usePlayers((_) => FakeInit.fail);

      await pumpCover(tester, streamUrl: _stream);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(players.opened, [
        (_stream, VideoFormat.hls),
        (_original, null),
        (_original, null),
        (_original, null),
      ]);
      expect(players.created.every((p) => p.disposed), isTrue);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();
      expect(players.opened.last, (_original, null));
      expect(players.opened, hasLength(5));

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
    });

    testWidgets('a stream that never starts gives way after '
        'streamStartTimeout, not the 3-minute attempt timeout', (tester) async {
      usePlayers((s) => s.isStream ? FakeInit.hang : FakeInit.succeed);

      await pumpCover(tester, streamUrl: _stream);
      await tester.pump(VideoSource.streamStartTimeout);
      await tester.pump();

      expect(players.opened, [(_stream, VideoFormat.hls), (_original, null)]);
      expect(players.created.last.value.isPlaying, isTrue);
    });
  });
}
