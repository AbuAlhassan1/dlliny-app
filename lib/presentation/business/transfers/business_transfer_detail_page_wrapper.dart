import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/accept_business_transfer_request.dart';
import 'package:hangout/domain/dto/response/business_transfer_response.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/business/transfers/controllers/transfers_list/transfers_list_bloc.dart';
import 'package:hangout/presentation/business/transfers/utils/transfer_enums.dart';
import 'package:hangout/presentation/business/transfers/widgets/accept_venue_business_picker_sheet.dart';
import 'package:hangout/presentation/business/transfers/widgets/transfer_status_badge.dart';

enum DetailMutationKind { replaced, removed }

class BusinessTransferDetailMutationResult {
  final DetailMutationKind kind;

  final BusinessTransferResponse? row;
  const BusinessTransferDetailMutationResult({required this.kind, this.row});
}

class BusinessTransferDetailPageWrapper extends StatefulWidget {
  final String transferId;
  final TransfersDirection direction;

  final BusinessTransferResponse? seed;

  const BusinessTransferDetailPageWrapper({
    super.key,
    required this.transferId,
    required this.direction,
    this.seed,
  });

  static Future<BusinessTransferDetailMutationResult?> push(
    BuildContext context, {
    required String transferId,
    required TransfersDirection direction,
    BusinessTransferResponse? seed,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BusinessTransferDetailPageWrapper(
          transferId: transferId,
          direction: direction,
          seed: seed,
        ),
      ),
    );
  }

  @override
  State<BusinessTransferDetailPageWrapper> createState() =>
      _BusinessTransferDetailPageWrapperState();
}

