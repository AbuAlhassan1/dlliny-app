import 'package:dio/dio.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

class MockAppCacheRepository extends Mock implements AppCacheRepository {}

const String kTestTimestamp = '2026-01-01T00:00:00Z';

void putSingleton<T extends Object>(T instance) =>
    serviceLocator.registerLazySingleton<T>(() => instance);

Future<void> resetLocator() => serviceLocator.reset();

ApiResponse<T> apiOk<T>(T? data) =>
    ApiResponse<T>(success: true, data: data, timestamp: kTestTimestamp);

ApiResponse<T> apiFail<T>({String? error}) =>
    ApiResponse<T>(success: false, error: error, timestamp: kTestTimestamp);

PagedResponse<T> paged<T>(
  List<T> content, {
  int page = 0,
  int size = 20,
  int? totalElements,
  int totalPages = 1,
  bool last = true,
}) => PagedResponse<T>(
  content: content,
  page: page,
  size: size,
  totalElements: totalElements ?? content.length,
  totalPages: totalPages,
  last: last,
);

UserDto buildUser({
  String id = 'user-1',
  String? username = 'hassan',
  String? displayName = 'Hassan',
  bool isPrivate = false,
}) => UserDto(
  id: id,
  username: username,
  displayName: displayName,
  verified: false,
  isPrivate: isPrivate,
);

UserSummaryResponse buildUserSummary({String id = 'user-2'}) =>
    UserSummaryResponse(id: id, verified: false);

PostResponse buildPost({String id = 'post-1'}) => PostResponse(
  id: id,
  likesCount: 0,
  commentsCount: 0,
  likedByMe: false,
  mine: true,
  media: const [],
  userMentions: const [],
  venueMentions: const [],
  createdAt: kTestTimestamp,
);

HangoutResponse buildHangout({String id = 'hangout-1'}) => HangoutResponse(
  id: id,
  organizerId: 'user-1',
  organizerUsername: 'hassan',
  venueId: 'venue-1',
  venueNameAr: 'مقهى',
  venueNameEn: 'Cafe',
  scheduledAt: kTestTimestamp,
  attendeeCount: 0,
  likesCount: 0,
  commentsCount: 0,
  status: 'SCHEDULED',
  joinPolicy: 'OPEN',
  postVisibility: 'PUBLIC',
  createdAt: kTestTimestamp,
);

DioException dioErrorWithMessage(String message, {int statusCode = 400}) {
  final options = RequestOptions(path: '/api/v1');
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

DioException dioErrorWithStatus(int statusCode) {
  final options = RequestOptions(path: '/api/v1');
  return DioException(
    requestOptions: options,
    response: Response<Map<String, dynamic>>(
      requestOptions: options,
      statusCode: statusCode,
      data: const {},
    ),
  );
}

DioException dioErrorWithoutBody() => DioException(
  requestOptions: RequestOptions(path: '/api/v1'),
  type: DioExceptionType.badResponse,
);

DioException dioTimeout() => DioException(
  requestOptions: RequestOptions(path: '/api/v1'),
  type: DioExceptionType.connectionTimeout,
);
