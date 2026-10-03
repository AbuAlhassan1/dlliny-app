import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/update_venue_handle_request.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/widgets/venue_handle_field.dart';

class EditHandlePageWrapper extends StatefulWidget {
  final String venueId;
  final String? currentHandle;
  const EditHandlePageWrapper({
    super.key,
    required this.venueId,
    required this.currentHandle,
  });

  static Future<void> push(
    BuildContext context, {
    required String venueId,
    required String? currentHandle,
  }) {
    final venueBloc = context.read<VenueBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: venueBloc,
          child: EditHandlePageWrapper(
            venueId: venueId,
            currentHandle: currentHandle,
          ),
        ),
      ),
    );
  }

  @override
  State<EditHandlePageWrapper> createState() => _EditHandlePageWrapperState();
}

class _EditHandlePageWrapperState extends State<EditHandlePageWrapper> {
  late final TextEditingController _handle = TextEditingController();
  final VenueHandleFieldController _handleStatus =
      VenueHandleFieldController();
  bool _submitting = false;

  @override
  void dispose() {
    _handle.dispose();
    _handleStatus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final next = _handleStatus.normalizedHandle;
    if (next == null || next.isEmpty) {
      appToast.error(LocaleKeys.manage_venue_handle_error_handle_required.tr());
      return;
    }
    if (_handleStatus.status != HandleFieldStatus.available) {
      appToast.error(LocaleKeys.manage_venue_handle_error_handle_invalid.tr());
      return;
    }
    setState(() => _submitting = true);
    final api = serviceLocator.get<ApiService>();
    try {
      final res = await api.changeVenueHandle(
        widget.venueId,
        UpdateVenueHandleRequest(handle: next),
      );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        appToast.error(res.error ?? LocaleKeys.manage_venue_handle_error_change_fallback.tr());
        setState(() => _submitting = false);
        return;
      }
      appToast.success(LocaleKeys.manage_venue_handle_success_changed.tr());
      context.read<VenueBloc>().add(GetVenueDetails(widget.venueId));
      Navigator.of(context).maybePop(true);
    } on DioException catch (e) {
      if (!mounted) return;
      appToast.error(_mapError(e));
      setState(() => _submitting = false);
    }
  }

  String _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    final serverMsg = (data is Map && data['error'] is String)
        ? data['error'] as String
        : null;
    switch (status) {
      case 409:
        return serverMsg ?? LocaleKeys.manage_venue_handle_error_handle_unavailable.tr();
      case 429:
        return serverMsg ?? LocaleKeys.manage_venue_handle_error_handle_cooldown.tr();
      case 400:
        return serverMsg ?? LocaleKeys.manage_venue_handle_error_handle_format.tr();
      default:
        return serverMsg ?? e.message ?? LocaleKeys.manage_venue_handle_error_change_fallback.tr();
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
          LocaleKeys.manage_venue_handle_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _submitting
                ? Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.onSurface,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: _submit,
                    child: Text(
                      LocaleKeys.manage_venue_handle_button_save.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((widget.currentHandle ?? '').isNotEmpty)
            _CurrentHandleCard(handle: widget.currentHandle!),
          const SizedBox(height: 16),
          VenueHandleField(
            controller: _handle,
            status: _handleStatus,
            label: LocaleKeys.manage_venue_handle_label_new_handle.tr(),
            isRequired: true,
            currentHandle: widget.currentHandle,
          ),
          const SizedBox(height: 16),
          _RulesCard(),
        ],
      ),
    );
  }
}

class _CurrentHandleCard extends StatelessWidget {
  final String handle;
  const _CurrentHandleCard({required this.handle});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.at, color: c.onSurfaceSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.manage_venue_handle_label_current_handle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@$handle',
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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

class _RulesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rules = [
      LocaleKeys.manage_venue_handle_rule_length.tr(),
      LocaleKeys.manage_venue_handle_rule_chars.tr(),
      LocaleKeys.manage_venue_handle_rule_start_end.tr(),
      LocaleKeys.manage_venue_handle_rule_no_double_punct.tr(),
      LocaleKeys.manage_venue_handle_rule_cooldown.tr(),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.info_circle, color: c.primary, size: 14),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.manage_venue_handle_label_rules.tr(),
                style: TextStyle(
                  color: c.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in rules)
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
        ],
      ),
    );
  }
}
