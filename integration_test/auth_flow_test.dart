import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/data_sources/auth_local_data_source.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/verify_otp_request.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/presentation/auth/auth_page_wrapper.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

const _timestamp = '2026-01-01T00:00:00Z';
const _phone = '+9647700000000';
const _otp = '123456';

/// End-to-end auth wiring: the real [AuthBloc], the real `Fresh` interceptor,
/// and the real [AuthLocalDataSource] (secure storage), with only the network
/// stubbed. This is what the unit tests can't cover — that a successful verify
/// actually lands a session on disk and flips the app to authenticated.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockApiService api;
  late Fresh<OAuth2Token> fresh;
  late AuthLocalDataSource tokenStorage;

  setUpAll(() {
    registerFallbackValue(VerifyOtpRequest(phoneNumber: _phone, otp: _otp));
  });

  setUp(() {
    api = MockApiService();
  });

  /// Boots the real auth stack in the order the app does it: storage first,
  /// then `Fresh` (which reads that storage once on construction), then the
  /// bloc. Seeding a session *after* Fresh is built would be invisible to it,
  /// so tests that need a pre-existing session pass [seededSession] here.
  Future<AuthBloc> bootAuth({OAuth2Token? seededSession}) async {
    FlutterSecureStorage.setMockInitialValues(
      seededSession == null
          ? {}
          : {
              'jwt': seededSession.accessToken,
              if (seededSession.refreshToken != null)
                'refresh': seededSession.refreshToken!,
            },
    );
    tokenStorage = AuthLocalDataSource();

    // The genuine interceptor, wired to the genuine token store.
    fresh = Fresh.oAuth2(
      tokenStorage: tokenStorage,
      tokenHeader: (token) => {'Authorization': 'Bearer ${token.accessToken}'},
      refreshToken: (_, _) async =>
          throw UnimplementedError('not exercised in this flow'),
    );

    await serviceLocator.reset();
    serviceLocator
      ..registerLazySingleton<ApiService>(() => api)
      ..registerLazySingleton<Fresh<OAuth2Token>>(() => fresh);

    final bloc = AuthBloc();
    addTearDown(bloc.close);
    addTearDown(fresh.close);
    addTearDown(serviceLocator.reset);
    return bloc;
  }

  ApiResponse<AuthResponse> authOk({
    String accessToken = 'access-token',
    String refreshToken = 'refresh-token',
  }) => ApiResponse<AuthResponse>(
    success: true,
    timestamp: _timestamp,
    data: AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      isNewUser: false,
      user: UserDto(id: 'user-1', verified: false),
    ),
  );

  Widget wrap(AuthBloc bloc) => MaterialApp(
    theme: Themes.lightTheme,
    home: BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const AuthPageWrapper(),
    ),
  );

  testWidgets('cold start with no stored session settles on Unauthenticated', (
    tester,
  ) async {
    final bloc = await bootAuth();

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    // Real Fresh replays `initial`; the bloc resolves it against real storage.
    expect(bloc.state, isA<Unauthenticated>());
    expect(await tokenStorage.read(), isNull);
    expect(find.byIcon(TablerIcons.brand_google_filled), findsOneWidget);
  });

  testWidgets('cold start with a stored session settles on Authenticated', (
    tester,
  ) async {
    final bloc = await bootAuth(
      seededSession: const OAuth2Token(
        accessToken: 'saved',
        refreshToken: 'saved-refresh',
      ),
    );

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    expect(bloc.state, isA<Authenticated>());
    expect((await tokenStorage.read())!.accessToken, 'saved');
  });

  testWidgets('verifying an OTP persists the session end-to-end', (
    tester,
  ) async {
    when(
      () => api.verifyOtp(any()),
    ).thenAnswer((_) async => authOk(accessToken: 'at-1', refreshToken: 'rt-1'));

    final bloc = await bootAuth();

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));
    expect(bloc.state, isA<Unauthenticated>());

    bloc.add(const VerifyOtp(phoneNumber: _phone, otp: _otp));
    await tester.pump(const Duration(seconds: 1));

    // 1. The bloc flipped to authenticated.
    expect(bloc.state, isA<Authenticated>());

    // 2. Fresh took the token (so every future Dio call is authorised).
    final held = await fresh.token;
    expect(held, isNotNull);
    expect(held!.accessToken, 'at-1');

    // 3. The session actually reached secure storage — survives a restart.
    final persisted = await tokenStorage.read();
    expect(persisted, isNotNull);
    expect(persisted!.accessToken, 'at-1');
    expect(persisted.refreshToken, 'rt-1');
  });

  testWidgets('a rejected OTP leaves no session and surfaces a toast', (
    tester,
  ) async {
    final options = RequestOptions(path: '/api/v1/auth/otp/verify');
    when(() => api.verifyOtp(any())).thenThrow(
      DioException(
        requestOptions: options,
        response: Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 400,
          data: {
            'success': false,
            'data': null,
            'error': 'الرمز غير صحيح',
            'timestamp': _timestamp,
          },
        ),
      ),
    );

    final messages = <AppToastMessage>[];
    final sub = appToast.stream.listen(messages.add);
    addTearDown(sub.cancel);

    final bloc = await bootAuth();

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    bloc.add(const VerifyOtp(phoneNumber: _phone, otp: '000000'));
    await tester.pump(const Duration(seconds: 1));

    expect(bloc.state, isA<OtpInvalidFromApi>());
    expect(messages.single.text, 'الرمز غير صحيح');
    expect(messages.single.severity, AppToastSeverity.error);

    // Nothing half-written on the failure path.
    expect(await tokenStorage.read(), isNull);
    expect(await fresh.token, isNull);
  });
}
