import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/response/intent_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';

part 'intents_event.dart';
part 'intents_state.dart';

class HubIntentsBloc extends Bloc<HubIntentsEvent, HubIntentsState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final AppCacheRepository _cache = serviceLocator.get<AppCacheRepository>();

  static const int _venuesPageSize = 20;

  HubIntentsBloc() : super(const HubIntentsInitial()) {
    on<LoadIntents>(_onLoad);
    on<SelectHubIntent>(_onSelect);
  }

  Future<void> _onLoad(
    LoadIntents event,
    Emitter<HubIntentsState> emit,
  ) async {
    final cached = await _readCache();
    if (cached != null && cached.intents.isNotEmpty) {
      emit(HubIntentsReady(
        intents: cached.intents,
        selectedCode: null,
        venuesPhase: HubIntentVenuesPhase.idle,
        venues: const [],
        hasNoMatches: false,
        isRefreshing: true,
      ));
    } else {
      emit(const HubIntentsListLoading());
    }

    try {
      final response = await _api.getIntents();
      if (!response.success || response.data == null) {
        _keepIntentsCacheOrError(emit, cached);
        return;
      }
      final intents = response.data!.where((i) => i.active).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (intents.isEmpty) {
        await _cache.remove(HubCacheKeys.intents);
        emit(const HubIntentsError());
        return;
      }
      await _cache.write(HubCacheKeys.intents, {
        'intents': intents.map((i) => i.toJson()).toList(),
      });
      emit(HubIntentsReady(
        intents: intents,
        selectedCode: null,
        venuesPhase: HubIntentVenuesPhase.idle,
        venues: const [],
        hasNoMatches: false,
      ));
    } on DioException catch (_) {
      _keepIntentsCacheOrError(emit, cached);
    } catch (_) {
      _keepIntentsCacheOrError(emit, cached);
    }
  }

  void _keepIntentsCacheOrError(
    Emitter<HubIntentsState> emit,
    _CachedIntents? cached,
  ) {
    if (cached != null && cached.intents.isNotEmpty) {
      emit(HubIntentsReady(
        intents: cached.intents,
        selectedCode: null,
        venuesPhase: HubIntentVenuesPhase.idle,
        venues: const [],
        hasNoMatches: false,
      ));
    } else {
      emit(const HubIntentsError());
    }
  }

  Future<void> _onSelect(
    SelectHubIntent event,
    Emitter<HubIntentsState> emit,
  ) async {
    final current = state;
    if (current is! HubIntentsReady) return;
    if (current.selectedCode == event.code) return;
    emit(HubIntentsReady(
      intents: current.intents,
      selectedCode: event.code,
      venuesPhase: HubIntentVenuesPhase.loading,
      venues: const [],
      hasNoMatches: false,
    ));
    await _fetchVenues(event.code, current.intents, emit);
  }

  Future<void> _fetchVenues(
    String code,
    List<IntentResponse> intents,
    Emitter<HubIntentsState> emit,
  ) async {
    try {
      final response = await _api.getVenuesForIntent(
        code,
        size: _venuesPageSize,
      );
      final current = state;
      if (current is! HubIntentsReady || current.selectedCode != code) {
        return;
      }
      if (!response.success || response.data == null) {
        emit(HubIntentsReady(
          intents: intents,
          selectedCode: code,
          venuesPhase: HubIntentVenuesPhase.error,
          venues: const [],
          hasNoMatches: false,
        ));
        return;
      }
      final payload = response.data!;
      if (code == intents.first.code) {
        await _cache.write(HubCacheKeys.intents, {
          'intents': intents.map((i) => i.toJson()).toList(),
          'selectedCode': code,
          'venues': payload.venues.content.map((v) => v.toJson()).toList(),
          'hasNoMatches': payload.hasNoMatches,
        });
      }
      emit(HubIntentsReady(
        intents: intents,
        selectedCode: code,
        venuesPhase: HubIntentVenuesPhase.loaded,
        venues: payload.venues.content,
        hasNoMatches: payload.hasNoMatches,
      ));
    } on DioException catch (_) {
      final current = state;
      if (current is! HubIntentsReady || current.selectedCode != code) {
        return;
      }
      emit(HubIntentsReady(
        intents: intents,
        selectedCode: code,
        venuesPhase: HubIntentVenuesPhase.error,
        venues: const [],
        hasNoMatches: false,
      ));
    } catch (_) {
      final current = state;
      if (current is! HubIntentsReady || current.selectedCode != code) {
        return;
      }
      emit(HubIntentsReady(
        intents: intents,
        selectedCode: code,
        venuesPhase: HubIntentVenuesPhase.error,
        venues: const [],
        hasNoMatches: false,
      ));
    }
  }

  Future<_CachedIntents?> _readCache() async {
    final raw = await _cache.read(HubCacheKeys.intents);
    if (raw is! Map) return null;
    try {
      final intents = ((raw['intents'] as List?) ?? const [])
          .map((e) => IntentResponse.fromJson(e as Map<String, dynamic>))
          .toList();
      if (intents.isEmpty) return null;
      final venues = ((raw['venues'] as List?) ?? const [])
          .map((e) => VenueSummaryResponse.fromJson(e as Map<String, dynamic>))
          .toList();
      return _CachedIntents(
        intents: intents,
        selectedCode: raw['selectedCode'] as String? ?? intents.first.code,
        venues: venues,
        hasNoMatches: raw['hasNoMatches'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

class _CachedIntents {
  final List<IntentResponse> intents;
  final String selectedCode;
  final List<VenueSummaryResponse> venues;
  final bool hasNoMatches;
  const _CachedIntents({
    required this.intents,
    required this.selectedCode,
    required this.venues,
    required this.hasNoMatches,
  });
}
