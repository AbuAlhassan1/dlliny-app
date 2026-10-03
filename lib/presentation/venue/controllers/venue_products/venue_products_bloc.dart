import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

part 'venue_products_event.dart';
part 'venue_products_state.dart';

class VenueProductsBloc extends Bloc<VenueProductsEvent, VenueProductsState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  final List<PostResponse> _items = [];
  int _nextPage = 0;
  bool _exhausted = false;

  static const int _pageSize = 20;

  VenueProductsBloc({required this.venueId})
      : super(const VenueProductsInitial()) {
    on<LoadVenueProducts>(_onLoad);
    on<LoadNextVenueProductsPage>(_onLoadNext);
  }

  Future<void> _onLoad(
    LoadVenueProducts event,
    Emitter<VenueProductsState> emit,
  ) async {
    _items.clear();
    _nextPage = 0;
    _exhausted = false;
    emit(const VenueProductsLoading());
    await _fetch(emit);
  }

  Future<void> _onLoadNext(
    LoadNextVenueProductsPage event,
    Emitter<VenueProductsState> emit,
  ) async {
    if (_exhausted) return;
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<VenueProductsState> emit) async {
    try {
      final res = await _api.listVenueProducts(
        venueId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!res.success || res.data == null) {
        emit(VenueProductsError(res.error ?? 'تعذر تحميل المنتجات'));
        return;
      }
      final page = res.data!;
      _items.addAll(page.content);
      _nextPage = page.page + 1;
      _exhausted = page.last;
      emit(VenueProductsLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
      ));
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? 'تعذر تحميل المنتجات');
      emit(VenueProductsError(msg));
    }
  }
}
