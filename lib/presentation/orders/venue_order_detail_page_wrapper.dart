import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/order_response.dart';
import 'package:hangout/presentation/orders/controllers/order_detail/order_detail_bloc.dart';
import 'package:hangout/presentation/orders/order_detail_page_wrapper.dart';

class VenueOrderDetailPageWrapper extends StatelessWidget {
  final String venueId;
  final String orderId;
  const VenueOrderDetailPageWrapper({
    super.key,
    required this.venueId,
    required this.orderId,
  });

  static Future<void> push(
    BuildContext context, {
    required String venueId,
    required String orderId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueOrderDetailPageWrapper(
          venueId: venueId,
          orderId: orderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderDetailBloc(
        orderId: orderId,
        side: OrderViewerSide.venue,
        venueId: venueId,
      )..add(const LoadOrder()),
      child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          final order = switch (state) {
            OrderDetailLoaded(:final order) => order,
            OrderDetailMutating(:final order) => order,
            OrderDetailActionSucceeded(:final order) => order,
            OrderDetailActionFailed(:final order) => order,
            _ => null,
          };
          return OrderDetailView(
            showCustomerActions: false,
            venueActionsBar: order == null
                ? null
                : _VenueActionsBar(order: order),
          );
        },
      ),
    );
  }
}

class _VenueActionsBar extends StatelessWidget {
  final OrderResponse order;
  const _VenueActionsBar({required this.order});

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          title,
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          body,
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'تراجع',
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(color: destructive ? c.danger : c.primary),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bloc = context.read<OrderDetailBloc>();
    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (await _confirm(
                    context,
                    title: 'رفض الطلب',
                    body: 'هل تريد رفض هذا الطلب؟ لا يمكن التراجع.',
                    confirmLabel: 'رفض',
                    destructive: true,
                  )) {
                    bloc.add(const RejectOrderRequested());
                  }
                },
                icon: Icon(TablerIcons.x, color: c.danger, size: 16),
                label: Text('رفض', style: TextStyle(color: c.danger)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () async {
                  if (await _confirm(
                    context,
                    title: 'قبول الطلب',
                    body: 'هل تريد قبول هذا الطلب؟',
                    confirmLabel: 'قبول',
                  )) {
                    bloc.add(const AcceptOrderRequested());
                  }
                },
                icon: Icon(TablerIcons.check, color: c.onPrimary, size: 16),
                label: const Text('قبول الطلب'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      case OrderStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (await _confirm(
                    context,
                    title: 'إلغاء الطلب',
                    body: 'هل تريد إلغاء هذا الطلب؟',
                    confirmLabel: 'إلغاء الطلب',
                    destructive: true,
                  )) {
                    bloc.add(const CancelOrderRequested());
                  }
                },
                icon: Icon(TablerIcons.x, color: c.danger, size: 16),
                label: Text('إلغاء', style: TextStyle(color: c.danger)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () async {
                  if (await _confirm(
                    context,
                    title: 'تأكيد التسليم',
                    body: 'تم استلام الزبون للمنتج والدفع؟',
                    confirmLabel: 'تأكيد',
                  )) {
                    bloc.add(const DeliverOrderRequested());
                  }
                },
                icon: Icon(
                  TablerIcons.package_export,
                  color: c.onPrimary,
                  size: 16,
                ),
                label: const Text('تأكيد التسليم'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.success,
                  foregroundColor: c.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      case OrderStatus.delivered:
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return const SizedBox.shrink();
    }
  }
}
