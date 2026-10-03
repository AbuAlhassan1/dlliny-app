import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/analytics_exceptions.dart';
import 'package:hangout/core/errors/tier_exceptions.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';

sealed class AudienceEvent {
  const AudienceEvent();
}

class AudienceLoaded extends AudienceEvent {
  const AudienceLoaded();
}

class AudienceRefreshed extends AudienceEvent {
  const AudienceRefreshed();
}

class AudienceState {
  final TileState<AudienceDemographicsResponse> demographics;
  final TileState<AudienceActivityResponse> activity;
  final TileState<LoyalistsResponse> loyalists;

  const AudienceState({
    required this.demographics,
    required this.activity,
    required this.loyalists,
  });

  const AudienceState.initial()
      : demographics = const TileLoading(),
        activity = const TileLoading(),
        loyalists = const TileLoading();

  AudienceState copyWith({
    TileState<AudienceDemographicsResponse>? demographics,
    TileState<AudienceActivityResponse>? activity,
    TileState<LoyalistsResponse>? loyalists,
  }) {
    return AudienceState(
      demographics: demographics ?? this.demographics,
      activity: activity ?? this.activity,
      loyalists: loyalists ?? this.loyalists,
    );
  }
}

class AudienceBloc extends Bloc<AudienceEvent, AudienceState> {
  final AnalyticsRepository _repo;
  final String venueId;

  AudienceBloc({required AnalyticsRepository repo, required this.venueId})
      : _repo = repo,
        super(const AudienceState.initial()) {
    on<AudienceLoaded>(_onLoad);
    on<AudienceRefreshed>(_onLoad);
  }

  Future<void> _onLoad(
    AudienceEvent event,
    Emitter<AudienceState> emit,
  ) async {
    emit(state.copyWith(
      demographics: const TileLoading(),
      activity: const TileLoading(),
      loyalists: const TileLoading(),
    ));

    final results = await Future.wait([
      _safeCall<AudienceDemographicsResponse>(
        () => _repo.getDemographics(venueId),
      ),
      _safeCall<AudienceActivityResponse>(
        () => _repo.getAudienceActivity(venueId),
      ),
      _safeCall<LoyalistsResponse>(() => _repo.getLoyalists(venueId)),
    ]);

    emit(state.copyWith(
      demographics: results[0] as TileState<AudienceDemographicsResponse>,
      activity: results[1] as TileState<AudienceActivityResponse>,
      loyalists: results[2] as TileState<LoyalistsResponse>,
    ));
  }

  Future<TileState<T>> _safeCall<T>(Future<T> Function() call) async {
    try {
      final data = await call();
      return TileData<T>(data);
    } on TierUpgradeRequiredException catch (e) {
      return TileProLocked<T>(e.feature);
    } on AnalyticsException catch (e) {
      return TileError<T>(e.message);
    } catch (e) {
      return TileError<T>(e.toString());
    }
  }
}
