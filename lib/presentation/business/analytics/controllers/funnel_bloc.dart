import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/analytics_exceptions.dart';
import 'package:hangout/core/errors/tier_exceptions.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';

sealed class FunnelEvent {
  const FunnelEvent();
}

class FunnelLoaded extends FunnelEvent {
  const FunnelLoaded();
}

class FunnelRefreshed extends FunnelEvent {
  const FunnelRefreshed();
}

class FunnelState {
  final TileState<ConversionFunnelResponse> funnel;
  final TileState<FootfallHeatmapResponse> footfall;

  const FunnelState({required this.funnel, required this.footfall});

  const FunnelState.initial()
      : funnel = const TileLoading(),
        footfall = const TileLoading();

  FunnelState copyWith({
    TileState<ConversionFunnelResponse>? funnel,
    TileState<FootfallHeatmapResponse>? footfall,
  }) {
    return FunnelState(
      funnel: funnel ?? this.funnel,
      footfall: footfall ?? this.footfall,
    );
  }
}

class FunnelBloc extends Bloc<FunnelEvent, FunnelState> {
  final AnalyticsRepository _repo;
  final String venueId;

  FunnelBloc({required AnalyticsRepository repo, required this.venueId})
      : _repo = repo,
        super(const FunnelState.initial()) {
    on<FunnelLoaded>(_onLoad);
    on<FunnelRefreshed>(_onLoad);
  }

  Future<void> _onLoad(FunnelEvent event, Emitter<FunnelState> emit) async {
    emit(state.copyWith(
      funnel: const TileLoading(),
      footfall: const TileLoading(),
    ));

    final results = await Future.wait([
      _safeCall<ConversionFunnelResponse>(
        () => _repo.getConversionFunnel(venueId),
      ),
      _safeCall<FootfallHeatmapResponse>(
        () => _repo.getFootfall(venueId),
      ),
    ]);

    emit(state.copyWith(
      funnel: results[0] as TileState<ConversionFunnelResponse>,
      footfall: results[1] as TileState<FootfallHeatmapResponse>,
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
