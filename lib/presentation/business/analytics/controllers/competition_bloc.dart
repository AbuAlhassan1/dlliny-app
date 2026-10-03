import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/analytics_exceptions.dart';
import 'package:hangout/core/errors/tier_exceptions.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';

sealed class CompetitionEvent {
  const CompetitionEvent();
}

class CompetitionLoaded extends CompetitionEvent {
  const CompetitionLoaded();
}

class CompetitionRefreshed extends CompetitionEvent {
  const CompetitionRefreshed();
}

class CompetitionState {
  final TileState<CategoryLeaderboardResponse> leaderboard;
  final TileState<MoversResponse> movers;
  final TileState<PeerBenchmarkResponse> peerBenchmark;

  const CompetitionState({
    required this.leaderboard,
    required this.movers,
    required this.peerBenchmark,
  });

  const CompetitionState.initial()
      : leaderboard = const TileLoading(),
        movers = const TileLoading(),
        peerBenchmark = const TileLoading();

  CompetitionState copyWith({
    TileState<CategoryLeaderboardResponse>? leaderboard,
    TileState<MoversResponse>? movers,
    TileState<PeerBenchmarkResponse>? peerBenchmark,
  }) {
    return CompetitionState(
      leaderboard: leaderboard ?? this.leaderboard,
      movers: movers ?? this.movers,
      peerBenchmark: peerBenchmark ?? this.peerBenchmark,
    );
  }
}

class CompetitionBloc extends Bloc<CompetitionEvent, CompetitionState> {
  final AnalyticsRepository _repo;
  final String venueId;

  CompetitionBloc({required AnalyticsRepository repo, required this.venueId})
      : _repo = repo,
        super(const CompetitionState.initial()) {
    on<CompetitionLoaded>(_onLoad);
    on<CompetitionRefreshed>(_onLoad);
  }

  Future<void> _onLoad(
    CompetitionEvent event,
    Emitter<CompetitionState> emit,
  ) async {
    emit(state.copyWith(
      leaderboard: const TileLoading(),
      movers: const TileLoading(),
      peerBenchmark: const TileLoading(),
    ));

    final results = await Future.wait([
      _safeCall<CategoryLeaderboardResponse>(
        () => _repo.getLeaderboard(venueId),
      ),
      _safeCall<MoversResponse>(() => _repo.getMovers(venueId)),
      _safeCall<PeerBenchmarkResponse>(() => _repo.getPeerBenchmark(venueId)),
    ]);

    emit(state.copyWith(
      leaderboard: results[0] as TileState<CategoryLeaderboardResponse>,
      movers: results[1] as TileState<MoversResponse>,
      peerBenchmark: results[2] as TileState<PeerBenchmarkResponse>,
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
