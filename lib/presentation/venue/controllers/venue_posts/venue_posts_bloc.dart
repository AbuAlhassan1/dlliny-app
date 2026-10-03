import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

part 'venue_posts_event.dart';
part 'venue_posts_state.dart';

class VenuePostsBloc extends Bloc<VenuePostsEvent, VenuePostsState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  final List<PostResponse> _items = [];
  int _nextPage = 0;
  bool _exhausted = false;

  static const int _pageSize = 20;

  VenuePostsBloc({required this.venueId})
      : super(const VenuePostsInitial()) {
    on<LoadVenuePosts>(_onLoad);
    on<LoadNextVenuePostsPage>(_onLoadNext);
  }

  Future<void> _onLoad(
    LoadVenuePosts event,
    Emitter<VenuePostsState> emit,
  ) async {
    _items.clear();
    _nextPage = 0;
    _exhausted = false;
    emit(const VenuePostsLoading());
    await _fetch(emit);
  }

  Future<void> _onLoadNext(
    LoadNextVenuePostsPage event,
    Emitter<VenuePostsState> emit,
  ) async {
    if (_exhausted) return;
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<VenuePostsState> emit) async {
    try {
      final res = await _api.listPublicVenuePosts(
        venueId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!res.success || res.data == null) {
        emit(VenuePostsError(res.error ?? 'تعذر تحميل المنشورات'));
        return;
      }
      final page = res.data!;
      _items.addAll(page.content);
      _nextPage = page.page + 1;
      _exhausted = page.last;
      emit(VenuePostsLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
      ));
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? 'تعذر تحميل المنشورات');
      emit(VenuePostsError(msg));
    }
  }
}
