import 'package:dio/dio.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/create_memory_request.dart';
import 'package:hangout/domain/dto/request/engagement_response_request.dart';
import 'package:hangout/domain/dto/request/react_to_memory_request.dart';
import 'package:hangout/domain/dto/response/engagement_results_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';

class MemoryRepository {
  final ApiService _api;
  MemoryRepository(this._api);

  Future<List<MemoryTrayBucket>> getTray() =>
      _unwrap(() => _api.getMemoriesTray());

  Future<List<MemoryResponse>> getUserMemories(String userId) =>
      _unwrap(() => _api.getUserMemories(userId));

  Future<List<MemoryResponse>> getVenueMemories(String venueId) =>
      _unwrap(() => _api.getVenueMemories(venueId));

  Future<MemoryResponse> getMemory(String memoryId) =>
      _unwrap(() => _api.getMemory(memoryId));

  Future<PagedResponse<MemoryViewerEntry>> getMemoryViewers(
    String memoryId, {
    int page = 0,
    int size = 50,
  }) =>
      _unwrap(() => _api.getMemoryViewers(memoryId, page: page, size: size));

  Future<MemoryResponse> createMemory(CreateMemoryRequest request) =>
      _unwrap(() => _api.createMemory(request));

  Future<MemoryResponse> createVenueMemory(
    String venueId,
    CreateMemoryRequest request,
  ) =>
      _unwrap(() => _api.createVenueMemory(venueId, request));

  Future<void> deleteMemory(String memoryId) =>
      _unwrapVoid(() => _api.deleteMemory(memoryId));

  Future<void> deleteVenueMemory(String venueId, String memoryId) =>
      _unwrapVoid(() => _api.deleteVenueMemory(venueId, memoryId));

  Future<void> recordView(String memoryId) =>
      _unwrapVoid(() => _api.recordMemoryView(memoryId));

  Future<void> react(String memoryId, String emoji) =>
      _unwrapVoid(
        () => _api.reactToMemory(
          memoryId,
          ReactToMemoryRequest(emoji: emoji),
        ),
      );

  Future<void> removeReaction(String memoryId) =>
      _unwrapVoid(() => _api.removeMemoryReaction(memoryId));

  Future<void> respondToEngagement(
    String memoryId,
    EngagementResponseRequest request,
  ) =>
      _unwrapVoid(() => _api.respondToMemoryEngagement(memoryId, request));

  Future<EngagementResultsResponse> getEngagementResults(
    String memoryId, {
    int page = 0,
    int size = 50,
  }) =>
      _unwrap(
        () => _api.getMemoryEngagementResults(
          memoryId,
          page: page,
          size: size,
        ),
      );

  Future<PagedResponse<MemoryResponse>> getMyMemoryMentions({
    int page = 0,
    int size = 20,
  }) =>
      _unwrap(
        () => _api.getMyMemoryMentions(page: page, size: size),
      );

  Future<MediaUploadUrlResponse> getImageUploadUrl(String contentType) =>
      _unwrap(() => _api.getMemoryImageUploadUrl(contentType));

  Future<MediaUploadUrlResponse> getVideoUploadUrl(String contentType) =>
      _unwrap(() => _api.getMemoryVideoUploadUrl(contentType));

  Future<MediaUploadUrlResponse> getAudioUploadUrl(String contentType) =>
      _unwrap(() => _api.getMemoryAudioUploadUrl(contentType));

  Future<MediaUploadUrlResponse> getVenueImageUploadUrl(
    String venueId,
    String contentType,
  ) =>
      _unwrap(
        () => _api.getVenueMemoryImageUploadUrl(venueId, contentType),
      );

  Future<MediaUploadUrlResponse> getVenueVideoUploadUrl(
    String venueId,
    String contentType,
  ) =>
      _unwrap(
        () => _api.getVenueMemoryVideoUploadUrl(venueId, contentType),
      );

  Future<MediaUploadUrlResponse> getVenueAudioUploadUrl(
    String venueId,
    String contentType,
  ) =>
      _unwrap(
        () => _api.getVenueMemoryAudioUploadUrl(venueId, contentType),
      );

  Future<MemoryMetricsResponse> getVenueMetrics(
    String venueId,
    String memoryId,
  ) =>
      _unwrap(() => _api.getVenueMemoryMetrics(venueId, memoryId));

  Future<T> _unwrap<T>(Future<ApiResponse<T>> Function() call) async {
    try {
      final response = await call();
      if (response.success && response.data != null) {
        return response.data as T;
      }
      throw MemoryUnexpectedException(response.error ?? 'Unknown error');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> _unwrapVoid(Future<ApiResponse<dynamic>> Function() call) async {
    try {
      final response = await call();
      if (response.success) return;
      throw MemoryUnexpectedException(response.error ?? 'Unknown error');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  MemoryException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final serverMessage = _extractMessage(body);

    if (status == null) {
      return MemoryTransientException(e.message ?? 'Network error');
    }
    if (status == 400) {
      final lower = serverMessage.toLowerCase();
      if (lower.contains('engagement')) {
        return EngagementInvalidException(serverMessage);
      }
      return MemoryValidationException(serverMessage);
    }
    if (status == 403) return MemoryForbiddenException(serverMessage);
    if (status == 404) return MemoryExpiredException(serverMessage);
    if (status == 409) return MemoryTransientException(serverMessage);
    if (status >= 500) return MemoryTransientException(serverMessage);
    return MemoryUnexpectedException(serverMessage);
  }

  String _extractMessage(dynamic body) {
    if (body is Map) {
      final m = body['error'] ?? body['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    if (body is String && body.isNotEmpty) return body;
    return 'Request failed';
  }
}
