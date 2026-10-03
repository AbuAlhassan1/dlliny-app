part of 'order_detail_bloc.dart';

sealed class OrderDetailEvent {
  const OrderDetailEvent();
}

class LoadOrder extends OrderDetailEvent {
  const LoadOrder();
}

class CancelOrderRequested extends OrderDetailEvent {
  const CancelOrderRequested();
}

class AcceptOrderRequested extends OrderDetailEvent {
  const AcceptOrderRequested();
}

class RejectOrderRequested extends OrderDetailEvent {
  const RejectOrderRequested();
}

class DeliverOrderRequested extends OrderDetailEvent {
  const DeliverOrderRequested();
}

class SendMessageRequested extends OrderDetailEvent {
  final String body;
  const SendMessageRequested(this.body);
}

class MarkMessagesReadRequested extends OrderDetailEvent {
  const MarkMessagesReadRequested();
}
