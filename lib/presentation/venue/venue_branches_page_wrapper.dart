import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_branches/venue_branches_bloc.dart';
import 'package:hangout/presentation/venue/venue_branch_form_page_wrapper.dart';

class VenueBranchesPageWrapper extends StatelessWidget {
  final String venueId;

  const VenueBranchesPageWrapper({super.key, required this.venueId});

  static Future<void> push(BuildContext context, String venueId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => VenueBranchesBloc(venueId: venueId)
            ..add(LoadVenueBranches()),
          child: VenueBranchesPageWrapper(venueId: venueId),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          LocaleKeys.manage_venue_branches_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocConsumer<VenueBranchesBloc, VenueBranchesState>(
        listenWhen: (_, s) => s is VenueBranchOperationError,
        listener: (context, state) {
          if (state is VenueBranchOperationError) {
            appToast.error(state.message);
          }
        },
        builder: (context, state) {
          final bloc = context.read<VenueBranchesBloc>();
          if (state is VenueBranchesLoading && bloc.branches.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1.5,
              ),
            );
          }
          if (state is VenueBranchesError && bloc.branches.isEmpty) {
            return _Error(
              message: state.message,
              onRetry: () => bloc.add(LoadVenueBranches()),
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: c.onSurface,
                  onRefresh: () async {
                    bloc.add(LoadVenueBranches());
                  },
                  child: bloc.branches.isEmpty
                      ? const _Empty()
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(15, 16, 15, 100),
                          itemCount: bloc.branches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final branch = bloc.branches[i];
                            return _BranchTile(
                              branch: branch,
                              onTap: () =>
                                  VenueBranchFormPageWrapper.pushEdit(
                                context,
                                bloc: bloc,
                                branch: branch,
                              ),
                            );
                          },
                        ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => VenueBranchFormPageWrapper.pushCreate(
                        context,
                        bloc: bloc,
                      ),
                      icon: const Icon(TablerIcons.plus, size: 18),
                      label: Text(
                        LocaleKeys.manage_venue_branches_button_add.tr(),
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                        )
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  final VenueLocationResponse branch;
  final VoidCallback onTap;

  const _BranchTile({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final label = (branch.labelAr?.isNotEmpty == true)
        ? branch.labelAr!
        : (branch.labelEn?.isNotEmpty == true
            ? branch.labelEn!
            : LocaleKeys.manage_venue_branches_secondary_label.tr());
    final address = [
      if (branch.cityNameAr?.isNotEmpty == true) branch.cityNameAr!,
      if (branch.districtNameAr?.isNotEmpty == true) branch.districtNameAr!,
    ].join(' · ');
    return Material(
      color: c.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                TablerIcons.building_store,
                color: c.onSurfaceSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (branch.isPrimary) ...[
                          const SizedBox(width: 6),
                          _PrimaryBadge(),
                        ],
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            TablerIcons.map_pin,
                            size: 11,
                            color: c.onSurfaceSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (branch.phone != null &&
                        branch.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            TablerIcons.phone,
                            size: 11,
                            color: c.onSurfaceSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              branch.phone!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                TablerIcons.chevron_left,
                size: 18,
                color: c.onSurfaceSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        LocaleKeys.manage_venue_branches_primary_label.tr(),
        style: TextStyle(
          color: c.onPrimary,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        Icon(
          TablerIcons.building_store,
          color: c.onSurfaceDisabled,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.manage_venue_branches_empty.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _Error({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.cloud_off,
              color: c.onSurfaceDisabled,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurface, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(TablerIcons.refresh, color: c.onSurface, size: 18),
              label: Text(
                LocaleKeys.manage_venue_branches_button_retry.tr(),
                style: TextStyle(color: c.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
