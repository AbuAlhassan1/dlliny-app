import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/orders/controllers/orders_list/orders_list_bloc.dart';
import 'package:hangout/presentation/orders/order_detail_page_wrapper.dart';
import 'package:hangout/presentation/orders/widgets/orders_list_view.dart';

class MyOrdersPageWrapper extends StatelessWidget {
  const MyOrdersPageWrapper({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyOrdersPageWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (_) =>
          OrdersListBloc(mode: OrdersListMode.myOrders)..add(const LoadOrders()),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: const Text(
            'طلباتي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: OrdersListView(
          venueSide: false,
          onTap: (order) => OrderDetailPageWrapper.push(context, order.id),
        ),
      ),
    );
  }
}
