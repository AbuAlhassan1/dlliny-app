import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/orders/controllers/orders_list/orders_list_bloc.dart';
import 'package:hangout/presentation/orders/venue_order_detail_page_wrapper.dart';
import 'package:hangout/presentation/orders/widgets/orders_list_view.dart';

class VenueOrdersInboxPageWrapper extends StatelessWidget {
  final String venueId;

  final String? venueName;

  const VenueOrdersInboxPageWrapper({
    super.key,
    required this.venueId,
    this.venueName,
  });

  static Future<void> push(
    BuildContext context, {
    required String venueId,
    String? venueName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueOrdersInboxPageWrapper(
          venueId: venueId,
          venueName: venueName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (_) => OrdersListBloc(
        mode: OrdersListMode.venueInbox,
        venueId: venueId,
      )..add(const LoadOrders()),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'إدارة الطلبات',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (venueName != null && venueName!.isNotEmpty)
                Text(
                  venueName!,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
        body: OrdersListView(
          venueSide: true,
          onTap: (order) => VenueOrderDetailPageWrapper.push(
            context,
            venueId: venueId,
            orderId: order.id,
          ),
        ),
      ),
    );
  }
}
