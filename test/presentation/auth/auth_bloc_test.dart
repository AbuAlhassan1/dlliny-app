import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/domain/dto/request/send_otp_request.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_test_harness.dart';

void main() {
  late MockApiService api;
  late MockFresh fresh;
  late StreamController<AuthenticationStatus> statusController;

  setUpAll(registerAuthFallbacks);

  setUp(() async {
    api = MockApiService();
    fresh = MockFresh();
    statusController = StreamController<AuthenticationStatus>.broadcast();

    when(
      () => fresh.authenticationStatus,
    ).thenAnswer((_) => statusController.stream);
    when(() => fresh.token).thenAnswer((_) async => null);
    when(() => fresh.setToken(any())).thenAnswer((_) async {});
    when(() => fresh.clearToken()).thenAnswer((_) async {});

    await registerAuthMocks(api: api, fresh: fresh);
  });

  tearDown(() async {
    await statusController.close();
    await resetAuthLocator();
  });

  test('starts Unauthenticated', () {
    expect(AuthBloc().state, isA<Unauthenticated>());
  });

  group('AuthStatusChanged', () {
    blocTest<AuthBloc, AuthState>(
      'emits Authenticated when Fresh reports authenticated',
      build: AuthBloc.new,
      act: (bloc) =>
          bloc.add(const AuthStatusChanged(AuthenticationStatus.authenticated)),
      expect: () => [isA<Authenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when Fresh reports unauthenticated',
      build: AuthBloc.new,
      act: (bloc) => bloc.add(
        const AuthStatusChanged(AuthenticationStatus.unauthenticated),
      ),
      expect: () => [isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'initial status with a stored token resolves to Authenticated',
      setUp: () => when(
        () => fresh.token,
      ).thenAnswer((_) async => const OAuth2Token(accessToken: 'stored')),
      build: AuthBloc.new,
      act: (bloc) =>
          bloc.add(const AuthStatusChanged(AuthenticationStatus.initial)),
      expect: () => [isA<Authenticated>()],
      verify: (_) => verify(() => fresh.token).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'initial status without a stored token resolves to Unauthenticated',
      build: AuthBloc.new,
      act: (bloc) =>
          bloc.add(const AuthStatusChanged(AuthenticationStatus.initial)),
      expect: () => [isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'reacts to status pushed on the Fresh stream (no manual event needed)',
      build: AuthBloc.new,
      act: (_) async {
        statusController.add(AuthenticationStatus.authenticated);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [isA<Authenticated>()],
    );
  });

  group('SendOtp', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, PhoneNumberValidAndSentSuccessfully] on success',
      setUp: () => when(
        () => api.sendOtp(any()),
      ).thenAnswer((_) async => apiOk<dynamic>(null)),
      build: AuthBloc.new,
      act: (bloc) => bloc.add(const SendOtp(phoneNumber: kTestPhone)),
      expect: () => [
        isA<AuthLoading>(),
        isA<PhoneNumberValidAndSentSuccessfully>(),
      ],
      verify: (_) {
        final request =
            verify(() => api.sendOtp(captureAny())).captured.single
                as SendOtpRequest;
        expect(request.phoneNumber, kTestPhone);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'surfaces the server message when the API returns an error body',
      setUp: () => when(
        () => api.sendOtp(any()),
      ).thenThrow(dioErrorWithMessage('رقم الهاتف غير صحيح')),
      build: AuthBloc.new,
      act: (bloc) => bloc.add(const SendOtp(phoneNumber: kTestPhone)),
      expect: () => [
        isA<AuthLoading>(),
        isA<PhoneNumberInvalidFromApi>().having(
          (s) => s.message,
          'message',
          'رقم الهاتف غير صحيح',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'maps a connection timeout to a dedicated timeout message',
      setUp: () => when(() => api.sendOtp(any())).thenThrow(dioTimeout()),
      build: AuthBloc.new,
      act: (bloc) => bloc.add(const SendOtp(phoneNumber: kTestPhone)),
      expect: () => [
        isA<AuthLoading>(),
        isA<PhoneNumberInvalidFromApi>().having(
          (s) => s.message,
          'message',
          'Request timed out. Please try again.',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'falls back to ApiCallError when the failure carries no body',
      setUp: () =>
          when(() => api.sendOtp(any())).thenThrow(dioErrorWithoutBody()),
      build: AuthBloc.new,
      act: (bloc) => bloc.add(const SendOtp(phoneNumber: kTestPhone)),
      expect: () => [isA<AuthLoading>(), isA<ApiCallError>()],
    );

    blocTest<AuthBloc, AuthState>(
      'KNOWN GAP: a success=false response leaves the bloc stuck on AuthLoading',
      setUp: () => when(
        () => api.sendOtp(any()),
      ).thenAnswer((_) async => apiFail<dynamic>(error: 'nope')),
      build: AuthBloc.new,
      act: (bloc) => bloc.add(const SendOtp(phoneNumber: kTestPhone)),
      expect: () => [isA<AuthLoading>()],
    );
  });

  group('VerifyOtp', () {
    blocTest<AuthBloc, AuthState>(
      'stores the token pair and emits Authenticated on success',
      setUp: () => when(() => api.verifyOtp(any())).thenAnswer(
        (_) async => apiOk(
          buildAuthResponse(accessToken: 'at-123', refreshToken: 'rt-456'),
        ),
      ),
      build: AuthBloc.new,
      act: (bloc) =>
          bloc.add(const VerifyOtp(phoneNumber: kTestPhone, otp: kTestOtp)),
      expect: () => [isA<Authenticated>()],
      verify: (_) {
        final token =
            verify(() => fresh.setToken(captureAny())).captured.single
                as OAuth2Token;
        expect(token.accessToken, 'at-123');
        expect(token.refreshToken, 'rt-456');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits OtpInvalidFromApi with the server message and stores no token',
      setUp: () => when(
        () => api.verifyOtp(any()),
      ).thenThrow(dioErrorWithMessage('الرمز غير صحيح')),
      build: AuthBloc.new,
      act: (bloc) =>
          bloc.add(const VerifyOtp(phoneNumber: kTestPhone, otp: '000000')),
      expect: () => [
        isA<OtpInvalidFromApi>().having(
          (s) => s.message,
          'message',
          'الرمز غير صحيح',
        ),
      ],
      verify: (_) => verifyNever(() => fresh.setToken(any())),
    );

    blocTest<AuthBloc, AuthState>(
      'emits ApiCallError when the failure carries no body',
      setUp: () =>
          when(() => api.verifyOtp(any())).thenThrow(dioErrorWithoutBody()),
      build: AuthBloc.new,
      act: (bloc) =>
          bloc.add(const VerifyOtp(phoneNumber: kTestPhone, otp: kTestOtp)),
      expect: () => [isA<ApiCallError>()],
      verify: (_) => verifyNever(() => fresh.setToken(any())),
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'clears the token, calls logout with the refresh token, emits Unauthenticated',
      setUp: () {
        when(() => fresh.token).thenAnswer(
          (_) async =>
              const OAuth2Token(accessToken: 'at', refreshToken: 'rt-789'),
        );
        when(
          () => api.logout(any()),
        ).thenAnswer((_) async => apiOk<dynamic>(null));
      },
      build: AuthBloc.new,
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [isA<Unauthenticated>()],
      errors: () => [isA<Object>()],
      verify: (_) {
        verify(() => fresh.clearToken()).called(1);
        verify(() => api.logout('rt-789')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits nothing and never calls logout when no token is stored',
      setUp: () => when(() => fresh.token).thenAnswer((_) async => null),
      build: AuthBloc.new,
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => <AuthState>[],
      errors: () => [isA<Object>()],
      verify: (_) {
        verifyNever(() => fresh.clearToken());
        verifyNever(() => api.logout(any()));
      },
    );
  });
}
