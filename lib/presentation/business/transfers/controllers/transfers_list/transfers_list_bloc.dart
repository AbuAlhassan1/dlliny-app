import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/business_transfer_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/transfers/utils/transfer_enums.dart';

part 'transfers_list_event.dart';
part 'transfers_list_state.dart';

enum TransfersDirection { incoming, outgoing }

class TransfersListBloc extends Bloc<TransfersListEvent, TransfersListState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final TransfersDirection direction;

  final List<BusinessTransferResponse> _items = [];
  int _nextPage = 0;
  bool _exhausted = false;
  TransferStatus? _filter = TransferStatus.pending;

  static const int _pageSize = 20;

  TransfersListBloc({required this.direction})
      : super(const TransfersListInitial()) {
    on<LoadTransfers>(_onLoad);
    on<LoadMoreTransfers>(_onLoadMore);
    on<SetTransfersFilter>(_onSetFilter);
    on<TransfersListRowMutated>(_onRowMutated);
    on<TransfersListRowRemoved>(_onRowRemoved);
  }

  Future<void> _onLoad(
    LoadTransfers event,
    Emitter<TransfersListState> emit,
  ) async {
    _items.clear();
    _nextPage = 0;
    _exhausted = false;
    emit(const TransfersListLoading());
    await _fetchPage(emit);
  }

  Future<void> _onLoadMore(
    LoadMoreTransfers event,
    Emitter<TransfersListState> emit,
  ) async {
    if (_exhausted) return;
    await _fetchPage(emit);
  }

  Future<void> _onSetFilter(
    SetTransfersFilter event,
    Emitter<TransfersListState> emit,
  ) async {
    if (event.status == _filter) return;
    _filter = event.status;
    add(const LoadTransfers());
  }

  Future<void> _onRowMutated(
    TransfersListRowMutated event,
    Emitter<TransfersListState> emit,
  ) async {
    final idx = _items.indexWhere((t) => t.id == event.row.id);
    if (idx >= 0) {
      _items[idx] = event.row;
      emit(TransfersListLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
        filter: _filter,
      ));
    }
  }

  Future<void> _onRowRemoved(
    TransfersListRowRemoved event,
    Emitter<TransfersListState> emit,
  ) async {
    final before = _items.length;
    _items.removeWhere((t) => t.id == event.transferId);
    if (_items.length != before) {
      emit(TransfersListLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
        filter: _filter,
      ));
    }
  }

  Future<void> _fetchPage(Emitter<TransfersListState> emit) async {
    try {
      final ApiResponse<PagedResponse<BusinessTransferResponse>> res;
      final statusArg = _filter?.wire ?? 'pending';
      if (direction == TransfersDirection.incoming) {
        res = await _api.getIncomingBusinessTransfers(
          status: statusArg,
          page: _nextPage,
          size: _pageSize,
        );
      } else {
        res = await _api.getOutgoingBusinessTransfers(
          status: statusArg,
          page: _nextPage,
          size: _pageSize,
        );
      }
      if (!res.success || res.data == null) {
        emit(TransfersListError(res.error ?? LocaleKeys.business_transfers_load_error.tr()));
        return;
      }
      final page = res.data!;
      _items.addAll(page.content);
      _nextPage = page.page + 1;
      _exhausted = page.last;
      emit(TransfersListLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
        filter: _filter,
      ));
    } on DioException catch (e) {
      emit(TransfersListError(_msg(e, LocaleKeys.business_transfers_load_error.tr())));
    }
  }

  String _msg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
