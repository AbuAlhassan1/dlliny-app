import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/generated/codegen_loader.g.dart';
import 'package:hangout/presentation/venues_hub/widgets/venue_poster_card.dart';
import 'package:video_player/video_player.dart';

import '../../helpers/fake_video_player.dart';

const _stream =
    'https://video.dlliny.com/5d2f7a10-3c4b-4e8f-9a61-2b7c0d9e4f13/playlist.m3u8';

void main() {
  late VideoPlayerRecorder players;

  setUp(() => players = VideoPlayerRecorder()..install());
  tearDown(() => players.uninstall());

  Future<void> pumpCard(WidgetTester tester, VenuePosterCard card) async {
    EasyLocalization.logger.enableBuildModes = [];
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        assetLoader: const CodegenLoader(),
        startLocale: const Locale('ar'),
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            theme: Themes.lightTheme,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(body: Center(child: card)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a cover with a Bunny stream is a video and plays it as HLS, '
      'even when its URL has no video extension', (tester) async {
    await pumpCard(
      tester,
      const VenuePosterCard(
        venueId: 'v-1',
        nameAr: 'مقهى الشناشيل',
        coverUrl: 'https://media.dlliny.com/venues/v-1/cover',
        coverStreamUrl: _stream,
      ),
    );

    final player = players.created.single;
    expect(player.dataSource, _stream);
    expect(player.formatHint, VideoFormat.hls);
    expect(player.value.volume, 0);
    expect(player.value.isLooping, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(player),
    );
  });

  testWidgets('a .mp4 cover whose stream is not ready plays the original', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const VenuePosterCard(
        venueId: 'v-1',
        nameAr: 'مقهى الشناشيل',
        coverUrl: 'https://media.dlliny.com/venues/v-1/cover.mp4',
      ),
    );

    final player = players.created.single;
    expect(player.dataSource, 'https://media.dlliny.com/venues/v-1/cover.mp4');
    expect(player.formatHint, isNull);
  });

  testWidgets('a stream arriving on a refresh swaps the player over', (
    tester,
  ) async {
    const url = 'https://media.dlliny.com/venues/v-1/cover.mp4';
    await pumpCard(
      tester,
      const VenuePosterCard(venueId: 'v-1', nameAr: 'مقهى', coverUrl: url),
    );
    await pumpCard(
      tester,
      const VenuePosterCard(
        venueId: 'v-1',
        nameAr: 'مقهى',
        coverUrl: url,
        coverStreamUrl: _stream,
      ),
    );

    expect(players.created.map((p) => (p.dataSource, p.formatHint)), [
      (url, null),
      (_stream, VideoFormat.hls),
    ]);
    expect(players.created.first.disposed, isTrue);
  });

  testWidgets('a venue with no cover opens no player', (tester) async {
    await pumpCard(
      tester,
      const VenuePosterCard(venueId: 'v-1', nameAr: 'مقهى'),
    );

    expect(players.created, isEmpty);
    expect(find.byType(VideoPlayer), findsNothing);
  });

  testWidgets('a cover whose stream fails plays the original file instead', (
    tester,
  ) async {
    players.uninstall();
    players = VideoPlayerRecorder.failingStreams()..install();

    await pumpCard(
      tester,
      const VenuePosterCard(
        venueId: 'v-1',
        nameAr: 'مقهى الشناشيل',
        coverUrl: 'https://media.dlliny.com/venues/v-1/cover.mp4',
        coverStreamUrl: _stream,
      ),
    );

    expect(players.opened, [
      (_stream, VideoFormat.hls),
      ('https://media.dlliny.com/venues/v-1/cover.mp4', null),
    ]);
    final [stream, original] = players.created;
    expect(stream.disposed, isTrue);
    expect(original.value.isPlaying, isTrue);
    expect(original.value.volume, 0);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(original),
    );
  });
}
