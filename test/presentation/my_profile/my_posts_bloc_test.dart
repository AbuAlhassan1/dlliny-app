import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

void main() {
  late MockApiService api;

  void stubPage(PagedResponse<PostResponse> page) => when(
    () => api.getMyPosts(page: any(named: 'page'), size: any(named: 'size')),
  ).thenAnswer((_) async => apiOk(page));

  setUp(() async {
    api = MockApiService();
    await resetLocator();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  group('GetMyPosts', () {
    blocTest<MyPostsBloc, MyPostsState>(
      'emits [Loading, Loaded] and exposes the page for the grid',
      setUp: () => stubPage(paged([buildPost(id: 'p1'), buildPost(id: 'p2')])),
      build: MyPostsBloc.new,
      act: (bloc) => bloc.add(GetMyPosts()),
      expect: () => [isA<MyPostsLoading>(), isA<MyPostsLoaded>()],
      verify: (bloc) {
        expect(bloc.myPosts?.content, hasLength(2));
        verify(() => api.getMyPosts(page: 0, size: 10)).called(1);
      },
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'emits an error on network failure',
      setUp: () => when(
        () => api.getMyPosts(page: any(named: 'page'), size: any(named: 'size')),
      ).thenThrow(dioErrorWithoutBody()),
      build: MyPostsBloc.new,
      act: (bloc) => bloc.add(GetMyPosts()),
      expect: () => [isA<MyPostsLoading>(), isA<MyPostsError>()],
      verify: (bloc) => expect(bloc.myPosts, isNull),
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'emits an error when the API reports success=false',
      setUp: () => when(
        () => api.getMyPosts(page: any(named: 'page'), size: any(named: 'size')),
      ).thenAnswer(
        (_) async => apiFail<PagedResponse<PostResponse>>(error: 'boom'),
      ),
      build: MyPostsBloc.new,
      act: (bloc) => bloc.add(GetMyPosts()),
      expect: () => [
        isA<MyPostsLoading>(),
        isA<MyPostsError>().having(
          (s) => s.message,
          'message',
          contains('boom'),
        ),
      ],
    );
  });

  group('GetMorePosts', () {
    blocTest<MyPostsBloc, MyPostsState>(
      'does nothing before the first page has loaded',
      build: MyPostsBloc.new,
      act: (bloc) => bloc.add(GetMorePosts()),
      expect: () => <MyPostsState>[],
      verify: (_) => verifyNever(
        () => api.getMyPosts(page: any(named: 'page'), size: any(named: 'size')),
      ),
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'does nothing once the last page has been reached',
      setUp: () => stubPage(paged([buildPost()], last: true)),
      build: MyPostsBloc.new,
      act: (bloc) async {
        bloc.add(GetMyPosts());
        await Future<void>.delayed(Duration.zero);
        bloc.add(GetMorePosts());
      },
      expect: () => [isA<MyPostsLoading>(), isA<MyPostsLoaded>()],
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'appends the next page to the existing content',
      setUp: () {
        when(() => api.getMyPosts(page: 0, size: 10)).thenAnswer(
          (_) async => apiOk(
            paged(
              [buildPost(id: 'p1')],
              page: 0,
              size: 10,
              totalElements: 2,
              totalPages: 2,
              last: false,
            ),
          ),
        );
        when(() => api.getMyPosts(page: 1, size: 10)).thenAnswer(
          (_) async => apiOk(
            paged(
              [buildPost(id: 'p2')],
              page: 1,
              size: 10,
              totalElements: 2,
              totalPages: 2,
              last: true,
            ),
          ),
        );
      },
      build: MyPostsBloc.new,
      act: (bloc) async {
        bloc.add(GetMyPosts());
        await Future<void>.delayed(Duration.zero);
        bloc.add(GetMorePosts());
      },
      expect: () => [
        isA<MyPostsLoading>(),
        isA<MyPostsLoaded>(),
        isA<MyPostsMoreLoading>(),
        isA<MyPostsMoreLoaded>(),
      ],
      verify: (bloc) {
        expect(bloc.myPosts?.content.map((p) => p.id), ['p1', 'p2']);
        expect(bloc.myPosts?.last, isTrue);
      },
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'emits a more-error and keeps the already-loaded page',
      setUp: () {
        when(() => api.getMyPosts(page: 0, size: 10)).thenAnswer(
          (_) async =>
              apiOk(paged([buildPost(id: 'p1')], size: 10, last: false)),
        );
        when(
          () => api.getMyPosts(page: 1, size: 10),
        ).thenThrow(dioErrorWithoutBody());
      },
      build: MyPostsBloc.new,
      act: (bloc) async {
        bloc.add(GetMyPosts());
        await Future<void>.delayed(Duration.zero);
        bloc.add(GetMorePosts());
      },
      expect: () => [
        isA<MyPostsLoading>(),
        isA<MyPostsLoaded>(),
        isA<MyPostsMoreLoading>(),
        isA<MyPostsMoreError>(),
      ],
      verify: (bloc) => expect(bloc.myPosts?.content, hasLength(1)),
    );
  });

  group('DeleteMyPost', () {
    blocTest<MyPostsBloc, MyPostsState>(
      'removes the post optimistically before the network call returns',
      setUp: () {
        stubPage(paged([buildPost(id: 'p1'), buildPost(id: 'p2')]));
        when(
          () => api.deletePost(any()),
        ).thenAnswer((_) async => apiOk<dynamic>(null));
      },
      build: MyPostsBloc.new,
      act: (bloc) async {
        bloc.add(GetMyPosts());
        await Future<void>.delayed(Duration.zero);
        bloc.add(DeleteMyPost('p1'));
      },
      expect: () => [
        isA<MyPostsLoading>(),
        isA<MyPostsLoaded>(),
        isA<MyPostDeleted>().having((s) => s.postId, 'postId', 'p1'),
        isA<MyPostsLoaded>(),
      ],
      verify: (bloc) {
        expect(bloc.myPosts?.content.map((p) => p.id), ['p2']);
        expect(bloc.myPosts?.totalElements, 1);
        verify(() => api.deletePost('p1')).called(1);
      },
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'restores the post when the delete request fails',
      setUp: () {
        stubPage(paged([buildPost(id: 'p1'), buildPost(id: 'p2')]));
        when(() => api.deletePost(any())).thenThrow(dioErrorWithoutBody());
      },
      build: MyPostsBloc.new,
      act: (bloc) async {
        bloc.add(GetMyPosts());
        await Future<void>.delayed(Duration.zero);
        bloc.add(DeleteMyPost('p1'));
      },
      expect: () => [
        isA<MyPostsLoading>(),
        isA<MyPostsLoaded>(),
        isA<MyPostDeleted>(),
        isA<MyPostsLoaded>(),
        isA<MyPostDeleteError>(),
        isA<MyPostsLoaded>(),
      ],
      verify: (bloc) {
        expect(
          bloc.myPosts?.content.map((p) => p.id),
          ['p1', 'p2'],
          reason: 'the post must be put back at its original index',
        );
        expect(bloc.myPosts?.totalElements, 2);
      },
    );

    blocTest<MyPostsBloc, MyPostsState>(
      'ignores a delete for an unknown post id',
      setUp: () => stubPage(paged([buildPost(id: 'p1')])),
      build: MyPostsBloc.new,
      act: (bloc) async {
        bloc.add(GetMyPosts());
        await Future<void>.delayed(Duration.zero);
        bloc.add(DeleteMyPost('does-not-exist'));
      },
      expect: () => [isA<MyPostsLoading>(), isA<MyPostsLoaded>()],
      verify: (_) => verifyNever(() => api.deletePost(any())),
    );
  });

  blocTest<MyPostsBloc, MyPostsState>(
    'ResetMyPosts clears the cached page (used on sign-out)',
    setUp: () => stubPage(paged([buildPost()])),
    build: MyPostsBloc.new,
    act: (bloc) async {
      bloc.add(GetMyPosts());
      await Future<void>.delayed(Duration.zero);
      bloc.add(ResetMyPosts());
    },
    expect: () => [
      isA<MyPostsLoading>(),
      isA<MyPostsLoaded>(),
      isA<MyPostsInitial>(),
    ],
    verify: (bloc) => expect(bloc.myPosts, isNull),
  );
}
