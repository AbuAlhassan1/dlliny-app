import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/order_response.dart';
import 'package:hangout/presentation/orders/controllers/order_detail/order_detail_bloc.dart';
import 'package:hangout/presentation/orders/widgets/order_inquiry_thread.dart';
import 'package:hangout/presentation/orders/widgets/order_status_badge.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

class OrderDetailPageWrapper extends StatelessWidget {
  final String orderId;
  const OrderDetailPageWrapper({super.key, required this.orderId});

  static Future<void> push(BuildContext context, String orderId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPageWrapper(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrderDetailBloc(
        orderId: orderId,
        side: OrderViewerSide.customer,
      )..add(const LoadOrder()),
      child: const _OrderDetailView(showCustomerActions: true),
    );
  }
}

class OrderDetailView extends StatelessWidget {
  final bool showCustomerActions;
  final Widget? venueActionsBar;
  const OrderDetailView({
    super.key,
    this.showCustomerActions = false,
    this.venueActionsBar,
  });

  @override
  Widget build(BuildContext context) {
    return _OrderDetailView(
      showCustomerActions: showCustomerActions,
      venueActionsBar: venueActionsBar,
    );
  }
}

class _OrderDetailView extends StatefulWidget {
  final bool showCustomerActions;
  final Widget? venueActionsBar;
  const _OrderDetailView({
    required this.showCustomerActions,
    this.venueActionsBar,
  });

  @override
  State<_OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<_OrderDetailView> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: const Text(
          'الطلب',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocConsumer<OrderDetailBloc, OrderDetailState>(
        listener: (context, state) {
          if (state is OrderDetailActionSucceeded) {
            appToast.success(state.message);
          } else if (state is OrderDetailActionFailed) {
            appToast.error(state.message);
          } else if (state is OrderDetailLoaded && !_markedRead) {
            if (state.order.unreadMessageCount > 0) {
              context.read<OrderDetailBloc>().add(
                const MarkMessagesReadRequested(),
              );
            }
            _markedRead = true;
          }
        },
        builder: (context, state) {
          return switch (state) {
            OrderDetailInitial() ||
            OrderDetailLoading() => Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1.5,
                ),
              ),
            OrderDetailError(:final message) => _ErrorView(message: message),
            OrderDetailLoaded(:final order) ||
            OrderDetailMutating(:final order) ||
            OrderDetailActionSucceeded(:final order) ||
            OrderDetailActionFailed(:final order) =>
              _OrderBody(
                order: order,
                isMutating: state is OrderDetailMutating,
                showCustomerActions: widget.showCustomerActions,
                venueActionsBar: widget.venueActionsBar,
              ),
          };
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.alert_triangle,
              color: c.onSurfaceDisabled,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => context.read<OrderDetailBloc>().add(
                const LoadOrder(),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  final OrderResponse order;
  final bool isMutating;
  final bool showCustomerActions;
  final Widget? venueActionsBar;
  const _OrderBody({
    required this.order,
    required this.isMutating,
    required this.showCustomerActions,
    this.venueActionsBar,
  });

  bool get _isOpen =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.accepted;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Header(order: order),
            const SizedBox(height: 14),
            _ProductCard(order: order),
            const SizedBox(height: 14),
            _VenueCard(order: order),
            const SizedBox(height: 14),
            if (showCustomerActions && _isOpen) ...[
              _CancelButton(),
              const SizedBox(height: 14),
            ],
            if (venueActionsBar != null) ...[
              venueActionsBar!,
              const SizedBox(height: 14),
            ],
            Divider(color: c.divider, height: 1),
            const SizedBox(height: 14),
            Text(
              'الرسائل',
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<OrderDetailBloc, OrderDetailState>(
              builder: (context, state) {
                final bloc = context.read<OrderDetailBloc>();
                return OrderInquiryThread(
                  order: order,
                  viewerSide: bloc.side,
                  isSending: isMutating,
                  onSend: (body) => bloc.add(SendMessageRequested(body)),
                );
              },
            ),
          ],
        ),
        if (isMutating)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: c.onSurface,
              backgroundColor: c.divider,
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final OrderResponse order;
  const _Header({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OrderStatusBadge(
                status: order.status,
                size: OrderStatusBadgeSize.large,
              ),
              const Spacer(),
              Text(
                formatRelativeTime(order.createdAt),
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.price.toStringAsFixed(0),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  order.priceCurrency ?? 'IQD',
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final OrderResponse order;
  const _ProductCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = order.product;
    final hasMedia = p.mediaUrl != null && p.mediaUrl!.isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: hasMedia
                ? CachedNetworkImage(
                    imageUrl: p.mediaUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: c.surfaceMuted,
                      child: Icon(
                        TablerIcons.photo_off,
                        color: c.onSurfaceDisabled,
                      ),
                    ),
                  )
                : Container(
                    color: c.surfaceMuted,
                    child: Icon(
                      TablerIcons.shopping_bag,
                      color: c.onSurfaceDisabled,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.caption?.isNotEmpty == true ? p.caption! : 'منتج',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (p.currentPrice != null &&
                      p.currentPrice != order.price) ...[
                    const SizedBox(height: 4),
                    Text(
                      'السعر الحالي: ${p.currentPrice!.toStringAsFixed(0)} ${order.priceCurrency}',
                      style: TextStyle(
                        color: c.onSurfaceMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final OrderResponse order;
  const _VenueCard({required this.order});

  Future<void> _copyPhone(BuildContext context, String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) appToast.info('تم نسخ الرقم');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final v = order.venue;
    final hasLogo = v.logoUrl != null && v.logoUrl!.isNotEmpty;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenuePageWrapper(venueId: v.id),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(100),
              ),
              child: hasLogo
                  ? CachedNetworkImage(
                      imageUrl: v.logoUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        TablerIcons.building_store,
                        color: c.onSurfaceSecondary,
                        size: 20,
                      ),
                    )
                  : Icon(
                      TablerIcons.building_store,
                      color: c.onSurfaceSecondary,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.nameAr ?? v.nameEn ?? 'متجر',
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (v.nameEn != null && v.nameEn!.isNotEmpty)
                    Text(
                      v.nameEn!,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (v.phone != null && v.phone!.isNotEmpty)
              IconButton(
                tooltip: 'اتصل',
                onPressed: () => _copyPhone(context, v.phone!),
                icon: Icon(TablerIcons.phone, color: c.primary, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: c.surface,
              title: Text(
                'إلغاء الطلب',
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'هل تريد إلغاء هذا الطلب؟',
                style: TextStyle(color: c.onSurfaceSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'لا',
                    style: TextStyle(color: c.onSurfaceSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'إلغاء الطلب',
                    style: TextStyle(color: c.danger),
                  ),
                ),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            context.read<OrderDetailBloc>().add(const CancelOrderRequested());
          }
        },
        icon: Icon(TablerIcons.x, color: c.danger, size: 16),
        label: Text('إلغاء الطلب', style: TextStyle(color: c.danger)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
