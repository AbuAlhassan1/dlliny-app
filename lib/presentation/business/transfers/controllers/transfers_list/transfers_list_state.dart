part of 'transfers_list_bloc.dart';

sealed class TransfersListState {
  const TransfersListState();
}

final class TransfersListInitial extends TransfersListState {
  const TransfersListInitial();
}

final class TransfersListLoading extends TransfersListState {
  const TransfersListLoading();
}

final class TransfersListError extends TransfersListState {
  final String message;
  const TransfersListError(this.message);
}

final class TransfersListLoaded extends TransfersListState {
  final List<BusinessTransferResponse> items;
  final bool hasMore;
  final TransferStatus? filter;
  const TransfersListLoaded({
    required this.items,
    required this.hasMore,
    required this.filter,
  });
}
