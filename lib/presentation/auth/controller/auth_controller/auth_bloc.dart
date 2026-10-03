import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/auth/apple_auth_service.dart';
import 'package:hangout/data/auth/google_auth_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/apple_sign_in_request.dart';
import 'package:hangout/domain/dto/request/google_sign_in_request.dart';
import 'package:hangout/domain/dto/request/send_otp_request.dart';
import 'package:hangout/domain/dto/request/verify_otp_request.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Fresh<OAuth2Token> _fresh = serviceLocator.get<Fresh<OAuth2Token>>();
  late StreamSubscription<AuthenticationStatus> _authStatusSubscription;
  final ApiService apiService = serviceLocator.get<ApiService>();

  AuthBloc() : super(Unauthenticated()) {
    _authStatusSubscription = _fresh.authenticationStatus.listen(
      (status) => add(AuthStatusChanged(status)),
    );

    on<AuthStatusChanged>((event, emit) async {
      switch (event.status) {
        case AuthenticationStatus.authenticated:
          emit(Authenticated());
          break;
        case AuthenticationStatus.unauthenticated:
          emit(Unauthenticated());
          break;
        case AuthenticationStatus.initial:
          await _checkInitialStatus(emit);
          break;
      }
    });

    on<SendOtp>((event, emit) async {
      emit(AuthLoading());
      ApiResponse<dynamic>? response;

      try {
        response = await apiService.sendOtp(
          SendOtpRequest(phoneNumber: event.phoneNumber),
        );
      } on DioException catch (error) {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          emit(
            PhoneNumberInvalidFromApi(
              message: 'Request timed out. Please try again.',
            ),
          );
          return;
        }

        ApiResponse<dynamic>? errorResponse = error.response != null
            ? ApiResponse.fromJson(error.response!.data, (_) => null)
            : null;

        if (errorResponse != null &&
            errorResponse.error != null &&
            errorResponse.error!.isNotEmpty) {
          emit(PhoneNumberInvalidFromApi(message: errorResponse.error!));
        } else {
          emit(ApiCallError());
        }
        return;
      }

      if (response.success) {
        emit(PhoneNumberValidAndSentSuccessfully());
      }
    });

    on<VerifyOtp>((event, emit) async {
      ApiResponse<AuthResponse>? response;

      try {
        response = await apiService.verifyOtp(
          VerifyOtpRequest(phoneNumber: event.phoneNumber, otp: event.otp),
        );
      } on DioException catch (error) {
        ApiResponse<dynamic>? errorResponse = error.response != null
            ? ApiResponse.fromJson(error.response!.data, (_) => null)
            : null;

        if (errorResponse != null &&
            errorResponse.error != null &&
            errorResponse.error!.isNotEmpty) {
          emit(OtpInvalidFromApi(message: errorResponse.error!));
        } else {
          emit(ApiCallError());
        }
        return;
      }

      await _fresh.setToken(
        OAuth2Token(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        ),
      );

      emit(Authenticated());
    });

    on<AuthLogoutRequested>((event, emit) async {
      var token = await _fresh.token;
      if (token != null && token.refreshToken != null) {
        await _fresh.clearToken();
        await apiService.logout(token.refreshToken!);
        emit(Unauthenticated());
      }
      await GoogleAuthService().signOut();
    });

    on<AppleSignInRequested>((event, emit) async {
      log("Apple Sign-In requested");
      emit(AuthLoading());

      ApiResponse<AuthResponse>? response;

      try {
        log("Apple Sign-In requested - trying to get ID token");
        final idToken = await AppleAuthService().signInAndGetIdTokenViaFirebase();
        if (idToken == null) {
          emit(Unauthenticated());
          return;
        }

        log("Apple Sign-In requested - ID token obtained, sending to API");
        response = await apiService.signInWithApple(
          AppleSignInRequest(idToken: idToken),
        );
      } on DioException catch (error) {
        log("Apple Sign-In failed with DioException: ${error.message}");
        ApiResponse<dynamic>? errorResponse = error.response != null
            ? ApiResponse.fromJson(error.response!.data, (_) => null)
            : null;

        if (errorResponse != null &&
            errorResponse.error != null &&
            errorResponse.error!.isNotEmpty) {
          emit(OtpInvalidFromApi(message: errorResponse.error!));
        } else {
          emit(ApiCallError());
        }
        return;
      } catch (error, stackTrace) {
        log("Apple Sign-In failed: $error", stackTrace: stackTrace);
        emit(ApiCallError());
        return;
      }

      log("Apple Sign-In successful, setting tokens");
      await _fresh.setToken(
        OAuth2Token(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        ),
      );

      log('Apple Sign-In successful, tokens stored');

      emit(Authenticated());
    });

    on<GoogleSignInRequested>((event, emit) async {
      log("Google Sign-In requested");
      emit(AuthLoading());

      ApiResponse<AuthResponse>? response;

      try {
        log("Google Sign-In requested - trying to get ID token");
        final idToken = await GoogleAuthService().signInAndGetIdToken();
        if (idToken == null) {
          emit(Unauthenticated());
          return;
        }

        log("Google Sign-In requested - ID token obtained, sending to API");
        response = await apiService.signInWithGoogle(
          GoogleSignInRequest(idToken: idToken),
        );
      } on DioException catch (error) {
        log("Google Sign-In failed with DioException: ${error.message}");
        ApiResponse<dynamic>? errorResponse = error.response != null
            ? ApiResponse.fromJson(error.response!.data, (_) => null)
            : null;

        if (errorResponse != null &&
            errorResponse.error != null &&
            errorResponse.error!.isNotEmpty) {
          emit(OtpInvalidFromApi(message: errorResponse.error!));
        } else {
          emit(ApiCallError());
        }
        return;
      } catch (error, stackTrace) {
        log("Google Sign-In failed: $error", stackTrace: stackTrace);
        emit(ApiCallError());
        return;
      }

      log("Google Sign-In successful, setting tokens");
      await _fresh.setToken(
        OAuth2Token(
          accessToken: response.data!.accessToken,
          refreshToken: response.data!.refreshToken,
        ),
      );

      log('Google Sign-In successful, tokens stored');

      emit(Authenticated());
    });
  }

  Future<void> _checkInitialStatus(Emitter<AuthState> emit) async {
    final token = await _fresh.token;
    if (token != null) {
      emit(Authenticated());
    } else {
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }
}
