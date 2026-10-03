import 'package:dio/dio.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/send_otp_request.dart';
import 'package:hangout/domain/dto/request/verify_otp_request.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

class MockFresh extends Mock implements Fresh<OAuth2Token> {}

const String kTestTimestamp = '2026-01-01T00:00:00Z';
const String kTestPhone = '+9647700000000';
const String kTestOtp = '123456';

void registerAuthFallbacks() {
  registerFallbackValue(SendOtpRequest(phoneNumber: kTestPhone));
  registerFallbackValue(
    VerifyOtpRequest(phoneNumber: kTestPhone, otp: kTestOtp),
  );
  registerFallbackValue(const OAuth2Token(accessToken: 'fallback-access'));
}

Future<void> registerAuthMocks({
  required ApiService api,
  required Fresh<OAuth2Token> fresh,
}) async {
  await serviceLocator.reset();
  serviceLocator
    ..registerLazySingleton<ApiService>(() => api)
    ..registerLazySingleton<Fresh<OAuth2Token>>(() => fresh);
}

Future<void> resetAuthLocator() => serviceLocator.reset();

UserDto buildUser({String id = 'user-1'}) => UserDto(id: id, verified: false);

AuthResponse buildAuthResponse({
  String accessToken = 'access-token',
  String refreshToken = 'refresh-token',
  bool isNewUser = false,
}) => AuthResponse(
  accessToken: accessToken,
  refreshToken: refreshToken,
  isNewUser: isNewUser,
  user: buildUser(),
);

UserAccessResponse buildAccess() =>
    const UserAccessResponse(businesses: [], orphanVenues: []);

ApiResponse<T> apiOk<T>(T? data) =>
    ApiResponse<T>(success: true, data: data, timestamp: kTestTimestamp);

ApiResponse<T> apiFail<T>({String? error}) =>
    ApiResponse<T>(success: false, error: error, timestamp: kTestTimestamp);

DioException dioErrorWithMessage(String message, {int statusCode = 400}) {
  final options = RequestOptions(path: '/api/v1/auth');
  return DioException(
    requestOptions: options,
    response: Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'success': false,
        'data': null,
        'error': message,
        'timestamp': kTestTimestamp,
      },
    ),
  );
}

DioException dioErrorWithoutBody() => DioException(
  requestOptions: RequestOptions(path: '/api/v1/auth'),
  type: DioExceptionType.badResponse,
);

DioException dioTimeout() => DioException(
  requestOptions: RequestOptions(path: '/api/v1/auth'),
  type: DioExceptionType.connectionTimeout,
);
