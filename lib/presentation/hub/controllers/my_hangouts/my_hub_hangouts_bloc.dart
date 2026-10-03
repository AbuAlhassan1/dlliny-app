import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';

part 'my_hub_hangouts_event.dart';
part 'my_hub_hangouts_state.dart';

class MyHubHangoutsBloc
    extends Bloc<MyHubHangoutsEvent, MyHubHangoutsState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  static const int _pageSize = 20;

  List<HangoutFeedItem> items = [];
  int _page = 0;
  bool _hasMore = true;

  MyHubHangoutsBloc() : super(const MyHubHangoutsInitial()) {
    on<LoadMyHubHangouts>(_onLoad);
    on<LoadMoreMyHubHangouts>(_onLoadMore);
  }

  Future<void> _onLoad(
    LoadMyHubHangouts event,
    Emitter<MyHubHangoutsState> emit,
  ) async {
    emit(const MyHubHangoutsLoading());
    try {
      final res = await _api.getMyHangoutsHub(page: 0, size: _pageSize);
      if (!res.success || res.data == null) {
        emit(MyHubHangoutsError(res.error ?? 'Failed to load'));
        return;
      }
      items = res.data!.items;
      _page = 0;
      _hasMore = res.data!.hasMore;
      if (items.isEmpty) {
        emit(const MyHubHangoutsEmpty());
      } else {
        emit(MyHubHangoutsLoaded(items: items, hasMore: _hasMore));
      }
    } on DioException catch (e) {
      emit(MyHubHangoutsError('Failed to load: $e'));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreMyHubHangouts event,
    Emitter<MyHubHangoutsState> emit,
  ) async {
    if (!_hasMore) return;
    if (state is! MyHubHangoutsLoaded) return;
    emit(MyHubHangoutsLoaded(
      items: items,
      hasMore: _hasMore,
      loadingMore: true,
    ));
    try {
      final res = await _api.getMyHangoutsHub(
        page: _page + 1,
        size: _pageSize,
      );
      if (!res.success || res.data == null) {
        emit(MyHubHangoutsLoaded(items: items, hasMore: _hasMore));
        return;
      }
      _page += 1;
      _hasMore = res.data!.hasMore;
      items = [...items, ...res.data!.items];
      emit(MyHubHangoutsLoaded(items: items, hasMore: _hasMore));
    } on DioException catch (_) {
      emit(MyHubHangoutsLoaded(items: items, hasMore: _hasMore));
    }
  }
}
