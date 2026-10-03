part of 'transfers_list_bloc.dart';

sealed class TransfersListEvent {
  const TransfersListEvent();
}

class LoadTransfers extends TransfersListEvent {
  const LoadTransfers();
}

class LoadMoreTransfers extends TransfersListEvent {
  const LoadMoreTransfers();
}

class SetTransfersFilter extends TransfersListEvent {
  final TransferStatus? status;
  const SetTransfersFilter(this.status);
}

class TransfersListRowMutated extends TransfersListEvent {
  final BusinessTransferResponse row;
  const TransfersListRowMutated(this.row);
}

class TransfersListRowRemoved extends TransfersListEvent {
  final String transferId;
  const TransfersListRowRemoved(this.transferId);
}
