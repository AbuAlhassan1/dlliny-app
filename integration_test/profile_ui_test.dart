import 'package:bloc_test/bloc_test.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart'
    show CityDto, CityWithDistrictsDto;
import 'package:hangout/generated/codegen_loader.g.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:hangout/presentation/my_profile/my_profile_page_wrapper.dart';
import 'package:hangout/presentation/my_profile/widgets/content_tabs_bar.dart';
import 'package:hangout/presentation/shared/widgets/app_toast_host.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

class MockAppCacheRepository extends Mock implements AppCacheRepository {}

/// The page reads `bloc.myPosts` / `bloc.myHangouts` directly as well as the
/// state, so the fakes expose both.
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

const _timestamp = '2026-01-01T00:00:00Z';

UserDto _user({String? displayName = 'Hassan', String? username = 'hassan'}) =>
    UserDto(
      id: 'user-1',
      username: username,
      displayName: displayName,
      verified: false,
    );

/// On-device UI test for the profile screen: the real [MyProfilePageWrapper]
/// with real translations, the real scroll/tab chrome, and real interaction.
/// Only the data sources are stubbed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService api;
  late MockAppCacheRepository cache;
  late MyProfileBloc profileBloc;
  late FakeMyPostsBloc postsBloc;
  late FakeMyHangoutsBloc hangoutsBloc;

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
    registerFallbackValue(GetMyPosts());
    registerFallbackValue(GetMyHangouts());
  });

  setUp(() async {
    api = MockApiService();
    cache = MockAppCacheRepository();
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.write(any(), any())).thenAnswer((_) async {});
    // The complete-profile dialog provides a CitiesAndDistrictsBloc that
    // fetches on create.
    when(() => api.getCitiesWithDistricts())
        .thenAnswer((_) async => ApiResponse<List<CityWithDistrictsDto>>(
              success: true, data: const [], timestamp: _timestamp));
    when(() => api.getCities()).thenAnswer((_) async =>
        ApiResponse<List<CityDto>>(
            success: true, data: const [], timestamp: _timestamp));

    await serviceLocator.reset();
    serviceLocator
      ..registerLazySingleton<ApiService>(() => api)
      ..registerLazySingleton<AppCacheRepository>(() => cache);

    profileBloc = MyProfileBloc();
    postsBloc = FakeMyPostsBloc();
    hangoutsBloc = FakeMyHangoutsBloc();

    // Default: both grids sit in their empty state.
    whenListen(
      postsBloc,
      const Stream<MyPostsState>.empty(),
      initialState: MyPostsLoaded(),
    );
    whenListen(
      hangoutsBloc,
      const Stream<MyHangoutsState>.empty(),
      initialState: MyHangoutsLoaded(),
    );
  });

  tearDown(() async {
    await profileBloc.close();
    await postsBloc.close();
    await hangoutsBloc.close();
    await serviceLocator.reset();
  });

  Widget buildApp({Locale locale = const Locale('ar')}) => EasyLocalization(
    startLocale: locale,
    supportedLocales: const [Locale('en'), Locale('ar')],
    path: 'assets/translations',
    fallbackLocale: const Locale('ar'),
    saveLocale: false,
    assetLoader: const CodegenLoader(),
    child: Builder(
      // Providers sit ABOVE MaterialApp, exactly as main.dart wires them, so
      // routes pushed on the root Navigator (the complete-profile dialog)
      // can still resolve them.
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<MyProfileBloc>.value(value: profileBloc),
          BlocProvider<MyPostsBloc>.value(value: postsBloc),
          BlocProvider<MyHangoutsBloc>.value(value: hangoutsBloc),
        ],
        child: MaterialApp(
          theme: Themes.lightTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const AppToastHost(child: MyProfilePageWrapper()),
        ),
      ),
    ),
  );

  /// Mounts the page and settles it with a loaded profile.
  ///
  /// `initState` schedules a **real** 1s timer that re-runs the page's
  /// listener. `pump(Duration)` only advances the frame clock, not real time,
  /// so we wait it out with `runAsync` — otherwise the callback lands after
  /// the test finishes. (It's `mounted`-guarded now, so a late fire is
  /// harmless; we still wait so the behaviour is actually exercised.)
  Future<void> pumpProfile(
    WidgetTester tester, {
    Locale locale = const Locale('ar'),
    UserDto? user,
  }) async {
    when(() => api.getMyProfile()).thenAnswer(
      (_) async => ApiResponse<UserDto>(
        success: true,
        data: user ?? _user(),
        timestamp: _timestamp,
      ),
    );

    await tester.pumpWidget(buildApp(locale: locale));
    profileBloc.add(GetMyProfile());
    await tester.pumpAndSettle();

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
    );
    await tester.pumpAndSettle();
  }

  /// The stat row and the tab bar share some labels (e.g. "منشوراتي"), so tab
  /// assertions are scoped to the tab bar.
  Finder tab(String label) => find.descendant(
    of: find.byType(ContentTabsBar),
    matching: find.text(label),
  );

  testWidgets('renders the Arabic tab bar with real translations', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(tab('منشوراتي'), findsOneWidget);
    expect(tab('طلعاتي'), findsOneWidget);
    expect(tab('طلعات مدعو الها'), findsOneWidget);
  });

  testWidgets('renders the English tab bar when the locale is en', (
    tester,
  ) async {
    await pumpProfile(tester, locale: const Locale('en'));

    expect(tab('My posts'), findsOneWidget);
    expect(tab('My hangouts'), findsOneWidget);
    expect(tab('Invited to'), findsOneWidget);
    expect(tab('منشوراتي'), findsNothing);
  });

  testWidgets('renders the signed-in user identity and stat row', (
    tester,
  ) async {
    await pumpProfile(tester, locale: const Locale('en'));

    expect(find.text('Hassan'), findsOneWidget);
    expect(find.text('@hassan'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('dispatches the initial content loads on mount', (tester) async {
    await pumpProfile(tester);

    verify(() => postsBloc.add(any(that: isA<GetMyPosts>()))).called(1);
    verify(() => hangoutsBloc.add(any(that: isA<GetMyHangouts>()))).called(1);
  });

  testWidgets('shows the posts empty state on the default tab', (tester) async {
    await pumpProfile(tester, locale: const Locale('en'));

    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('tapping the hangouts tab swaps the visible page', (
    tester,
  ) async {
    await pumpProfile(tester, locale: const Locale('en'));
    expect(find.text('No posts yet'), findsOneWidget);

    await tester.tap(tab('My hangouts'));
    await tester.pumpAndSettle();

    expect(find.text('No hangouts yet'), findsOneWidget);
    expect(find.text('No posts yet'), findsNothing);
  });

  testWidgets('tapping the invited tab reaches the third page', (tester) async {
    await pumpProfile(tester, locale: const Locale('en'));

    await tester.tap(tab('Invited to'));
    await tester.pumpAndSettle();

    // The label now appears twice: once in the tab bar, once as the page's
    // placeholder body.
    expect(find.text('Invited to'), findsNWidgets(2));
    expect(find.text('No posts yet'), findsNothing);
  });

  testWidgets('a posts failure renders the error in place of the grid', (
    tester,
  ) async {
    whenListen(
      postsBloc,
      const Stream<MyPostsState>.empty(),
      initialState: MyPostsError('could not load posts'),
    );

    await pumpProfile(tester, locale: const Locale('en'));

    expect(find.text('could not load posts'), findsOneWidget);
    expect(find.text('No posts yet'), findsNothing);
  });

  testWidgets('an incomplete profile pops the complete-profile dialog', (
    tester,
  ) async {
    // Usernames the backend auto-generates start with "user" — the page
    // treats those as incomplete and prompts.
    await pumpProfile(
      tester,
      locale: const Locale('en'),
      user: _user(displayName: 'Hassan', username: 'user12345'),
    );

    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('disposing inside the first second does not throw', (
    tester,
  ) async {
    when(() => api.getMyProfile()).thenAnswer(
      (_) async => ApiResponse<UserDto>(
        success: true,
        data: _user(),
        timestamp: _timestamp,
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Navigate away well inside the 1s window (tab switch / sign-out).
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    // Let the now-orphaned timer fire. Without the `mounted` guard in
    // initState this throws "This widget has been unmounted, so the State no
    // longer has a context".
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1300)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
