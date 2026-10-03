import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/order_response.dart';

part 'orders_list_event.dart';
part 'orders_list_state.dart';

enum OrdersListMode { myOrders, venueInbox }

class OrdersListBloc extends Bloc<OrdersListEvent, OrdersListState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final OrdersListMode mode;

  final String? venueId;

  final List<OrderSummaryResponse> _items = [];
  int _nextPage = 0;
  bool _exhausted = false;
  OrderStatus? _filter;

  static const int _pageSize = 20;

  OrdersListBloc({required this.mode, this.venueId})
      : assert(
          mode == OrdersListMode.myOrders || venueId != null,
          'venueId is required for venueInbox',
        ),
        super(const OrdersListInitial()) {
    on<LoadOrders>(_onLoad);
    on<LoadNextPage>(_onLoadNext);
    on<SetStatusFilter>(_onSetFilter);
  }

  Future<void> _onLoad(
    LoadOrders event,
    Emitter<OrdersListState> emit,
  ) async {
    _items.clear();
    _nextPage = 0;
    _exhausted = false;
    emit(const OrdersListLoading());
    await _fetchPage(emit);
  }

  Future<void> _onLoadNext(
    LoadNextPage event,
    Emitter<OrdersListState> emit,
  ) async {
    if (_exhausted) return;
    await _fetchPage(emit);
  }

  Future<void> _onSetFilter(
    SetStatusFilter event,
    Emitter<OrdersListState> emit,
  ) async {
    if (event.status == _filter) return;
    _filter = event.status;
    add(const LoadOrders());
  }

  Future<void> _fetchPage(Emitter<OrdersListState> emit) async {
    try {
      final res = await _call(_nextPage);
      if (!res.success || res.data == null) {
        emit(OrdersListError(res.error ?? 'تعذر تحميل الطلبات'));
        return;
      }
      final page = res.data!;
      _items.addAll(page.content);
      _nextPage = page.page + 1;
      _exhausted = page.last;
      emit(OrdersListLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
        filter: _filter,
      ));
    } on DioException catch (e) {
      emit(OrdersListError(_msg(e, 'تعذر تحميل الطلبات')));
    }
  }

  Future<ApiResponse<PagedResponse<OrderSummaryResponse>>> _call(int page) {
    if (mode == OrdersListMode.myOrders) {
      return _api.getMyOrders(
        status: _filter?.name.toUpperCase(),
        page: page,
        size: _pageSize,
      );
    }
    return _api.listVenueOrders(
      venueId!,
      status: _filter?.name.toUpperCase(),
      page: page,
      size: _pageSize,
    );
  }

  String _msg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
