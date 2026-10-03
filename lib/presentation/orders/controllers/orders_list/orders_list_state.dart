part of 'orders_list_bloc.dart';

sealed class OrdersListState {
  const OrdersListState();
}

final class OrdersListInitial extends OrdersListState {
  const OrdersListInitial();
}

final class OrdersListLoading extends OrdersListState {
  const OrdersListLoading();
}

final class OrdersListError extends OrdersListState {
  final String message;
  const OrdersListError(this.message);
}

final class OrdersListLoaded extends OrdersListState {
  final List<OrderSummaryResponse> items;
  final bool hasMore;
  final OrderStatus? filter;
  const OrdersListLoaded({
    required this.items,
    required this.hasMore,
    required this.filter,
  });
}
