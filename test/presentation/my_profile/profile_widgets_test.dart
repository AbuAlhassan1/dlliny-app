import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/hangouts_grid.dart';
import 'package:hangout/presentation/my_profile/widgets/posts_grid.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';

import '../../helpers/test_harness.dart';

class FakeMyPostsBloc extends MockBloc<MyPostsEvent, MyPostsState>
    implements MyPostsBloc {
  @override
  PagedResponse<PostResponse>? myPosts;
}

class FakeMyHangoutsBloc extends MockBloc<MyHangoutsEvent, MyHangoutsState>
    implements MyHangoutsBloc {
  @override
  List<HangoutResponse> myHangouts = [];
}

void main() {
  late MockApiService api;

  setUp(() async {
    api = MockApiService();
    await resetLocator();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  Widget host(Widget child) =>
      MaterialApp(theme: Themes.lightTheme, home: Scaffold(body: child));

  group('UserAvatar', () {
    testWidgets('falls back to the person glyph when there is no url', (
      tester,
    ) async {
      await tester.pumpWidget(host(const UserAvatar(avatarUrl: null)));
      await tester.pump();

      expect(find.byIcon(TablerIcons.user), findsOneWidget);
    });

    testWidgets('treats an empty url as "no avatar"', (tester) async {
      await tester.pumpWidget(host(const UserAvatar(avatarUrl: '')));
      await tester.pump();

      expect(find.byIcon(TablerIcons.user), findsOneWidget);
    });

    testWidgets('honours the requested size', (tester) async {
      await tester.pumpWidget(
        host(const UserAvatar(avatarUrl: null, size: 42)),
      );
      await tester.pump();

      final box = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(TablerIcons.user),
              matching: find.byType(Container),
            )
            .last,
      );
      expect(box.constraints?.maxWidth ?? 42, 42);
    });
  });

  group('PostsGrid', () {
    late FakeMyPostsBloc bloc;

    setUp(() => bloc = FakeMyPostsBloc());
    tearDown(() => bloc.close());

    Widget grid() => host(
      BlocProvider<MyPostsBloc>.value(value: bloc, child: const PostsGrid()),
    );

    testWidgets('shows a spinner while loading', (tester) async {
      whenListen(
        bloc,
        const Stream<MyPostsState>.empty(),
        initialState: MyPostsLoading(),
      );

      await tester.pumpWidget(grid());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error message', (tester) async {
      whenListen(
        bloc,
        const Stream<MyPostsState>.empty(),
        initialState: MyPostsError('could not load'),
      );

      await tester.pumpWidget(grid());
      await tester.pump();

      expect(find.text('could not load'), findsOneWidget);
    });

    testWidgets('shows the empty state when there are no posts', (
      tester,
    ) async {
      whenListen(
        bloc,
        const Stream<MyPostsState>.empty(),
        initialState: MyPostsLoaded(),
      );

      await tester.pumpWidget(grid());
      await tester.pump();

      expect(find.text('No posts yet'), findsOneWidget);
    });
  });

  group('HangoutsGrid', () {
    late FakeMyHangoutsBloc bloc;

    setUp(() => bloc = FakeMyHangoutsBloc());
    tearDown(() => bloc.close());

    Widget grid() => host(
      BlocProvider<MyHangoutsBloc>.value(
        value: bloc,
        child: const HangoutsGrid(),
      ),
    );

    testWidgets('shows a spinner while loading', (tester) async {
      whenListen(
        bloc,
        const Stream<MyHangoutsState>.empty(),
        initialState: MyHangoutsLoading(),
      );

      await tester.pumpWidget(grid());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error message', (tester) async {
      whenListen(
        bloc,
        const Stream<MyHangoutsState>.empty(),
        initialState: MyHangoutsError('offline'),
      );

      await tester.pumpWidget(grid());
      await tester.pump();

      expect(find.text('offline'), findsOneWidget);
    });
  });
}
