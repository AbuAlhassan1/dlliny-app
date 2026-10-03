import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/business_transfer_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/transfers/controllers/transfers_list/transfers_list_bloc.dart';
import 'package:hangout/presentation/business/transfers/utils/transfer_enums.dart';
import 'package:hangout/presentation/business/transfers/widgets/transfer_status_badge.dart';

class TransfersListView extends StatefulWidget {
  final TransfersDirection direction;
  final void Function(BusinessTransferResponse) onTap;

  const TransfersListView({
    super.key,
    required this.direction,
    required this.onTap,
  });

  @override
  State<TransfersListView> createState() => _TransfersListViewState();
}

class _TransfersListViewState extends State<TransfersListView> {
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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      context.read<TransfersListBloc>().add(const LoadMoreTransfers());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        const _FilterBar(),
        Expanded(
          child: BlocBuilder<TransfersListBloc, TransfersListState>(
            builder: (context, state) {
              return switch (state) {
                TransfersListInitial() ||
                TransfersListLoading() => Center(
                    child: CircularProgressIndicator(
                      color: c.onSurface,
                      strokeWidth: 1.5,
                    ),
                  ),
                TransfersListError(:final message) => _Error(message: message),
                TransfersListLoaded(:final items, :final hasMore) =>
                  items.isEmpty
                      ? _Empty(direction: widget.direction)
                      : RefreshIndicator(
                          onRefresh: () async => context
                              .read<TransfersListBloc>()
                              .add(const LoadTransfers()),
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
                              final row = items[index];
                              return _TransferRow(
                                row: row,
                                direction: widget.direction,
                                onTap: () => widget.onTap(row),
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
  const _FilterBar();

  static const _statuses = <TransferStatus?>[
    TransferStatus.pending,
    TransferStatus.accepted,
    TransferStatus.declined,
    TransferStatus.cancelled,
    TransferStatus.expired,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 44,
      child: BlocBuilder<TransfersListBloc, TransfersListState>(
        buildWhen: (a, b) {
          if (a is TransfersListLoaded && b is TransfersListLoaded) {
            return a.filter != b.filter;
          }
          return true;
        },
        builder: (context, state) {
          final current = state is TransfersListLoaded ? state.filter : null;
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
                    .read<TransfersListBloc>()
                    .add(SetTransfersFilter(s)),
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
                      s == null
                          ? LocaleKeys.map_category_filter_all.tr()
                          : transferStatusLabelAr(s),
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

class _Error extends StatelessWidget {
  final String message;
  const _Error({required this.message});
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
              onPressed: () => context
                  .read<TransfersListBloc>()
                  .add(const LoadTransfers()),
              child: Text(LocaleKeys.common_retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final TransfersDirection direction;
  const _Empty({required this.direction});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final copy = direction == TransfersDirection.incoming
        ? LocaleKeys.business_transfers_empty_incoming.tr()
        : LocaleKeys.business_transfers_empty_outgoing.tr();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.transfer, color: c.onSurfaceDisabled, size: 32),
            const SizedBox(height: 10),
            Text(
              copy,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final BusinessTransferResponse row;
  final TransfersDirection direction;
  final VoidCallback onTap;
  const _TransferRow({
    required this.row,
    required this.direction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final type = TransferType.fromWire(row.transferType);
    final status = TransferStatus.fromWire(row.status);
    final isVenue = type == TransferType.venue;

    final counterpartUsername = direction == TransfersDirection.incoming
        ? row.senderUsername
        : row.targetUsername;
    final assetLabel = isVenue
        ? context.pickBilingual(
            ar: row.venueNameAr,
            en: row.venueNameEn,
            fallback: LocaleKeys.business_transfers_venue_fallback.tr(),
          )
        : (row.businessName ??
            LocaleKeys.business_transfers_business_fallback.tr());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVenue ? TablerIcons.building_store : TablerIcons.briefcase,
                color: c.onSurfaceSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          assetLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (status != null)
                        TransferStatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    direction == TransfersDirection.incoming
                        ? LocaleKeys.business_transfers_from_counterpart.tr(
                            namedArgs: {'username': counterpartUsername},
                          )
                        : LocaleKeys.business_transfers_to_counterpart.tr(
                            namedArgs: {'username': counterpartUsername},
                          ),
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
                        (isVenue
                                ? LocaleKeys.business_transfers_kind_transfer_venue
                                : LocaleKeys.business_transfers_kind_transfer_business)
                            .tr(),
                        style: TextStyle(
                          color: c.onSurfaceMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatRelativeTime(row.createdAt),
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
