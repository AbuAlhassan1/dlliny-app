import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/request/complete_profile_request.dart';
import 'package:hangout/domain/dto/request/update_profile_request.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

void main() {
  late MockApiService api;
  late MockAppCacheRepository cache;

  setUpAll(() {
    registerFallbackValue(const UpdateProfileRequest());
    registerFallbackValue(const CompleteProfileRequest(displayName: 'x'));
  });

  setUp(() async {
    api = MockApiService();
    cache = MockAppCacheRepository();

    await resetLocator();
    putSingleton<ApiService>(api);
    putSingleton<AppCacheRepository>(cache);

    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
  });

  tearDown(resetLocator);

  group('GetMyProfile', () {
    blocTest<MyProfileBloc, ProfileState>(
      'cache miss + API success emits [Loading, Loaded] and writes the cache',
      setUp: () => when(
        () => api.getMyProfile(),
      ).thenAnswer((_) async => apiOk(buildUser(displayName: 'Hassan'))),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [
        isA<MyProfileLoading>(),
        isA<MyProfileLoaded>().having(
          (s) => s.user?.displayName,
          'user.displayName',
          'Hassan',
        ),
      ],
      verify: (bloc) {
        verify(() => cache.write(AppCacheKeys.myProfile, any())).called(1);
        expect(bloc.user?.id, 'user-1');
      },
    );

    blocTest<MyProfileBloc, ProfileState>(
      'cache hit paints immediately without a Loading state, then revalidates',
      setUp: () {
        when(
          () => cache.read(AppCacheKeys.myProfile),
        ).thenAnswer((_) async => buildUser(displayName: 'Cached').toJson());
        when(
          () => api.getMyProfile(),
        ).thenAnswer((_) async => apiOk(buildUser(displayName: 'Fresh')));
      },
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [
        isA<MyProfileLoaded>().having(
          (s) => s.user?.displayName,
          'user.displayName',
          'Cached',
        ),
        isA<MyProfileLoaded>().having(
          (s) => s.user?.displayName,
          'user.displayName',
          'Fresh',
        ),
      ],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'corrupt cache entry is treated as a miss',
      setUp: () {
        when(
          () => cache.read(AppCacheKeys.myProfile),
        ).thenAnswer((_) async => 'not-a-map');
        when(
          () => api.getMyProfile(),
        ).thenAnswer((_) async => apiOk(buildUser()));
      },
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [isA<MyProfileLoading>(), isA<MyProfileLoaded>()],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'cache miss + network failure emits an error',
      setUp: () =>
          when(() => api.getMyProfile()).thenThrow(dioErrorWithoutBody()),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [isA<MyProfileLoading>(), isA<MyProfileError>()],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'cache miss + success=false emits an error carrying the server message',
      setUp: () => when(
        () => api.getMyProfile(),
      ).thenAnswer((_) async => apiFail<UserDto>(error: 'nope')),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [
        isA<MyProfileLoading>(),
        isA<MyProfileError>().having(
          (s) => s.message,
          'message',
          contains('nope'),
        ),
      ],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'a failed refresh over a cached profile emits nothing (keeps the paint)',
      setUp: () {
        when(
          () => cache.read(AppCacheKeys.myProfile),
        ).thenAnswer((_) async => buildUser(displayName: 'Cached').toJson());
        when(() => api.getMyProfile()).thenThrow(dioErrorWithoutBody());
      },
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [isA<MyProfileLoaded>()],
      verify: (bloc) => expect(bloc.user?.displayName, 'Cached'),
    );

    blocTest<MyProfileBloc, ProfileState>(
      'success=false over a cached profile re-emits the stale user',
      setUp: () {
        when(
          () => cache.read(AppCacheKeys.myProfile),
        ).thenAnswer((_) async => buildUser(displayName: 'Cached').toJson());
        when(
          () => api.getMyProfile(),
        ).thenAnswer((_) async => apiFail<UserDto>(error: 'nope'));
      },
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(GetMyProfile()),
      expect: () => [
        isA<MyProfileLoaded>().having(
          (s) => s.user?.displayName,
          'user.displayName',
          'Cached',
        ),
        isA<MyProfileLoaded>().having(
          (s) => s.user?.displayName,
          'user.displayName',
          'Cached',
        ),
      ],
    );
  });

  group('UpdateMyProfile', () {
    blocTest<MyProfileBloc, ProfileState>(
      'rejects a blank display name before touching the network',
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(UpdateMyProfile(displayName: '   ')),
      expect: () => [
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'الاسم الظاهر مطلوب',
        ),
      ],
      verify: (_) => verifyNever(() => api.updateProfile(any())),
    );

    blocTest<MyProfileBloc, ProfileState>(
      'on success emits [Updating, Updated, Loaded] and writes the cache',
      setUp: () => when(
        () => api.updateProfile(any()),
      ).thenAnswer((_) async => apiOk(buildUser(displayName: 'New Name'))),
      build: MyProfileBloc.new,
      act: (bloc) =>
          bloc.add(UpdateMyProfile(displayName: '  New Name  ', bio: 'hi')),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdated>(),
        isA<MyProfileLoaded>().having(
          (s) => s.user?.displayName,
          'user.displayName',
          'New Name',
        ),
      ],
      verify: (_) {
        final sent =
            verify(() => api.updateProfile(captureAny())).captured.single
                as UpdateProfileRequest;
        expect(sent.displayName, 'New Name', reason: 'must be trimmed');
        expect(sent.bio, 'hi');
        verify(() => cache.write(AppCacheKeys.myProfile, any())).called(1);
      },
    );

    blocTest<MyProfileBloc, ProfileState>(
      'network failure emits an update error and leaves the cache alone',
      setUp: () =>
          when(() => api.updateProfile(any())).thenThrow(dioErrorWithoutBody()),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(UpdateMyProfile(displayName: 'New Name')),
      expect: () => [isA<MyProfileUpdating>(), isA<MyProfileUpdateError>()],
      verify: (_) => verifyNever(() => cache.write(any(), any())),
    );

    blocTest<MyProfileBloc, ProfileState>(
      'success=false surfaces the server message',
      setUp: () => when(
        () => api.updateProfile(any()),
      ).thenAnswer((_) async => apiFail<UserDto>(error: 'bad name')),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(UpdateMyProfile(displayName: 'New Name')),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'bad name',
        ),
      ],
    );
  });

  group('UpdateAccountType', () {
    blocTest<MyProfileBloc, ProfileState>(
      'flips the privacy flag and emits [Updating, Updated, Loaded]',
      setUp: () => when(
        () => api.updateProfile(any()),
      ).thenAnswer((_) async => apiOk(buildUser(isPrivate: true))),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(UpdateAccountType(true)),
      expect: () => [
        isA<AccountTypeUpdating>(),
        isA<AccountTypeUpdated>(),
        isA<MyProfileLoaded>().having(
          (s) => s.user?.isPrivate,
          'user.isPrivate',
          true,
        ),
      ],
      verify: (_) {
        final sent =
            verify(() => api.updateProfile(captureAny())).captured.single
                as UpdateProfileRequest;
        expect(sent.isPrivate, true);
        expect(sent.displayName, isNull);
      },
    );

    blocTest<MyProfileBloc, ProfileState>(
      'network failure emits an account-type error',
      setUp: () =>
          when(() => api.updateProfile(any())).thenThrow(dioErrorWithoutBody()),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(UpdateAccountType(true)),
      expect: () => [
        isA<AccountTypeUpdating>(),
        isA<AccountTypeUpdateError>(),
      ],
    );
  });

  group('CompleteMyProfile', () {
    blocTest<MyProfileBloc, ProfileState>(
      'rejects an empty display name',
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(CompleteMyProfile(displayName: '')),
      expect: () => [
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'الاسم مطلوب',
        ),
      ],
      verify: (_) => verifyNever(() => api.completeProfile(any())),
    );

    blocTest<MyProfileBloc, ProfileState>(
      'rejects a username containing a space',
      build: MyProfileBloc.new,
      act: (bloc) =>
          bloc.add(CompleteMyProfile(displayName: 'Hassan', username: 'a b')),
      expect: () => [
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'اسم المستخدم غير صالح',
        ),
      ],
      verify: (_) => verifyNever(() => api.completeProfile(any())),
    );

    blocTest<MyProfileBloc, ProfileState>(
      'on success emits [Updating, Updated] and re-fetches the profile',
      setUp: () {
        when(
          () => api.completeProfile(any()),
        ).thenAnswer((_) async => apiOk(buildUser()));
        when(
          () => api.getMyProfile(),
        ).thenAnswer((_) async => apiOk(buildUser(displayName: 'Hassan')));
      },
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(
        CompleteMyProfile(displayName: 'Hassan', username: 'hassan'),
      ),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdated>(),
        isA<MyProfileLoading>(),
        isA<MyProfileLoaded>(),
      ],
      verify: (_) => verify(() => api.getMyProfile()).called(1),
    );

    blocTest<MyProfileBloc, ProfileState>(
      'translates a 409 username conflict into the Arabic taken message',
      setUp: () => when(() => api.completeProfile(any())).thenThrow(
        dioErrorWithMessage('username already taken', statusCode: 409),
      ),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(
        CompleteMyProfile(displayName: 'Hassan', username: 'taken'),
      ),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'اسم المستخدم محجوز. جرّب اسماً آخر.',
        ),
      ],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'translates a timeout into the connectivity message',
      setUp: () =>
          when(() => api.completeProfile(any())).thenThrow(dioTimeout()),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(CompleteMyProfile(displayName: 'Hassan')),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.',
        ),
      ],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'translates a 5xx into the server-problem message',
      setUp: () => when(
        () => api.completeProfile(any()),
      ).thenThrow(dioErrorWithStatus(500)),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(CompleteMyProfile(displayName: 'Hassan')),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'مشكلة في الخادم. حاول بعد قليل.',
        ),
      ],
    );

    blocTest<MyProfileBloc, ProfileState>(
      'translates a 401 into the expired-session message',
      setUp: () => when(
        () => api.completeProfile(any()),
      ).thenThrow(dioErrorWithStatus(401)),
      build: MyProfileBloc.new,
      act: (bloc) => bloc.add(CompleteMyProfile(displayName: 'Hassan')),
      expect: () => [
        isA<MyProfileUpdating>(),
        isA<MyProfileUpdateError>().having(
          (s) => s.message,
          'message',
          'انتهت جلستك. الرجاء تسجيل الدخول مجدداً.',
        ),
      ],
    );
  });
}