class _BusinessTransferDetailPageWrapperState
    extends State<BusinessTransferDetailPageWrapper> {
  late Future<BusinessTransferResponse> _future;
  BusinessTransferResponse? _row;

  BusinessTransferDetailMutationResult? _result;

  bool _mutating = false;

  bool get _isIncoming => widget.direction == TransfersDirection.incoming;

  @override
  void initState() {
    super.initState();
    _row = widget.seed;
    _future = _refresh();
  }

  Future<BusinessTransferResponse> _refresh() async {
    if (_row != null) return _row!;
    final api = serviceLocator.get<ApiService>();
    final res = _isIncoming
        ? await api.getIncomingBusinessTransfers(status: 'pending', size: 50)
        : await api.getOutgoingBusinessTransfers(status: 'pending', size: 50);
    if (!res.success || res.data == null) {
      throw Exception(
        res.error ?? LocaleKeys.business_transfers_detail_load_error.tr(),
      );
    }
    final match = res.data!.content
        .where((t) => t.id == widget.transferId)
        .firstOrNull;
    if (match == null) {
      throw Exception(LocaleKeys.business_transfers_detail_not_found.tr());
    }
    _row = match;
    return match;
  }

  void _applyMutated(BusinessTransferResponse next) {
    setState(() {
      _row = next;
      _result = BusinessTransferDetailMutationResult(
        kind: DetailMutationKind.replaced,
        row: next,
      );
    });
  }

  Future<void> _accept() async {
    final row = _row;
    if (row == null) return;
    final isVenue = TransferType.fromWire(row.transferType) == TransferType.venue;

    String? targetBusinessId;
    if (isVenue) {
      final myBusinesses = _myOwnedBusinesses(context);
      if (myBusinesses.isEmpty) {
        appToast.error(
          LocaleKeys.business_transfers_detail_need_business_account_toast.tr(),
        );
        return;
      }
      if (myBusinesses.length == 1) {
        targetBusinessId = myBusinesses.single.businessId;
      } else {
        final picked = await showAcceptVenueBusinessPickerSheet(
          context,
          businesses: myBusinesses,
        );
        if (picked == null) return;
        targetBusinessId = picked.businessId;
      }
    }

    final confirmed = await _confirm(
      title: LocaleKeys.business_transfers_detail_confirm_accept_title.tr(),
      body: (isVenue
              ? LocaleKeys.business_transfers_detail_confirm_accept_venue_body
              : LocaleKeys.business_transfers_detail_confirm_accept_business_body)
          .tr(),
      confirmLabel:
          LocaleKeys.business_transfers_detail_confirm_accept_label.tr(),
    );
    if (!confirmed || !mounted) return;

    await _runMutation(
      () => serviceLocator.get<ApiService>().acceptBusinessTransfer(
            widget.transferId,
            AcceptBusinessTransferRequest(targetBusinessId: targetBusinessId),
          ),
      failureFallback:
          LocaleKeys.business_transfers_detail_accept_failed_fallback.tr(),
    );
  }

  Future<void> _decline() async {
    final confirmed = await _confirm(
      title: LocaleKeys.business_transfers_detail_confirm_reject_title.tr(),
      body: LocaleKeys.business_transfers_detail_confirm_reject_body.tr(),
      confirmLabel:
          LocaleKeys.business_transfers_detail_confirm_reject_label.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _runMutation(
      () => serviceLocator
          .get<ApiService>()
          .declineBusinessTransfer(widget.transferId),
      failureFallback:
          LocaleKeys.business_transfers_detail_reject_failed_fallback.tr(),
    );
  }

  Future<void> _cancel() async {
    final confirmed = await _confirm(
      title: LocaleKeys.business_transfers_detail_confirm_cancel_title.tr(),
      body: LocaleKeys.business_transfers_detail_confirm_cancel_body.tr(),
      confirmLabel:
          LocaleKeys.business_transfers_detail_confirm_cancel_label.tr(),
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await _runMutation(
      () => serviceLocator
          .get<ApiService>()
          .cancelBusinessTransfer(widget.transferId),
      failureFallback:
          LocaleKeys.business_transfers_detail_cancel_failed_fallback.tr(),
      removed: true,
    );
  }

  Future<void> _runMutation(
    Future<dynamic> Function() call, {
    required String failureFallback,
    bool removed = false,
  }) async {
    setState(() => _mutating = true);
    try {
      final dynamic res = await call();
      if (!mounted) return;
      if (res.success != true || res.data == null) {
        appToast.error(res.error ?? failureFallback);
        setState(() => _mutating = false);
        return;
      }
      final next = res.data as BusinessTransferResponse;
      if (removed) {
        _result = BusinessTransferDetailMutationResult(
          kind: DetailMutationKind.removed,
        );
      } else {
        _applyMutated(next);
      }
      setState(() => _mutating = false);
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? failureFallback);
      appToast.error(msg);
      setState(() => _mutating = false);
    }
  }

  Future<bool> _confirm({
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
              LocaleKeys.common_back.tr(),
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

  List<BusinessAccess> _myOwnedBusinesses(BuildContext context) {
    final access = context.read<AccessBloc>().myAccess?.data;
    if (access == null) return const [];
    return access.businesses
        .where((b) => b.businessRoleName == 'business_owner' && b.active)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_result);
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_result),
          ),
          title: Text(
            LocaleKeys.business_transfers_detail_page_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
          body: FutureBuilder<BusinessTransferResponse>(
            future: _future,
            builder: (context, snapshot) {
              final row = _row ?? snapshot.data;
              if (row == null) {
                if (snapshot.hasError) {
                  return _Error(message: snapshot.error.toString());
                }
                return Center(
                  child: CircularProgressIndicator(
                    color: c.onSurface,
                    strokeWidth: 1.5,
                  ),
                );
              }
              return _Body(
                row: row,
                direction: widget.direction,
                mutating: _mutating,
                onAccept: _accept,
                onDecline: _decline,
                onCancel: _cancel,
              );
            },
          ),
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
        child: Text(
          message,
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final BusinessTransferResponse row;
  final TransfersDirection direction;
  final bool mutating;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  const _Body({
    required this.row,
    required this.direction,
    required this.mutating,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final type = TransferType.fromWire(row.transferType);
    final status = TransferStatus.fromWire(row.status);
    final isVenue = type == TransferType.venue;
    final isIncoming = direction == TransfersDirection.incoming;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _StatusCard(row: row, status: status),
            const SizedBox(height: 14),
            _AssetCard(row: row, isVenue: isVenue),
            const SizedBox(height: 14),
            _PartiesCard(row: row, isIncoming: isIncoming),
            if (row.message != null && row.message!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _MessageCard(message: row.message!),
            ],
            if (status == TransferStatus.pending) ...[
              const SizedBox(height: 20),
              if (isIncoming) ...[
                _PrimaryAction(
                  label: isVenue
                      ? LocaleKeys.business_transfers_detail_cta_accept_venue.tr()
                      : LocaleKeys.business_transfers_detail_cta_accept_business.tr(),
                  icon: TablerIcons.check,
                  background: c.success,
                  foreground: c.onPrimary,
                  onTap: mutating ? null : onAccept,
                ),
                const SizedBox(height: 8),
                _PrimaryAction(
                  label: LocaleKeys.business_transfers_detail_cta_reject.tr(),
                  icon: TablerIcons.x,
                  background: c.surface,
                  foreground: c.danger,
                  borderColor: c.border,
                  onTap: mutating ? null : onDecline,
                ),
              ] else ...[
                _PrimaryAction(
                  label: LocaleKeys.business_transfers_detail_cta_cancel.tr(),
                  icon: TablerIcons.x,
                  background: c.surface,
                  foreground: c.danger,
                  borderColor: c.border,
                  onTap: mutating ? null : onCancel,
                ),
              ],
            ],
          ],
        ),
        if (mutating)
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

class _StatusCard extends StatelessWidget {
  final BusinessTransferResponse row;
  final TransferStatus? status;
  const _StatusCard({required this.row, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final expiresAt = DateTime.tryParse(row.expiresAt);
    final isPending = status == TransferStatus.pending;
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
              if (status != null)
                TransferStatusBadge(
                  status: status!,
                  size: TransferStatusBadgeSize.large,
                ),
              const Spacer(),
              Text(
                formatRelativeTime(row.createdAt),
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
              ),
            ],
          ),
          if (isPending && expiresAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  TablerIcons.clock,
                  color: c.onSurfaceSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.business_transfers_detail_expires_at_relative.tr(
                    namedArgs: {'time': formatRelativeTime(row.expiresAt)},
                  ),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (!isPending && row.respondedAt != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  TablerIcons.history,
                  color: c.onSurfaceSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  LocaleKeys.business_transfers_detail_responded_at_relative.tr(
                    namedArgs: {'time': formatRelativeTime(row.respondedAt!)},
                  ),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final BusinessTransferResponse row;
  final bool isVenue;
  const _AssetCard({required this.row, required this.isVenue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = isVenue
        ? context.pickBilingual(
            ar: row.venueNameAr,
            en: row.venueNameEn,
            fallback: LocaleKeys.business_transfers_venue_fallback.tr(),
          )
        : (row.businessName ??
            LocaleKeys.business_transfers_business_fallback.tr());
    final subtitle = isVenue
        ? LocaleKeys.business_transfers_detail_one_venue_transfer_from.tr(
            namedArgs: {
              'from': row.businessName ??
                  LocaleKeys.business_transfers_business_sender_fallback.tr(),
            },
          )
        : LocaleKeys.business_transfers_detail_whole_business_transfer.tr();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVenue ? TablerIcons.building_store : TablerIcons.briefcase,
              color: c.onSurface,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isVenue && row.venueNameEn != null && row.venueNameEn!.isNotEmpty)
                  Text(
                    row.venueNameEn!,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartiesCard extends StatelessWidget {
  final BusinessTransferResponse row;
  final bool isIncoming;
  const _PartiesCard({required this.row, required this.isIncoming});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _PartyRow(
            label: LocaleKeys.business_transfers_detail_from_label.tr(),
            username: row.senderUsername,
            highlighted: !isIncoming,
          ),
          const SizedBox(height: 8),
          Icon(
            TablerIcons.arrow_down,
            color: c.onSurfaceSecondary,
            size: 14,
          ),
          const SizedBox(height: 8),
          _PartyRow(
            label: LocaleKeys.business_transfers_detail_to_label.tr(),
            username: row.targetUsername,
            highlighted: isIncoming,
          ),
          if (row.targetBusinessName != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                LocaleKeys.business_transfers_detail_target_business.tr(
                  namedArgs: {'name': row.targetBusinessName ?? ''},
                ),
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  final String label;
  final String username;
  final bool highlighted;
  const _PartyRow({
    required this.label,
    required this.username,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(
              color: c.onSurfaceMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '@$username${highlighted ? '  (أنت)' : ''}',
            style: TextStyle(
              color: c.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.business_transfers_detail_message_label.tr(),
            style: TextStyle(
              color: c.onSurfaceMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onTap;
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: foreground, size: 16),
        label: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: borderColor != null
              ? BorderSide(color: borderColor!)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
