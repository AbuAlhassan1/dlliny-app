import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/transfers/business_transfer_detail_page_wrapper.dart';
import 'package:hangout/presentation/business/transfers/controllers/transfers_list/transfers_list_bloc.dart';
import 'package:hangout/presentation/business/transfers/create_business_transfer_page_wrapper.dart';
import 'package:hangout/presentation/business/transfers/widgets/transfers_list_view.dart';

class BusinessTransfersPageWrapper extends StatelessWidget {
  const BusinessTransfersPageWrapper({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BusinessTransfersPageWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: Text(
            LocaleKeys.business_transfers_page_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              tooltip: LocaleKeys.business_transfers_new_transfer_tooltip.tr(),
              onPressed: () =>
                  CreateBusinessTransferPageWrapper.pushForBusiness(context),
              icon: Icon(TablerIcons.plus, color: c.onSurface),
            ),
          ],
          bottom: TabBar(
            indicatorColor: c.onSurface,
            labelColor: c.onSurface,
            unselectedLabelColor: c.onSurfaceSecondary,
            dividerColor: c.border,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(text: LocaleKeys.business_transfers_tab_incoming.tr()),
              Tab(text: LocaleKeys.business_transfers_tab_outgoing.tr()),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TabBody(direction: TransfersDirection.incoming),
            _TabBody(direction: TransfersDirection.outgoing),
          ],
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  final TransfersDirection direction;
  const _TabBody({required this.direction});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TransfersListBloc(direction: direction)
        ..add(const LoadTransfers()),
      child: Builder(
        builder: (inner) => TransfersListView(
          direction: direction,
          onTap: (row) async {
            final result = await BusinessTransferDetailPageWrapper.push(
              inner,
              transferId: row.id,
              direction: direction,
              seed: row,
            );
            if (!inner.mounted) return;
            if (result is BusinessTransferDetailMutationResult) {
              switch (result.kind) {
                case DetailMutationKind.replaced:
                  inner
                      .read<TransfersListBloc>()
                      .add(TransfersListRowMutated(result.row!));
                case DetailMutationKind.removed:
                  inner
                      .read<TransfersListBloc>()
                      .add(TransfersListRowRemoved(row.id));
              }
            }
          },
        ),
      ),
    );
  }
}
