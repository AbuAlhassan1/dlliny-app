import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/analytics_exceptions.dart';
import 'package:hangout/core/errors/tier_exceptions.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';

sealed class ContentEvent {
  const ContentEvent();
}

class ContentLoaded extends ContentEvent {
  const ContentLoaded();
}

class ContentRefreshed extends ContentEvent {
  const ContentRefreshed();
}

class ContentState {
  final TileState<TopPostsResponse> topPosts;
  final TileState<TopMemoriesResponse> topMemories;
  final TileState<ReviewTrendResponse> reviewTrend;

  const ContentState({
    required this.topPosts,
    required this.topMemories,
    required this.reviewTrend,
  });

  const ContentState.initial()
      : topPosts = const TileLoading(),
        topMemories = const TileLoading(),
        reviewTrend = const TileLoading();

  ContentState copyWith({
    TileState<TopPostsResponse>? topPosts,
    TileState<TopMemoriesResponse>? topMemories,
    TileState<ReviewTrendResponse>? reviewTrend,
  }) {
    return ContentState(
      topPosts: topPosts ?? this.topPosts,
      topMemories: topMemories ?? this.topMemories,
      reviewTrend: reviewTrend ?? this.reviewTrend,
    );
  }
}

class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final AnalyticsRepository _repo;
  final String venueId;

  ContentBloc({required AnalyticsRepository repo, required this.venueId})
      : _repo = repo,
        super(const ContentState.initial()) {
    on<ContentLoaded>(_onLoad);
    on<ContentRefreshed>(_onLoad);
  }

  Future<void> _onLoad(ContentEvent event, Emitter<ContentState> emit) async {
    emit(state.copyWith(
      topPosts: const TileLoading(),
      topMemories: const TileLoading(),
      reviewTrend: const TileLoading(),
    ));

    final results = await Future.wait([
      _safeCall<TopPostsResponse>(() => _repo.getTopPosts(venueId)),
      _safeCall<TopMemoriesResponse>(() => _repo.getTopMemories(venueId)),
      _safeCall<ReviewTrendResponse>(() => _repo.getReviewTrend(venueId)),
    ]);

    emit(state.copyWith(
      topPosts: results[0] as TileState<TopPostsResponse>,
      topMemories: results[1] as TileState<TopMemoriesResponse>,
      reviewTrend: results[2] as TileState<ReviewTrendResponse>,
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
