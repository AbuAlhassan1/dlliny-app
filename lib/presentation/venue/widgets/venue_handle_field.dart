import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/handle_availability_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venue/utils/venue_handle_validator.dart';

enum HandleFieldStatus {
  empty,

  invalidFormat,

  checking,

  available,

  unavailable,

  error;

  bool get canSubmit =>
      this == HandleFieldStatus.available ||
      this == HandleFieldStatus.empty;
}

class VenueHandleFieldController extends ChangeNotifier {
  HandleFieldStatus _status = HandleFieldStatus.empty;
  String? _reason;
  String? _normalizedHandle;

  HandleFieldStatus get status => _status;

  String? get lastReason => _reason;

  String? get normalizedHandle => _normalizedHandle;

  void _update(
    HandleFieldStatus next, {
    String? reason,
    String? normalizedHandle,
  }) {
    if (_status == next &&
        _reason == reason &&
        _normalizedHandle == normalizedHandle) {
      return;
    }
    _status = next;
    _reason = reason;
    _normalizedHandle = normalizedHandle;
    notifyListeners();
  }
}

class VenueHandleField extends StatefulWidget {
  final TextEditingController controller;
  final VenueHandleFieldController status;

  final String? label;

  final bool isRequired;

  final String? currentHandle;

  const VenueHandleField({
    super.key,
    required this.controller,
    required this.status,
    this.label,
    this.isRequired = false,
    this.currentHandle,
  });

  @override
  State<VenueHandleField> createState() => _VenueHandleFieldState();
}

class _VenueHandleFieldState extends State<VenueHandleField> {
  Timer? _debounce;

  int _latestSeq = 0;

  String? _lastQueried;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _evaluate(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged() => _evaluate(widget.controller.text);

  void _evaluate(String raw) {
    final normalized = raw.trim().toLowerCase().replaceFirst(RegExp(r'^@+'), '');
    if (normalized.isEmpty) {
      _debounce?.cancel();
      widget.status._update(
        widget.isRequired
            ? HandleFieldStatus.invalidFormat
            : HandleFieldStatus.empty,
        normalizedHandle: null,
      );
      return;
    }

    final formatError = validateVenueHandle(
      normalized,
      currentHandle: widget.currentHandle,
    );
    if (formatError != null) {
      _debounce?.cancel();
      widget.status._update(
        HandleFieldStatus.error,
        normalizedHandle: normalized,
      );
      return;
    }

    if (_lastQueried == normalized) {
      return;
    }

    widget.status._update(
      HandleFieldStatus.checking,
      normalizedHandle: normalized,
    );
    _debounce?.cancel();
    final seq = ++_latestSeq;
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _lookup(normalized, seq);
    });
  }

  Future<void> _lookup(String handle, int seq) async {
    final api = serviceLocator.get<ApiService>();
    try {
      final res = await api.checkVenueHandleAvailability(handle);
      if (!mounted || seq != _latestSeq) return;
      _lastQueried = handle;
      if (!res.success || res.data == null) {
        widget.status._update(
          HandleFieldStatus.error,
          normalizedHandle: handle,
        );
        return;
      }
      final body = res.data!;
      if (body.available) {
        widget.status._update(
          HandleFieldStatus.available,
          normalizedHandle: body.handle,
        );
      } else {
        widget.status._update(
          HandleFieldStatus.unavailable,
          reason: body.reason,
          normalizedHandle: body.handle,
        );
      }
    } on DioException {
      if (!mounted || seq != _latestSeq) return;
      widget.status._update(
        HandleFieldStatus.error,
        normalizedHandle: handle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppLabeledField(
      label: widget.label ?? LocaleKeys.venue_handle_label_optional.tr(),
      requiredMark: widget.isRequired,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            style: TextStyle(color: c.onSurface),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_.]')),
              TextInputFormatter.withFunction(
                (oldVal, newVal) => newVal.copyWith(
                  text: newVal.text.toLowerCase(),
                ),
              ),
            ],
            decoration: appInputDecoration(
              c,
              hint: 'cafe_beirut',
              prefixIcon: Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 14, end: 4),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    '@',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              suffixIcon: _SuffixIcon(status: widget.status),
            ),
          ),
          const SizedBox(height: 6),
          _StatusLine(
            status: widget.status,
            controller: widget.controller,
            currentHandle: widget.currentHandle,
            isRequired: widget.isRequired,
          ),
        ],
      ),
    );
  }
}

