import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/response/weekly_recommendations_response.dart';

part 'weekly_venues_event.dart';
part 'weekly_venues_state.dart';

class WeeklyVenuesBloc extends Bloc<WeeklyVenuesEvent, WeeklyVenuesState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final AppCacheRepository _cache = serviceLocator.get<AppCacheRepository>();

  WeeklyVenuesBloc() : super(const WeeklyVenuesInitial()) {
    on<LoadWeeklyVenues>(_onLoad);
  }

  Future<void> _onLoad(
    LoadWeeklyVenues event,
    Emitter<WeeklyVenuesState> emit,
  ) async {
    final cached = await _readCache();
    if (cached != null && cached.items.isNotEmpty) {
      emit(WeeklyVenuesLoaded(
        items: cached.items,
        weekStartsAt: cached.weekStartsAt,
        isFallback: cached.isFallback,
        isRefreshing: true,
      ));
    } else {
      emit(const WeeklyVenuesLoading());
    }

    try {
      final response = await _api.getMyWeeklyRecommendations();
      if (!response.success || response.data == null) {
        _keepCacheOrError(emit, cached);
        return;
      }
      final payload = response.data!;
      if (payload.items.isEmpty) {
        await _cache.remove(HubCacheKeys.weeklyVenues);
        emit(const WeeklyVenuesEmpty());
        return;
      }
      await _cache.write(HubCacheKeys.weeklyVenues, payload.toJson());
      emit(WeeklyVenuesLoaded(
        items: payload.items,
        weekStartsAt: payload.weekStartsAt,
        isFallback: payload.isFallback,
      ));
    } on DioException catch (_) {
      _keepCacheOrError(emit, cached);
    } catch (_) {
      _keepCacheOrError(emit, cached);
    }
  }

  void _keepCacheOrError(
    Emitter<WeeklyVenuesState> emit,
    WeeklyRecommendationsResponse? cached,
  ) {
    if (cached != null && cached.items.isNotEmpty) {
      emit(WeeklyVenuesLoaded(
        items: cached.items,
        weekStartsAt: cached.weekStartsAt,
        isFallback: cached.isFallback,
      ));
    } else {
      emit(const WeeklyVenuesError());
    }
  }

  Future<WeeklyRecommendationsResponse?> _readCache() async {
    final raw = await _cache.read(HubCacheKeys.weeklyVenues);
    if (raw is! Map<String, dynamic>) return null;
    try {
      return WeeklyRecommendationsResponse.fromJson(raw);
    } catch (_) {
      return null;
    }
  }
}
