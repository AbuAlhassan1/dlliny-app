import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/send_order_message_request.dart';
import 'package:hangout/domain/dto/response/order_response.dart';

part 'order_detail_event.dart';
part 'order_detail_state.dart';

enum OrderViewerSide { customer, venue }

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String orderId;
  final OrderViewerSide side;

  final String? venueId;

  OrderResponse? _order;

  OrderDetailBloc({
    required this.orderId,
    required this.side,
    this.venueId,
  })  : assert(
          side == OrderViewerSide.customer || venueId != null,
          'venueId is required when side == venue',
        ),
        super(const OrderDetailInitial()) {
    on<LoadOrder>(_onLoad);
    on<CancelOrderRequested>(_onCancel);
    on<AcceptOrderRequested>(_onAccept);
    on<RejectOrderRequested>(_onReject);
    on<DeliverOrderRequested>(_onDeliver);
    on<SendMessageRequested>(_onSendMessage);
    on<MarkMessagesReadRequested>(_onMarkRead);
  }

  Future<void> _onLoad(
    LoadOrder event,
    Emitter<OrderDetailState> emit,
  ) async {
    if (_order == null) emit(const OrderDetailLoading());
    try {
      final res = side == OrderViewerSide.customer
          ? await _api.getOrder(orderId)
          : await _api.getVenueOrder(venueId!, orderId);
      if (!res.success || res.data == null) {
        emit(OrderDetailError(res.error ?? 'تعذر تحميل الطلب'));
        return;
      }
      _order = res.data;
      emit(OrderDetailLoaded(_order!));
    } on DioException catch (e) {
      emit(OrderDetailError(_msg(e, 'تعذر تحميل الطلب')));
    }
  }

  Future<void> _onCancel(
    CancelOrderRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    await _runTransition(
      emit,
      label: 'إلغاء الطلب',
      success: 'تم إلغاء الطلب',
      call: () => side == OrderViewerSide.customer
          ? _api.cancelOrder(orderId)
          : _api.cancelVenueOrder(venueId!, orderId),
    );
  }

  Future<void> _onAccept(
    AcceptOrderRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    await _runTransition(
      emit,
      label: 'قبول الطلب',
      success: 'تم قبول الطلب',
      call: () => _api.acceptOrder(venueId!, orderId),
    );
  }

  Future<void> _onReject(
    RejectOrderRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    await _runTransition(
      emit,
      label: 'رفض الطلب',
      success: 'تم رفض الطلب',
      call: () => _api.rejectOrder(venueId!, orderId),
    );
  }

  Future<void> _onDeliver(
    DeliverOrderRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    await _runTransition(
      emit,
      label: 'تأكيد التسليم',
      success: 'تم تأكيد التسليم',
      call: () => _api.deliverOrder(venueId!, orderId),
    );
  }

  Future<void> _runTransition(
    Emitter<OrderDetailState> emit, {
    required String label,
    required String success,
    required Future<dynamic> Function() call,
  }) async {
    final current = _order;
    if (current == null) return;
    emit(OrderDetailMutating(current));
    try {
      final dynamic res = await call();
      if (res.success != true || res.data == null) {
        emit(OrderDetailActionFailed(current, res.error ?? 'تعذر تنفيذ $label'));
        return;
      }
      _order = res.data as OrderResponse;
      emit(OrderDetailActionSucceeded(_order!, success));
      emit(OrderDetailLoaded(_order!));
    } on DioException catch (e) {
      emit(OrderDetailActionFailed(current, _msg(e, 'تعذر تنفيذ $label')));
    }
  }

  Future<void> _onSendMessage(
    SendMessageRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    final current = _order;
    if (current == null) return;
    final body = event.body.trim();
    if (body.isEmpty) return;
    emit(OrderDetailMutating(current));
    try {
      final req = SendOrderMessageRequest(body: body);
      final res = side == OrderViewerSide.customer
          ? await _api.sendOrderMessage(orderId, req)
          : await _api.sendVenueOrderMessage(venueId!, orderId, req);
      if (!res.success || res.data == null) {
        emit(OrderDetailActionFailed(
          current,
          res.error ?? 'تعذر إرسال الرسالة',
        ));
        return;
      }
      _order = OrderResponse(
        id: current.id,
        status: current.status,
        inquiryLocked: current.inquiryLocked,
        price: current.price,
        priceCurrency: current.priceCurrency,
        product: current.product,
        venue: current.venue,
        customer: current.customer,
        createdAt: current.createdAt,
        respondedAt: current.respondedAt,
        deliveredAt: current.deliveredAt,
        cancelledAt: current.cancelledAt,
        messages: [...current.messages, res.data!],
        unreadMessageCount: current.unreadMessageCount,
      );
      emit(OrderDetailLoaded(_order!));
    } on DioException catch (e) {
      emit(OrderDetailActionFailed(current, _msg(e, 'تعذر إرسال الرسالة')));
    }
  }

  Future<void> _onMarkRead(
    MarkMessagesReadRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    final current = _order;
    if (current == null) return;
    try {
      if (side == OrderViewerSide.customer) {
        await _api.markOrderMessagesRead(orderId);
      } else {
        await _api.markVenueOrderMessagesRead(venueId!, orderId);
      }
      if (current.unreadMessageCount > 0) {
        _order = OrderResponse(
          id: current.id,
          status: current.status,
          inquiryLocked: current.inquiryLocked,
          price: current.price,
          priceCurrency: current.priceCurrency,
          product: current.product,
          venue: current.venue,
          customer: current.customer,
          createdAt: current.createdAt,
          respondedAt: current.respondedAt,
          deliveredAt: current.deliveredAt,
          cancelledAt: current.cancelledAt,
          messages: current.messages,
          unreadMessageCount: 0,
        );
        emit(OrderDetailLoaded(_order!));
      }
    } on DioException {
    }
  }

  String _msg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
