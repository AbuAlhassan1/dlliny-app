import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:hangout/presentation/my_profile/controller/followers_following/followers_following_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

void main() {
  late MockApiService api;

  setUp(() async {
    api = MockApiService();
    await resetLocator();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  void stubFollowers(PagedResponse<UserSummaryResponse> page) => when(
    () =>
        api.getMyFollowers(page: any(named: 'page'), size: any(named: 'size')),
  ).thenAnswer((_) async => apiOk(page));

  void stubFollowing(PagedResponse<UserSummaryResponse> page) => when(
    () =>
        api.getMyFollowing(page: any(named: 'page'), size: any(named: 'size')),
  ).thenAnswer((_) async => apiOk(page));

  group('kind routing', () {
    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'FollowKind.followers hits the followers endpoint only',
      setUp: () => stubFollowers(paged([buildUserSummary()])),
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) => bloc.add(GetFollowList()),
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingLoaded>(),
      ],
      verify: (_) {
        verify(() => api.getMyFollowers(page: 0, size: 20)).called(1);
        verifyNever(
          () => api.getMyFollowing(
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        );
      },
    );

    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'FollowKind.following hits the following endpoint only',
      setUp: () => stubFollowing(paged([buildUserSummary()])),
      build: () => FollowersFollowingBloc(FollowKind.following),
      act: (bloc) => bloc.add(GetFollowList()),
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingLoaded>(),
      ],
      verify: (_) {
        verify(() => api.getMyFollowing(page: 0, size: 20)).called(1);
        verifyNever(
          () => api.getMyFollowers(
            page: any(named: 'page'),
            size: any(named: 'size'),
          ),
        );
      },
    );
  });

  group('GetFollowList', () {
    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'exposes the users list for the sheet',
      setUp: () => stubFollowers(
        paged([buildUserSummary(id: 'u1'), buildUserSummary(id: 'u2')]),
      ),
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) => bloc.add(GetFollowList()),
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingLoaded>(),
      ],
      verify: (bloc) => expect(bloc.users.map((u) => u.id), ['u1', 'u2']),
    );

    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'emits an error on network failure',
      setUp: () => when(
        () => api.getMyFollowers(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenThrow(dioErrorWithoutBody()),
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) => bloc.add(GetFollowList()),
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingError>(),
      ],
    );

    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'emits an error carrying the server message on success=false',
      setUp: () => when(
        () => api.getMyFollowers(
          page: any(named: 'page'),
          size: any(named: 'size'),
        ),
      ).thenAnswer(
        (_) async =>
            apiFail<PagedResponse<UserSummaryResponse>>(error: 'denied'),
      ),
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) => bloc.add(GetFollowList()),
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingError>().having(
          (s) => s.message,
          'message',
          'denied',
        ),
      ],
    );
  });

  group('GetMoreFollowList', () {
    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'does nothing before the first page has loaded',
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) => bloc.add(GetMoreFollowList()),
      expect: () => <FollowersFollowingState>[],
    );

    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'does nothing once the last page has been reached',
      setUp: () => stubFollowers(paged([buildUserSummary()], last: true)),
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) async {
        bloc.add(GetFollowList());
        await Future<void>.delayed(Duration.zero);
        bloc.add(GetMoreFollowList());
      },
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingLoaded>(),
      ],
    );

    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'accumulates the next page into the users list',
      setUp: () {
        when(() => api.getMyFollowers(page: 0, size: 20)).thenAnswer(
          (_) async => apiOk(
            paged(
              [buildUserSummary(id: 'u1')],
              page: 0,
              totalElements: 2,
              totalPages: 2,
              last: false,
            ),
          ),
        );
        when(() => api.getMyFollowers(page: 1, size: 20)).thenAnswer(
          (_) async => apiOk(
            paged(
              [buildUserSummary(id: 'u2')],
              page: 1,
              totalElements: 2,
              totalPages: 2,
              last: true,
            ),
          ),
        );
      },
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) async {
        bloc.add(GetFollowList());
        await Future<void>.delayed(Duration.zero);
        bloc.add(GetMoreFollowList());
      },
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingLoaded>(),
        isA<FollowersFollowingMoreLoading>(),
        isA<FollowersFollowingMoreLoaded>(),
      ],
      verify: (bloc) {
        expect(bloc.users.map((u) => u.id), ['u1', 'u2']);
        expect(bloc.page?.content, hasLength(2));
        expect(bloc.page?.last, isTrue);
      },
    );

    blocTest<FollowersFollowingBloc, FollowersFollowingState>(
      'emits a more-error and keeps the already-loaded users',
      setUp: () {
        when(() => api.getMyFollowers(page: 0, size: 20)).thenAnswer(
          (_) async => apiOk(paged([buildUserSummary(id: 'u1')], last: false)),
        );
        when(
          () => api.getMyFollowers(page: 1, size: 20),
        ).thenThrow(dioErrorWithoutBody());
      },
      build: () => FollowersFollowingBloc(FollowKind.followers),
      act: (bloc) async {
        bloc.add(GetFollowList());
        await Future<void>.delayed(Duration.zero);
        bloc.add(GetMoreFollowList());
      },
      expect: () => [
        isA<FollowersFollowingLoading>(),
        isA<FollowersFollowingLoaded>(),
        isA<FollowersFollowingMoreLoading>(),
        isA<FollowersFollowingMoreError>(),
      ],
      verify: (bloc) => expect(bloc.users, hasLength(1)),
    );
  });
}
