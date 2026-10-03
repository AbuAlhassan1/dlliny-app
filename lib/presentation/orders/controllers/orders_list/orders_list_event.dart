part of 'orders_list_bloc.dart';

sealed class OrdersListEvent {
  const OrdersListEvent();
}

class LoadOrders extends OrdersListEvent {
  const LoadOrders();
}

class LoadNextPage extends OrdersListEvent {
  const LoadNextPage();
}

class SetStatusFilter extends OrdersListEvent {
  final OrderStatus? status;
  const SetStatusFilter(this.status);
}
