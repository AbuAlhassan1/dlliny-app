import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';

class VenueVerificationPageWrapper extends StatefulWidget {
  final String venueId;
  final String venueName;

  final bool alreadyVerified;

  const VenueVerificationPageWrapper({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.alreadyVerified,
  });

  static Future<void> push(
    BuildContext context, {
    required String venueId,
    required String venueName,
    required bool alreadyVerified,
  }) {
    final venueBloc = context.read<VenueBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: venueBloc,
          child: VenueVerificationPageWrapper(
            venueId: venueId,
            venueName: venueName,
            alreadyVerified: alreadyVerified,
          ),
        ),
      ),
    );
  }

  @override
  State<VenueVerificationPageWrapper> createState() =>
      _VenueVerificationPageWrapperState();
}

class _VenueVerificationPageWrapperState
    extends State<VenueVerificationPageWrapper> {
  final _documents = TextEditingController();
  late Future<List<VerificationRequestResponse>> _requestsFuture;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _fetchRequests();
  }

  @override
  void dispose() {
    _documents.dispose();
    super.dispose();
  }

  Future<List<VerificationRequestResponse>> _fetchRequests() async {
    final api = serviceLocator.get<ApiService>();
    final res = await api.getVerificationRequests();
    if (!res.success || res.data == null) {
      throw Exception(res.error ?? LocaleKeys.manage_venue_verification_error_load_requests.tr());
    }
    final mine = res.data!
        .where((r) => r.venueId == widget.venueId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return mine;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final docs = _documents.text.trim();
    if (docs.isEmpty) {
      appToast.info(LocaleKeys.manage_venue_verification_error_add_docs.tr());
      return;
    }
    setState(() => _submitting = true);
    try {
      final api = serviceLocator.get<ApiService>();
      final res = await api.submitVerificationRequest(
        widget.venueId,
        documents: docs,
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        appToast.error(res.error ?? LocaleKeys.manage_venue_verification_error_submit_fallback.tr());
        setState(() => _submitting = false);
        return;
      }
      appToast.success(LocaleKeys.manage_venue_verification_success_submitted.tr());
      _documents.clear();
      setState(() {
        _submitting = false;
        _requestsFuture = _fetchRequests();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final msg = (data is Map && data['error'] is String)
          ? data['error'] as String
          : (e.message ?? LocaleKeys.manage_venue_verification_error_submit_fallback.tr());
      appToast.error(msg);
      setState(() => _submitting = false);
    }
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
          LocaleKeys.manage_venue_verification_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: FutureBuilder<List<VerificationRequestResponse>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1.5,
              ),
            );
          }
          if (snapshot.hasError) {
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
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.onSurfaceSecondary),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        _requestsFuture = _fetchRequests();
                      }),
                      child: Text(LocaleKeys.manage_venue_verification_button_retry.tr()),
                    ),
                  ],
                ),
              ),
            );
          }
          final requests = snapshot.data ?? const <VerificationRequestResponse>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.alreadyVerified)
                _AlreadyVerifiedCard(venueName: widget.venueName)
              else
                _PrimaryStatusBlock(
                  requests: requests,
                  documentsController: _documents,
                  submitting: _submitting,
                  onSubmit: _submit,
                ),
              if (requests.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  LocaleKeys.manage_venue_verification_log_title.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final r in requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _HistoryTile(request: r),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AlreadyVerifiedCard extends StatelessWidget {
  final String venueName;
  const _AlreadyVerifiedCard({required this.venueName});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.rosette_discount_check_filled,
            color: c.success,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.manage_venue_verification_verified_title.tr(),
                  style: TextStyle(
                    color: c.success,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  LocaleKeys.manage_venue_verification_verified_body
                      .tr(namedArgs: {'venue': venueName}),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
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

class _PrimaryStatusBlock extends StatelessWidget {
  final List<VerificationRequestResponse> requests;
  final TextEditingController documentsController;
  final bool submitting;
  final VoidCallback onSubmit;
  const _PrimaryStatusBlock({
    required this.requests,
    required this.documentsController,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final latestPending =
        requests.where((r) => r.status.toLowerCase() == 'pending').firstOrNull;
    if (latestPending != null) {
      return _PendingCard(request: latestPending);
    }
    final latestRejected = requests
        .where((r) => r.status.toLowerCase() == 'rejected')
        .firstOrNull;
    return _SubmitForm(
      lastRejection: latestRejected,
      controller: documentsController,
      submitting: submitting,
      onSubmit: onSubmit,
    );
  }
}

class _PendingCard extends StatelessWidget {
  final VerificationRequestResponse request;
  const _PendingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.clock, color: c.onSurfaceSecondary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocaleKeys.manage_venue_verification_under_review_title.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formatRelativeTime(request.submittedAt),
                style: TextStyle(color: c.onSurfaceMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.manage_venue_verification_under_review_body.tr(),
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SubmitForm extends StatelessWidget {
  final VerificationRequestResponse? lastRejection;
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;
  const _SubmitForm({
    required this.lastRejection,
    required this.controller,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lastRejection != null) ...[
          _RejectionCard(request: lastRejection!),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(
                TablerIcons.rosette_discount_check,
                color: c.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  LocaleKeys.manage_venue_verification_intro_headline.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          LocaleKeys.manage_venue_verification_required_label.tr(),
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        for (final r in [
          LocaleKeys.manage_venue_verification_required_doc_cr.tr(),
          LocaleKeys.manage_venue_verification_required_doc_ownership.tr(),
          LocaleKeys.manage_venue_verification_required_doc_contact.tr(),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6, end: 6),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.onSurfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        AppLabeledField(
          label: LocaleKeys.manage_venue_verification_label_supporting_docs.tr(),
          requiredMark: true,
          child: TextField(
            controller: controller,
            maxLines: 6,
            minLines: 4,
            enabled: !submitting,
            style: TextStyle(color: c.onSurface),
            decoration: appInputDecoration(
              c,
              hint: LocaleKeys.manage_venue_verification_supporting_docs_helper.tr(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: submitting ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: c.onSurface,
              foregroundColor: c.surface,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: submitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: c.surface,
                      strokeWidth: 1.5,
                    ),
                  )
                : Text(LocaleKeys.manage_venue_verification_button_submit.tr()),
          ),
        ),
      ],
    );
  }
}

class _RejectionCard extends StatelessWidget {
  final VerificationRequestResponse request;
  const _RejectionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final notes = request.reviewerNotes?.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.danger.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.circle_x, color: c.danger, size: 20),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.manage_venue_verification_rejected_title.tr(),
                style: TextStyle(
                  color: c.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              notes,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            LocaleKeys.manage_venue_verification_rejected_body.tr(),
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final VerificationRequestResponse request;
  const _HistoryTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final status = request.status.toLowerCase();
    final (color, label, icon) = switch (status) {
      'approved' => (c.success, LocaleKeys.manage_venue_verification_status_approved.tr(), TablerIcons.check),
      'rejected' => (c.danger, LocaleKeys.manage_venue_verification_status_rejected.tr(), TablerIcons.x),
      _ => (c.onSurfaceSecondary, LocaleKeys.manage_venue_verification_status_pending.tr(), TablerIcons.clock),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatRelativeTime(request.submittedAt),
                      style: TextStyle(
                        color: c.onSurfaceMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (request.reviewerNotes?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    request.reviewerNotes!,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
