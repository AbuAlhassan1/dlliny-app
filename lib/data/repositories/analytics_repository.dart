import 'package:dio/dio.dart';
import 'package:hangout/core/errors/analytics_exceptions.dart';
import 'package:hangout/core/errors/tier_exceptions.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';

class AnalyticsRepository {
  final ApiService _api;
  AnalyticsRepository(this._api);

  Future<BuzzAnalyticsResponse> getBuzz(String venueId) =>
      _unwrap(() => _api.getVenueBuzzAnalytics(venueId));

  Future<DailySeriesResponse> getDaily(
    String venueId, {
    String? from,
    String? to,
  }) =>
      _unwrap(() => _api.getVenueDailyAnalytics(venueId, from: from, to: to));

  Future<HangoutFunnelResponse> getHangoutFunnel(
    String venueId, {
    String? from,
    String? to,
  }) =>
      _unwrap(
        () => _api.getVenueHangoutFunnel(venueId, from: from, to: to),
      );

  Future<TopPostsResponse> getTopPosts(
    String venueId, {
    int days = 30,
    int size = 5,
  }) =>
      _unwrap(() => _api.getVenueTopPosts(venueId, days: days, size: size));

  Future<TopMemoriesResponse> getTopMemories(
    String venueId, {
    int size = 5,
  }) =>
      _unwrap(() => _api.getVenueTopMemories(venueId, size: size));

  Future<ReviewTrendResponse> getReviewTrend(
    String venueId, {
    int days = 30,
  }) =>
      _unwrap(() => _api.getVenueReviewTrend(venueId, days: days));

  Future<FootfallHeatmapResponse> getFootfall(String venueId) =>
      _unwrap(() => _api.getVenueFootfallHeatmap(venueId));

  Future<ConversionFunnelResponse> getConversionFunnel(
    String venueId, {
    String? from,
    String? to,
  }) =>
      _unwrap(
        () => _api.getVenueConversionFunnel(venueId, from: from, to: to),
      );

  Future<CategoryLeaderboardResponse> getLeaderboard(
    String venueId, {
    int size = 10,
  }) =>
      _unwrap(() => _api.getVenueLeaderboard(venueId, size: size));

  Future<MoversResponse> getMovers(
    String venueId, {
    String direction = 'risers',
    int size = 5,
  }) =>
      _unwrap(
        () => _api.getVenueMovers(venueId, direction: direction, size: size),
      );

  Future<PeerBenchmarkResponse> getPeerBenchmark(
    String venueId, {
    int weeks = 4,
  }) =>
      _unwrap(() => _api.getVenuePeerBenchmark(venueId, weeks: weeks));

  Future<AudienceDemographicsResponse> getDemographics(String venueId) =>
      _unwrap(() => _api.getVenueAudienceDemographics(venueId));

  Future<AudienceActivityResponse> getAudienceActivity(String venueId) =>
      _unwrap(() => _api.getVenueAudienceActivity(venueId));

  Future<LoyalistsResponse> getLoyalists(
    String venueId, {
    int days = 30,
    int minMentions = 3,
    int page = 0,
    int size = 20,
  }) =>
      _unwrap(
        () => _api.getVenueLoyalists(
          venueId,
          days: days,
          minMentions: minMentions,
          page: page,
          size: size,
        ),
      );

  Future<T> _unwrap<T>(Future<ApiResponse<T>> Function() call) async {
    try {
      final response = await call();
      if (response.success && response.data != null) {
        return response.data as T;
      }
      final tier = tierUpgradeFromMessage(response.error);
      if (tier != null) throw tier;
      throw AnalyticsUnexpectedException(response.error ?? 'Unknown error');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final serverMessage = _extractMessage(e.response?.data);

    if (status == 402) {
      final tier = tierUpgradeFromMessage(serverMessage);
      if (tier != null) return tier;
      return const TierUpgradeRequiredException('Pro feature');
    }

    if (status == null) {
      return AnalyticsTransientException(e.message ?? 'Network error');
    }
    if (status == 400) return AnalyticsValidationException(serverMessage);
    if (status == 403) return AnalyticsForbiddenException(serverMessage);
    if (status == 404) return AnalyticsNotFoundException(serverMessage);
    if (status >= 500) return AnalyticsTransientException(serverMessage);
    return AnalyticsUnexpectedException(serverMessage);
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
