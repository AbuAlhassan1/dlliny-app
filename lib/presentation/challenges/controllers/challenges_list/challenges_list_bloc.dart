import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/challenge_enums.dart';
import 'package:hangout/domain/dto/response/challenge_list_item_response.dart';

part 'challenges_list_event.dart';
part 'challenges_list_state.dart';

class ChallengesListBloc extends Bloc<ChallengesListEvent, ChallengesListState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  final AppCacheRepository _cache = serviceLocator.get<AppCacheRepository>();

  final Map<ChallengeCadence?, List<ChallengeListItemResponse>> _byCadence = {};

  ChallengesListBloc() : super(const ChallengesListInitial()) {
    on<ChallengesListEvent>((event, emit) {});

    on<LoadChallenges>((event, emit) async {
      final cadence = event.cadence;

      if (cadence == null && (_byCadence[null]?.isEmpty ?? true)) {
        final cached = await _readCachedChallenges();
        if (cached != null && cached.isNotEmpty) {
          _byCadence[null] = cached;
          emit(ChallengesListLoaded(
            cadence: null,
            byCadence: Map.unmodifiable(_byCadence),
          ));
        }
      }

      if (_byCadence[cadence]?.isNotEmpty != true) {
        emit(ChallengesListLoading(
          cadence: cadence,
          byCadence: Map.unmodifiable(_byCadence),
        ));
      }

      ApiResponse<List<ChallengeListItemResponse>> response;
      try {
        response = await apiService.getChallenges(
          cadence: _cadenceToWire(cadence),
        );
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(_byCadence[cadence]?.isNotEmpty == true
            ? ChallengesListLoaded(
                cadence: cadence,
                byCadence: Map.unmodifiable(_byCadence),
              )
            : ChallengesListError(
                cadence: cadence,
                message: 'Failed to load challenges',
                byCadence: Map.unmodifiable(_byCadence),
              ));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _byCadence[cadence] = response.data!;
        if (cadence == null) {
          await _cache.write(
            AppCacheKeys.challenges,
            response.data!.map((e) => e.toJson()).toList(),
          );
        }
        emit(ChallengesListLoaded(
          cadence: cadence,
          byCadence: Map.unmodifiable(_byCadence),
        ));
      } else if (_byCadence[cadence]?.isNotEmpty == true) {
        emit(ChallengesListLoaded(
          cadence: cadence,
          byCadence: Map.unmodifiable(_byCadence),
        ));
      } else {
        emit(ChallengesListError(
          cadence: cadence,
          message: response.error ?? 'Failed to load challenges',
          byCadence: Map.unmodifiable(_byCadence),
        ));
      }
    });
  }

  Future<List<ChallengeListItemResponse>?> _readCachedChallenges() async {
    try {
      final raw = await _cache.read(AppCacheKeys.challenges);
      if (raw is List) {
        return raw
            .map((e) => ChallengeListItemResponse.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
    }
    return null;
  }

  String? _cadenceToWire(ChallengeCadence? c) {
    return switch (c) {
      null => null,
      ChallengeCadence.daily => 'DAILY',
      ChallengeCadence.weekly => 'WEEKLY',
      ChallengeCadence.monthly => 'MONTHLY',
      ChallengeCadence.seasonal => 'SEASONAL',
      ChallengeCadence.special => 'SPECIAL',
    };
  }
}
