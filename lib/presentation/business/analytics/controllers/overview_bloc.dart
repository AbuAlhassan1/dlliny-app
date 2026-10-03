import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/analytics_exceptions.dart';
import 'package:hangout/core/errors/tier_exceptions.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';

sealed class OverviewEvent {
  const OverviewEvent();
}

class OverviewLoaded extends OverviewEvent {
  const OverviewLoaded();
}

class OverviewRefreshed extends OverviewEvent {
  const OverviewRefreshed();
}

class OverviewState {
  final TileState<BuzzAnalyticsResponse> buzz;
  final TileState<DailySeriesResponse> daily;
  final TileState<HangoutFunnelResponse> hangoutFunnel;

  const OverviewState({
    required this.buzz,
    required this.daily,
    required this.hangoutFunnel,
  });

  const OverviewState.initial()
      : buzz = const TileLoading(),
        daily = const TileLoading(),
        hangoutFunnel = const TileLoading();

  OverviewState copyWith({
    TileState<BuzzAnalyticsResponse>? buzz,
    TileState<DailySeriesResponse>? daily,
    TileState<HangoutFunnelResponse>? hangoutFunnel,
  }) {
    return OverviewState(
      buzz: buzz ?? this.buzz,
      daily: daily ?? this.daily,
      hangoutFunnel: hangoutFunnel ?? this.hangoutFunnel,
    );
  }
}

class OverviewBloc extends Bloc<OverviewEvent, OverviewState> {
  final AnalyticsRepository _repo;
  final String venueId;

  OverviewBloc({required AnalyticsRepository repo, required this.venueId})
      : _repo = repo,
        super(const OverviewState.initial()) {
    on<OverviewLoaded>(_onLoad);
    on<OverviewRefreshed>(_onLoad);
  }

  Future<void> _onLoad(OverviewEvent event, Emitter<OverviewState> emit) async {
    emit(state.copyWith(
      buzz: const TileLoading(),
      daily: const TileLoading(),
      hangoutFunnel: const TileLoading(),
    ));

    final results = await Future.wait([
      _safeCall<BuzzAnalyticsResponse>(() => _repo.getBuzz(venueId)),
      _safeCall<DailySeriesResponse>(() => _repo.getDaily(venueId)),
      _safeCall<HangoutFunnelResponse>(() => _repo.getHangoutFunnel(venueId)),
    ]);

    emit(state.copyWith(
      buzz: results[0] as TileState<BuzzAnalyticsResponse>,
      daily: results[1] as TileState<DailySeriesResponse>,
      hangoutFunnel: results[2] as TileState<HangoutFunnelResponse>,
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
