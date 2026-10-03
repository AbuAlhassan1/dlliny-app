import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/post_details_page_wrapper.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';

import '../../helpers/fake_video_player.dart';
import '../../helpers/locale_test_helper.dart';
import '../../helpers/test_harness.dart';

const _original = 'https://media.dlliny.com/posts/7f3a/clip.mp4';
const _stream =
    'https://video.dlliny.com/0b8e4c52-9f5e-4d3a-a1f0-6c2d7e9b1a44/playlist.m3u8';

PostResponse _postWith(List<MediaItem> media) => PostResponse(
  id: 'post-1',
  author: const AuthorInfo(id: 'user-1', username: 'hassan'),
  likesCount: 0,
  commentsCount: 0,
  likedByMe: false,
  mine: false,
  media: media,
  userMentions: const [],
  venueMentions: const [],
  createdAt: kTestTimestamp,
);

void main() {
  late VideoPlayerRecorder players;

  setUpAll(() => loadTestLocale('ar'));

  setUp(() async {
    await resetLocator();
    final api = MockApiService();
    when(
      () => api.getComments(
        any(),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => apiOk(paged(<CommentResponse>[])));
    putSingleton<ApiService>(api);
    players = VideoPlayerRecorder()..install();
  });

  tearDown(() async {
    players.uninstall();
    await resetLocator();
  });

  Future<void> pumpDetails(WidgetTester tester, PostResponse post) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: Themes.lightTheme,
        home: BlocProvider(
          create: (_) => PostInteractionsBloc(),
          child: PostDetailsPageWrapper(post: post),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'opening a post creates one player — the visible slide\'s — on its stream',
    (tester) async {
      await pumpDetails(
        tester,
        _postWith(const [
          MediaItem(
            url: _original,
            mediaType: 'video',
            sortOrder: 0,
            streamUrl: _stream,
          ),
          MediaItem(
            url: 'https://media.dlliny.com/posts/7f3a/second.mp4',
            mediaType: 'video',
            sortOrder: 1,
          ),
        ]),
      );

      final player = players.created.single;
      expect(player.dataSource, _stream);
      expect(player.formatHint, VideoFormat.hls);
      expect(
        tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
        same(player),
      );
    },
  );

  testWidgets('a post video without a stream yet plays the original', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      _postWith(const [
        MediaItem(url: _original, mediaType: 'video', sortOrder: 0),
      ]),
    );

    final player = players.created.single;
    expect(player.dataSource, _original);
    expect(player.formatHint, isNull);
  });

  testWidgets('leaving the page disposes the only player', (tester) async {
    await pumpDetails(
      tester,
      _postWith(const [
        MediaItem(
          url: _original,
          mediaType: 'video',
          sortOrder: 0,
          streamUrl: _stream,
        ),
      ]),
    );
    final player = players.created.single;

    await tester.pumpWidget(const SizedBox.shrink());

    expect(player.disposed, isTrue);
  });

  testWidgets('a post video whose stream fails plays the original instead', (
    tester,
  ) async {
    players.uninstall();
    players = VideoPlayerRecorder.failingStreams()..install();

    await pumpDetails(
      tester,
      _postWith(const [
        MediaItem(
          url: _original,
          mediaType: 'video',
          sortOrder: 0,
          streamUrl: _stream,
        ),
      ]),
    );
    await tester.pump();

    expect(players.opened, [(_stream, VideoFormat.hls), (_original, null)]);
    final [stream, original] = players.created;
    expect(stream.disposed, isTrue);
    expect(original.value.isLooping, isTrue);
    expect(original.value.isPlaying, isTrue);
    expect(
      tester.widget<VideoPlayer>(find.byType(VideoPlayer)).controller,
      same(original),
    );
  });
}
