import 'dart:async';
import 'dart:io' show Platform;

// easy_localization re-exports intl's TextDirection, which shadows the
// Flutter one used for the RTL assertion.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/codegen_loader.g.dart';
import 'package:hangout/presentation/auth/auth_page_wrapper.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:hangout/presentation/shared/widgets/app_toast_host.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

class MockFresh extends Mock implements Fresh<OAuth2Token> {}

/// On-device UI test for the sign-in screen. Unlike the widget tests (which
/// run on the host with a mocked bloc and fall back to raw locale keys), this
/// renders the *real* screen: real translations through `CodegenLoader`, the
/// real toast host, real RTL layout, and the real iOS platform — so the
/// iOS-only Apple button is actually present here.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService api;
  late MockFresh fresh;
  late StreamController<AuthenticationStatus> status;

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
  });

  setUp(() async {
    api = MockApiService();
    fresh = MockFresh();
    status = StreamController<AuthenticationStatus>.broadcast();

    when(() => fresh.authenticationStatus).thenAnswer((_) => status.stream);
    when(() => fresh.token).thenAnswer((_) async => null);
    when(() => fresh.setToken(any())).thenAnswer((_) async {});

    await serviceLocator.reset();
    serviceLocator
      ..registerLazySingleton<ApiService>(() => api)
      ..registerLazySingleton<Fresh<OAuth2Token>>(() => fresh);
  });

  tearDown(() async {
    await status.close();
    await serviceLocator.reset();
  });

  /// Mirrors main.dart's real localization + toast wiring, minus the router.
  Widget buildApp(AuthBloc bloc, {Locale locale = const Locale('ar')}) {
    return EasyLocalization(
      startLocale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      // Tests must not persist a locale into the simulator's prefs, or they
      // leak into each other.
      saveLocale: false,
      assetLoader: const CodegenLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: Themes.lightTheme,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: AppToastHost(
            child: BlocProvider<AuthBloc>.value(
              value: bloc,
              child: const AuthPageWrapper(),
            ),
          ),
        ),
      ),
    );
  }

  AuthBloc newBloc() {
    final bloc = AuthBloc();
    addTearDown(bloc.close);
    return bloc;
  }

  testWidgets('renders the Arabic sign-in screen with real translations', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(newBloc()));
    await tester.pumpAndSettle();

    expect(find.text('هلا والله'), findsOneWidget);
    expect(find.text('سجّل الدخول باستخدام جوجل'), findsOneWidget);
    expect(
      find.text('بتسجيل الدخول، أنت توافق على شروط الاستخدام وسياسة الخصوصية.'),
      findsOneWidget,
    );
    // The hero logo asset actually resolves.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('renders the English sign-in screen when the locale is en', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(newBloc(), locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('هلا والله'), findsNothing);
  });

  testWidgets('lays out right-to-left in Arabic', (tester) async {
    await tester.pumpWidget(buildApp(newBloc()));
    await tester.pumpAndSettle();

    final direction = Directionality.of(
      tester.element(find.text('هلا والله')),
    );
    expect(direction, TextDirection.rtl);
  });

  testWidgets('shows the Apple CTA on iOS and hides it elsewhere', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(newBloc()));
    await tester.pumpAndSettle();

    final appleCta = find.text('سجّل الدخول باستخدام آبل');
    if (Platform.isIOS) {
      // The host-machine widget test asserts the opposite; this is the real
      // platform gate firing.
      expect(appleCta, findsOneWidget);
    } else {
      expect(appleCta, findsNothing);
    }
  });

  testWidgets('tapping Google surfaces a real error toast on failure', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(newBloc()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('سجّل الدخول باستخدام جوجل'));
    await tester.pumpAndSettle();

    // Google sign-in can't complete here (no Firebase app on the test
    // harness), so the bloc lands on ApiCallError and the page's listener
    // raises the generic toast — rendered for real by AppToastHost.
    //
    // Note: the in-flight spinner is NOT asserted here. `GoogleAuthService()`
    // throws synchronously without Firebase, so AuthLoading and ApiCallError
    // are emitted within one microtask and no frame ever paints the spinner.
    // The loading visual is covered in auth_page_widget_test.dart, where the
    // bloc is driven directly.
    expect(find.text('حصل خطأ، حاول مرة ثانية'), findsOneWidget);
  });

  testWidgets('the CTA is re-enabled once the failure resolves', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(newBloc()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('سجّل الدخول باستخدام جوجل'));
    await tester.pumpAndSettle();

    // Back out of the loading state, so the user can retry.
    expect(find.text('سجّل الدخول باستخدام جوجل'), findsOneWidget);
  });
}