class _SuffixIcon extends StatelessWidget {
  final VenueHandleFieldController status;
  const _SuffixIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: status,
      builder: (context, _) {
        switch (status.status) {
          case HandleFieldStatus.checking:
            return Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: c.onSurfaceSecondary,
                ),
              ),
            );
          case HandleFieldStatus.available:
            return Icon(
              TablerIcons.circle_check_filled,
              color: c.success,
              size: 18,
            );
          case HandleFieldStatus.unavailable:
          case HandleFieldStatus.error:
          case HandleFieldStatus.invalidFormat:
            return Icon(
              TablerIcons.alert_circle_filled,
              color: c.danger,
              size: 18,
            );
          case HandleFieldStatus.empty:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

class _StatusLine extends StatelessWidget {
  final VenueHandleFieldController status;
  final TextEditingController controller;
  final String? currentHandle;
  final bool isRequired;
  const _StatusLine({
    required this.status,
    required this.controller,
    required this.currentHandle,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedBuilder(
      animation: Listenable.merge([status, controller]),
      builder: (context, _) {
        switch (status.status) {
          case HandleFieldStatus.empty:
            return isRequired
                ? const SizedBox.shrink()
                : _hint(c, LocaleKeys.venue_handle_hint_auto.tr());
          case HandleFieldStatus.checking:
            return _hint(c, LocaleKeys.venue_handle_hint_checking.tr());
          case HandleFieldStatus.available:
            return _success(c, LocaleKeys.venue_handle_hint_available.tr());
          case HandleFieldStatus.invalidFormat:
            final localMsg = validateVenueHandle(
              controller.text,
              required: isRequired,
              currentHandle: currentHandle,
            );
            return _error(c, localMsg ?? LocaleKeys.venue_handle_hint_invalid_format.tr());
          case HandleFieldStatus.unavailable:
            return _error(c, _reasonToMessage(status.lastReason));
          case HandleFieldStatus.error:
            final typed =
                controller.text.trim().toLowerCase().replaceFirst(
                      RegExp(r'^@+'),
                      '',
                    );
            if (currentHandle != null &&
                typed == currentHandle!.toLowerCase()) {
              return _error(
                c,
                LocaleKeys.venue_handle_hint_same_as_current.tr(),
              );
            }
            return _error(c, LocaleKeys.venue_handle_hint_check_failed.tr());
        }
      },
    );
  }

  Widget _hint(AppColors c, String msg) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Row(
          children: [
            Icon(
              TablerIcons.info_circle,
              color: c.onSurfaceSecondary,
              size: 11,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _success(AppColors c, String msg) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Row(
          children: [
            Icon(
              TablerIcons.circle_check_filled,
              color: c.success,
              size: 11,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: c.success,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _error(AppColors c, String msg) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Text(
          msg,
          style: TextStyle(color: c.danger, fontSize: 11),
        ),
      );

  String _reasonToMessage(String? code) {
    switch (code) {
      case VenueHandleReason.invalidFormat:
        return LocaleKeys.venue_handle_hint_invalid_format.tr();
      case VenueHandleReason.reserved:
        return LocaleKeys.venue_handle_hint_reserved.tr();
      case VenueHandleReason.taken:
        return LocaleKeys.venue_handle_hint_taken.tr();
      case VenueHandleReason.cooldown:
        return LocaleKeys.venue_handle_hint_rate_limited.tr();
      default:
        return LocaleKeys.venue_handle_hint_unavailable.tr();
    }
  }
}
