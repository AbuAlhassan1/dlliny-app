import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/api/api_service.dart';
import '../../domain/dto/request/requests.dart';
import '../di/injection_container.dart';

class ProximityReporter {
  ProximityReporter._();

  static final ProximityReporter instance = ProximityReporter._();

  bool _inFlight = false;

  AppLifecycleListener? _lifecycle;

  void start() {
    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(onResume: reportIfPermitted);
    reportIfPermitted();
  }

  void stop() {
    _lifecycle?.dispose();
    _lifecycle = null;
  }

  Future<void> reportIfPermitted() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!granted) return;

      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return;

      await serviceLocator.get<ApiService>().reportProximityPing(
            ProximityPingRequest(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
          );
    } catch (_) {
    } finally {
      _inFlight = false;
    }
  }
}
