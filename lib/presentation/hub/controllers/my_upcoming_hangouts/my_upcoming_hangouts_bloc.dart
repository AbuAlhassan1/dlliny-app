import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';

part 'my_upcoming_hangouts_event.dart';
part 'my_upcoming_hangouts_state.dart';

class MyUpcomingHangoutsBloc
    extends Bloc<MyUpcomingHangoutsEvent, MyUpcomingHangoutsState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  static const int _pageSize = 20;

  List<HangoutFeedItem> items = [];
  int _page = 0;
  bool _hasMore = true;

  MyUpcomingHangoutsBloc()
      : super(const MyUpcomingHangoutsInitial()) {
    on<LoadMyUpcomingHangouts>(_onLoad);
    on<LoadMoreMyUpcomingHangouts>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadMyUpcomingHangouts event,
    Emitter<MyUpcomingHangoutsState> emit,
  ) async {
    emit(const MyUpcomingHangoutsLoading());
    try {
      final res = await _api.getMyUpcomingHangouts(page: 0, size: _pageSize);
      if (!res.success || res.data == null) {
        emit(MyUpcomingHangoutsError(res.error ?? 'Failed to load'));
        return;
      }
      items = res.data!.items;
      _page = 0;
      _hasMore = res.data!.hasMore;
      if (items.isEmpty) {
        emit(const MyUpcomingHangoutsEmpty());
      } else {
        emit(MyUpcomingHangoutsLoaded(items: items, hasMore: _hasMore));
      }
    } on DioException catch (e) {
      emit(MyUpcomingHangoutsError('Failed to load: $e'));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreMyUpcomingHangouts event,
    Emitter<MyUpcomingHangoutsState> emit,
  ) async {
    if (!_hasMore) return;
    if (state is! MyUpcomingHangoutsLoaded) return;
    emit(MyUpcomingHangoutsLoaded(
      items: items,
      hasMore: _hasMore,
      loadingMore: true,
    ));
    try {
      final res = await _api.getMyUpcomingHangouts(
        page: _page + 1,
        size: _pageSize,
      );
      if (!res.success || res.data == null) {
        emit(MyUpcomingHangoutsLoaded(items: items, hasMore: _hasMore));
        return;
      }
      _page += 1;
      _hasMore = res.data!.hasMore;
      items = [...items, ...res.data!.items];
      emit(MyUpcomingHangoutsLoaded(items: items, hasMore: _hasMore));
    } on DioException catch (_) {
      emit(MyUpcomingHangoutsLoaded(items: items, hasMore: _hasMore));
    }
  }
}
