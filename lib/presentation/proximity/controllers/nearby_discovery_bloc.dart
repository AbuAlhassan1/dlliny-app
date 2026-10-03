import 'dart:async';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/proximity_reporter.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/proximity_settings_request.dart';
import 'package:hangout/generated/locale_keys.g.dart';

part 'nearby_discovery_event.dart';
part 'nearby_discovery_state.dart';

class NearbyDiscoveryBloc
    extends Bloc<NearbyDiscoveryEvent, NearbyDiscoveryState> {
  static const int _probeLimit = 1;

  final ApiService _api = serviceLocator.get<ApiService>();

  bool? _discoverable;

  NearbyDiscoveryBloc() : super(const NearbyDiscoveryInitial()) {
    on<LoadNearbyDiscovery>(_onLoad);
    on<ToggleNearbyDiscovery>(_onToggle);
  }

  Future<void> _onLoad(
    LoadNearbyDiscovery event,
    Emitter<NearbyDiscoveryState> emit,
  ) async {
    emit(const NearbyDiscoveryLoading());
    try {
      final response = await _api.getNearbySuggestions(limit: _probeLimit);
      if (emit.isDone) return;
      if (!response.success || response.data == null) {
        emit(const NearbyDiscoveryUnavailable());
        return;
      }
      _discoverable = response.data!.discoverable;
      emit(NearbyDiscoveryReady(discoverable: _discoverable!));
    } on DioException catch (_) {
      if (emit.isDone) return;
      emit(const NearbyDiscoveryUnavailable());
    } catch (_) {
      if (emit.isDone) return;
      emit(const NearbyDiscoveryUnavailable());
    }
  }

  Future<void> _onToggle(
    ToggleNearbyDiscovery event,
    Emitter<NearbyDiscoveryState> emit,
  ) async {
    final known = _discoverable;
    if (known == null) return;

    final target = event.discoverable;
    if (target == known) return;

    emit(NearbyDiscoveryUpdating(discoverable: known));

    if (target) {
      final blocked = await _blockingLocationReason();
      if (emit.isDone) return;
      if (blocked != null) {
        emit(NearbyDiscoveryError(blocked, discoverable: known));
        return;
      }
    }

    ApiResponse<void> response;
    try {
      response = await _api.updateProximitySettings(
        ProximitySettingsRequest(discoverable: target),
      );
    } on DioException catch (_) {
      if (emit.isDone) return;
      emit(NearbyDiscoveryError(
        LocaleKeys.settings_nearby_discovery_update_failed.tr(),
        discoverable: known,
      ));
      return;
    } catch (_) {
      if (emit.isDone) return;
      emit(NearbyDiscoveryError(
        LocaleKeys.settings_nearby_discovery_update_failed.tr(),
        discoverable: known,
      ));
      return;
    }
    if (emit.isDone) return;

    if (!response.success) {
      emit(NearbyDiscoveryError(
        response.error ??
            LocaleKeys.settings_nearby_discovery_update_failed.tr(),
        discoverable: known,
      ));
      return;
    }

    _discoverable = target;

    if (target) {
      unawaited(ProximityReporter.instance.reportIfPermitted());
    }

    emit(NearbyDiscoveryReady(discoverable: target, justChanged: true));
  }

  Future<String?> _blockingLocationReason() async {
    try {
      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) {
        return LocaleKeys.settings_nearby_discovery_error_location_service.tr();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return LocaleKeys.settings_nearby_discovery_error_permission_blocked
            .tr();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return LocaleKeys.settings_nearby_discovery_error_permission.tr();
      }
      return null;
    } catch (_) {
      return LocaleKeys.settings_nearby_discovery_update_failed.tr();
    }
  }
}
