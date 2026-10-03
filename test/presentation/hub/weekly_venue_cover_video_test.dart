import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/domain/dto/response/weekly_recommendations_response.dart';
import 'package:hangout/presentation/hub/controllers/weekly_venues/weekly_venues_bloc.dart';
import 'package:hangout/presentation/hub/widgets/weekly_venues/weekly_venue_card.dart';
import 'package:hangout/presentation/hub/widgets/weekly_venues_section.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../helpers/fake_video_player.dart';

const _stream =
    'https://video.dlliny.com/5d2f7a10-3c4b-4e8f-9a61-2b7c0d9e4f13/playlist.m3u8';

class _MockWeeklyVenuesBloc
    extends MockBloc<WeeklyVenuesEvent, WeeklyVenuesState>
    implements WeeklyVenuesBloc {}

WeeklyRecommendationItem _item(
  String venueId, {
  String? coverUrl,
  String? coverStreamUrl,
}) => WeeklyRecommendationItem(
  venueId: venueId,
  nameAr: 'مقهى',
  coverUrl: coverUrl,
  coverStreamUrl: coverStreamUrl,
  position: 0,
  score: 1,
  fallback: false,
);

void main() {
  late VideoPlayerRecorder players;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    players = VideoPlayerRecorder()..install();
  });

  tearDown(() {
    players.uninstall();
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 500,
    );
  });

  Widget host(Widget child) => MaterialApp(
    theme: Themes.lightTheme,
    home: Scaffold(body: child),
  );

  testWidgets('a weekly pick whose cover has a Bunny stream plays it as HLS, '
      'even when its URL has no video extension', (tester) async {
    await tester.pumpWidget(
      host(
        WeeklyVenueCard(
          item: _item(
            'v-1',
            coverUrl: 'https://media.dlliny.com/venues/v-1/cover',
            coverStreamUrl: _stream,
          ),
        ),
      ),
    );
    await tester.pump();

    final player = players.created.single;
    expect(player.dataSource, _stream);
    expect(player.formatHint, VideoFormat.hls);
    expect(player.value.isPlaying, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(player),
    );
  });

  testWidgets('a .mp4 weekly cover whose stream is not ready plays the file', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        WeeklyVenueCard(
          item: _item(
            'v-1',
            coverUrl: 'https://media.dlliny.com/venues/v-1/cover.mp4',
          ),
        ),
      ),
    );
    await tester.pump();

    final player = players.created.single;
    expect(player.dataSource, 'https://media.dlliny.com/venues/v-1/cover.mp4');
    expect(player.formatHint, isNull);
  });

  testWidgets('the rail gives its sound to the first video cover — '
      'a stream-only one included', (tester) async {
    final bloc = _MockWeeklyVenuesBloc();
    whenListen(
      bloc,
      const Stream<WeeklyVenuesState>.empty(),
      initialState: WeeklyVenuesLoaded(
        items: [
          _item('v-1'),
          _item(
            'v-2',
            coverUrl: 'https://media.dlliny.com/venues/v-2/cover',
            coverStreamUrl: _stream,
          ),
        ],
        weekStartsAt: '2026-09-28T00:00:00+03:00',
        isFallback: false,
      ),
    );

    await tester.pumpWidget(
      BlocProvider<WeeklyVenuesBloc>.value(
        value: bloc,
        child: host(const WeeklyVenuesSection()),
      ),
    );
    await tester.pumpAndSettle();

    final player = players.created.single;
    expect(player.dataSource, _stream);
    expect(player.value.volume, 1);
  });

  testWidgets('a weekly cover whose stream fails plays the original file', (
    tester,
  ) async {
    players.uninstall();
    players = VideoPlayerRecorder.failingStreams()..install();

    await tester.pumpWidget(
      host(
        WeeklyVenueCard(
          item: _item(
            'v-1',
            coverUrl: 'https://media.dlliny.com/venues/v-1/cover.mp4',
            coverStreamUrl: _stream,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(players.opened, [
      (_stream, VideoFormat.hls),
      ('https://media.dlliny.com/venues/v-1/cover.mp4', null),
    ]);
    final [stream, original] = players.created;
    expect(stream.disposed, isTrue);
    expect(original.value.isPlaying, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(original),
    );
  });
}
