part of 'order_detail_bloc.dart';

sealed class OrderDetailState {
  const OrderDetailState();
}

final class OrderDetailInitial extends OrderDetailState {
  const OrderDetailInitial();
}

final class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading();
}

final class OrderDetailError extends OrderDetailState {
  final String message;
  const OrderDetailError(this.message);
}

final class OrderDetailLoaded extends OrderDetailState {
  final OrderResponse order;
  const OrderDetailLoaded(this.order);
}

final class OrderDetailMutating extends OrderDetailState {
  final OrderResponse order;
  const OrderDetailMutating(this.order);
}

final class OrderDetailActionSucceeded extends OrderDetailState {
  final OrderResponse order;
  final String message;
  const OrderDetailActionSucceeded(this.order, this.message);
}

final class OrderDetailActionFailed extends OrderDetailState {
  final OrderResponse order;
  final String message;
  const OrderDetailActionFailed(this.order, this.message);
}
