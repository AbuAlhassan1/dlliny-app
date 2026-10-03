import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/order_response.dart';
import 'package:hangout/presentation/orders/controllers/orders_list/orders_list_bloc.dart';
import 'package:hangout/presentation/orders/widgets/order_status_badge.dart';

class OrdersListView extends StatefulWidget {
  final bool venueSide;

  final void Function(OrderSummaryResponse) onTap;

  const OrdersListView({
    super.key,
    required this.venueSide,
    required this.onTap,
  });

  @override
  State<OrdersListView> createState() => _OrdersListViewState();
}

class _OrdersListViewState extends State<OrdersListView> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      context.read<OrdersListBloc>().add(const LoadNextPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        _FilterBar(),
        Expanded(
          child: BlocBuilder<OrdersListBloc, OrdersListState>(
            builder: (context, state) {
              return switch (state) {
                OrdersListInitial() ||
                OrdersListLoading() => Center(
                    child: CircularProgressIndicator(
                      color: c.onSurface,
                      strokeWidth: 1.5,
                    ),
                  ),
                OrdersListError(:final message) => Center(
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
                            onPressed: () => context
                                .read<OrdersListBloc>()
                                .add(const LoadOrders()),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  ),
                OrdersListLoaded(:final items, :final hasMore) =>
                  items.isEmpty
                      ? _EmptyView(venueSide: widget.venueSide)
                      : RefreshIndicator(
                          onRefresh: () async => context
                              .read<OrdersListBloc>()
                              .add(const LoadOrders()),
                          child: ListView.separated(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: items.length + (hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: c.divider,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              if (index >= items.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: c.onSurface,
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                );
                              }
                              final o = items[index];
                              return _OrderRow(
                                order: o,
                                venueSide: widget.venueSide,
                                onTap: () => widget.onTap(o),
                              );
                            },
                          ),
                        ),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  static const _statuses = <OrderStatus?>[
    null,
    OrderStatus.pending,
    OrderStatus.accepted,
    OrderStatus.delivered,
    OrderStatus.rejected,
    OrderStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 44,
      child: BlocBuilder<OrdersListBloc, OrdersListState>(
        buildWhen: (a, b) {
          if (a is OrdersListLoaded && b is OrdersListLoaded) {
            return a.filter != b.filter;
          }
          return true;
        },
        builder: (context, state) {
          final current = state is OrdersListLoaded ? state.filter : null;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _statuses.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final s = _statuses[index];
              final selected = current == s;
              return InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => context
                    .read<OrdersListBloc>()
                    .add(SetStatusFilter(s)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? c.onSurface : c.surfaceMuted,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      s == null ? 'الكل' : orderStatusLabelAr(s),
                      style: TextStyle(
                        color: selected ? c.surface : c.onSurfaceSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool venueSide;
  const _EmptyView({required this.venueSide});
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
              TablerIcons.shopping_bag,
              color: c.onSurfaceDisabled,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              venueSide ? 'لا توجد طلبات بعد' : 'لم تطلب أي منتج بعد',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderSummaryResponse order;
  final bool venueSide;
  final VoidCallback onTap;
  const _OrderRow({
    required this.order,
    required this.venueSide,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mediaUrl = order.productMediaUrl;
    final hasMedia = mediaUrl != null && mediaUrl.isNotEmpty;
    final title = venueSide
        ? (order.customerDisplayName ?? '@${order.customerUsername}')
        : (order.venueNameAr ?? order.venueNameEn ?? 'متجر');
    final subtitle = order.productCaption?.isNotEmpty == true
        ? order.productCaption!
        : (venueSide ? '@${order.customerUsername}' : '');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasMedia
                  ? CachedNetworkImage(
                      imageUrl: mediaUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        TablerIcons.shopping_bag,
                        color: c.onSurfaceDisabled,
                      ),
                    )
                  : Icon(
                      TablerIcons.shopping_bag,
                      color: c.onSurfaceDisabled,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${order.price.toStringAsFixed(0)} ${order.priceCurrency}',
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (order.unreadMessageCount > 0)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '${order.unreadMessageCount}',
                              style: TextStyle(
                                color: c.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      Text(
                        formatRelativeTime(order.createdAt),
                        style: TextStyle(
                          color: c.onSurfaceMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
