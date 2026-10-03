import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/update_profile_request.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

const _timestamp = '2026-01-01T00:00:00Z';

UserDto _user({String displayName = 'Hassan'}) =>
    UserDto(id: 'user-1', username: 'hassan', displayName: displayName, verified: false);

ApiResponse<T> _ok<T>(T data) =>
    ApiResponse<T>(success: true, data: data, timestamp: _timestamp);

/// Profile caching end-to-end: the real [MyProfileBloc] against the **real**
/// sqflite-backed [AppCacheRepository]. Only the network is stubbed, so these
/// prove the stale-while-revalidate contract actually survives a cold start —
/// something the unit tests (which mock the cache) can't show.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService api;
  late AppCacheRepository cache;

  setUpAll(() => registerFallbackValue(const UpdateProfileRequest()));

  setUp(() async {
    api = MockApiService();
    cache = AppCacheRepository();
    await cache.clear();

    await serviceLocator.reset();
    serviceLocator
      ..registerLazySingleton<ApiService>(() => api)
      ..registerLazySingleton<AppCacheRepository>(() => cache);
  });

  tearDown(() async {
    await cache.clear();
    await serviceLocator.reset();
  });

  testWidgets('a successful fetch writes the profile to the on-disk cache', (
    tester,
  ) async {
    when(
      () => api.getMyProfile(),
    ).thenAnswer((_) async => _ok(_user(displayName: 'Hassan')));

    final bloc = MyProfileBloc();
    addTearDown(bloc.close);

    bloc.add(GetMyProfile());
    await tester.pump(const Duration(seconds: 1));

    expect(bloc.state, isA<MyProfileLoaded>());
    expect(bloc.user?.displayName, 'Hassan');

    // The row really landed in sqflite, not just in memory.
    final raw = await cache.read(AppCacheKeys.myProfile);
    expect(raw, isA<Map>());
    expect(UserDto.fromJson(Map<String, dynamic>.from(raw as Map)).displayName,
        'Hassan');
  });

  testWidgets('a fresh bloc serves the cached profile when the network is down',
      (tester) async {
    // 1. First run: populate the cache from a good response.
    when(
      () => api.getMyProfile(),
    ).thenAnswer((_) async => _ok(_user(displayName: 'Cached Hassan')));

    final first = MyProfileBloc();
    first.add(GetMyProfile());
    await tester.pump(const Duration(seconds: 1));
    expect(first.user?.displayName, 'Cached Hassan');
    await first.close();

    // 2. Simulate a restart with no connectivity: a brand-new bloc (empty
    //    in-memory state) and a failing endpoint.
    when(() => api.getMyProfile()).thenThrow(
      Exception('offline'),
    );

    final second = MyProfileBloc();
    addTearDown(second.close);

    second.add(GetMyProfile());
    await tester.pump(const Duration(seconds: 1));

    // The user still sees their profile, read back off disk.
    expect(second.state, isA<MyProfileLoaded>());
    expect(second.user?.displayName, 'Cached Hassan');
  });

  testWidgets('updating the profile refreshes the on-disk cache', (
    tester,
  ) async {
    when(
      () => api.getMyProfile(),
    ).thenAnswer((_) async => _ok(_user(displayName: 'Old')));
    when(
      () => api.updateProfile(any()),
    ).thenAnswer((_) async => _ok(_user(displayName: 'New')));

    final bloc = MyProfileBloc();
    addTearDown(bloc.close);

    bloc.add(GetMyProfile());
    await tester.pump(const Duration(seconds: 1));
    expect(bloc.user?.displayName, 'Old');

    bloc.add(UpdateMyProfile(displayName: 'New'));
    await tester.pump(const Duration(seconds: 1));

    expect(bloc.user?.displayName, 'New');

    final raw = await cache.read(AppCacheKeys.myProfile);
    expect(UserDto.fromJson(Map<String, dynamic>.from(raw as Map)).displayName,
        'New');
  });

  testWidgets('clearing the cache drops the stored profile (sign-out path)', (
    tester,
  ) async {
    when(() => api.getMyProfile()).thenAnswer((_) async => _ok(_user()));

    final bloc = MyProfileBloc();
    addTearDown(bloc.close);
    bloc.add(GetMyProfile());
    await tester.pump(const Duration(seconds: 1));
    expect(await cache.read(AppCacheKeys.myProfile), isNotNull);

    // This is what main.dart does on Unauthenticated.
    await cache.clear();

    expect(await cache.read(AppCacheKeys.myProfile), isNull);
  });
}
