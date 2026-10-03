import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/check_in_request.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/challenges/controllers/challenge_detail/challenge_detail_bloc.dart';

class CheckInButton extends StatefulWidget {
  final Map<String, dynamic> config;
  const CheckInButton({super.key, required this.config});

  @override
  State<CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<CheckInButton> {
  bool _busy = false;

  List<String> get _branchIds {
    final raw = widget.config['branchIds'];
    if (raw is! List) return const [];
    return raw.whereType<String>().toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final branchIds = _branchIds;
    if (branchIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: c.primary,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _busy ? null : _handleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: _busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: c.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(TablerIcons.map_pin_check,
                            color: c.onPrimary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          LocaleKeys.check_in_cta.tr(),
                          style: TextStyle(
                            color: c.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap() async {
    setState(() => _busy = true);
    try {
      final position = await _resolvePosition();
      if (position == null) return;
      if (!mounted) return;
      await _submit(position);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Position?> _resolvePosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      appToast.error(LocaleKeys.check_in_error_service_disabled.tr());
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      appToast.error(LocaleKeys.check_in_error_permission_denied.tr());
      return null;
    }

    try {
      final cached = await Geolocator.getLastKnownPosition();
      if (cached != null) return cached;
    } catch (_) {}
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      appToast.error(LocaleKeys.check_in_error_generic.tr());
      return null;
    }
  }

  Future<void> _submit(Position position) async {
    final api = serviceLocator.get<ApiService>();
    final req = CheckInRequest(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    String? firstError;
    for (final branchId in _branchIds) {
      try {
        final res = await api.checkInAtBranch(branchId, req);
        if (res.success && res.data != null) {
          if (!mounted) return;
          appToast.success(
            LocaleKeys.check_in_success_toast.tr(namedArgs: {
              'distance': res.data!.distanceMeters.toString(),
            }),
          );
          if (mounted) {
            context
                .read<ChallengeDetailBloc>()
                .add(const RefreshChallengeDetail());
          }
          return;
        }
        firstError ??= _translateServerError(res.error);
      } on DioException catch (e) {
        final serverMsg = _extractDioMessage(e);
        firstError ??= _translateServerError(serverMsg);
      } catch (_) {
        firstError ??= LocaleKeys.check_in_error_generic.tr();
      }
    }
    if (!mounted) return;
    appToast.error(firstError ?? LocaleKeys.check_in_error_generic.tr());
  }

  String? _extractDioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return (data['error'] as String).trim();
    }
    return e.message;
  }

  String _translateServerError(String? raw) {
    if (raw == null || raw.isEmpty) {
      return LocaleKeys.check_in_error_generic.tr();
    }
    final lower = raw.toLowerCase();
    if (lower.contains('too far')) {
      final distance = _extractDistance(raw);
      return distance != null
          ? LocaleKeys.check_in_error_too_far
              .tr(namedArgs: {'distance': distance})
          : LocaleKeys.check_in_error_too_far
              .tr(namedArgs: {'distance': '?'});
    }
    if (lower.contains('already checked in') || lower.contains('cooldown')) {
      return LocaleKeys.check_in_error_cooldown.tr();
    }
    if (lower.contains('too many')) {
      return LocaleKeys.check_in_error_rate_limited.tr();
    }
    if (lower.contains('inactive')) {
      return LocaleKeys.check_in_error_inactive.tr();
    }
    return raw;
  }

  String? _extractDistance(String raw) {
    final match = RegExp(r'(\d+)\s*m').firstMatch(raw);
    return match?.group(1);
  }
}
