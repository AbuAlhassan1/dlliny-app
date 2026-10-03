import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';

part 'nearby_venues_event.dart';
part 'nearby_venues_state.dart';

class NearbyVenuesBloc
    extends Bloc<NearbyVenuesEvent, NearbyVenuesState> {
  static const int _radiusMeters = 2000;

  static const int _limit = 20;

  final ApiService _api = serviceLocator.get<ApiService>();

  NearbyVenuesBloc() : super(const NearbyVenuesInitial()) {
    on<LoadNearbyVenues>(_onLoad);
    on<RequestNearbyVenuesPermission>(_onRequestPermission);
  }

  Future<void> _onLoad(
    LoadNearbyVenues event,
    Emitter<NearbyVenuesState> emit,
  ) async {
    emit(const NearbyVenuesLoading());

    final gate = await _ensureLocationReady();
    if (gate != null) {
      emit(gate);
      return;
    }

    try {
      final position = await _resolvePosition();
      if (position == null) {
        emit(const NearbyVenuesError());
        return;
      }
      final response = await _api.getNearbyVenues(
        position.latitude,
        position.longitude,
        radiusMeters: event.radiusMeters ?? _radiusMeters,
        limit: event.limit ?? _limit,
      );
      if (!response.success || response.data == null) {
        emit(const NearbyVenuesError());
        return;
      }
      final items = response.data!;
      if (items.isEmpty) {
        emit(const NearbyVenuesEmpty());
        return;
      }
      emit(NearbyVenuesLoaded(items));
      final locationName = await _reverseGeocode(position);
      if (emit.isDone) return;
      if (locationName != null) {
        emit(NearbyVenuesLoaded(items, locationName: locationName));
      }
    } on DioException catch (_) {
      emit(const NearbyVenuesError());
    } catch (_) {
      emit(const NearbyVenuesError());
    }
  }

  Future<Position?> _resolvePosition() async {
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {
      lastKnown = null;
    }
    if (lastKnown != null) return lastKnown;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _reverseGeocode(Position position) async {
    try {
      final placemarks = await Geocoding()
          .placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(const Duration(seconds: 5), onTimeout: () => <Placemark>[]);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      for (final candidate in [
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
        final v = candidate?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onRequestPermission(
    RequestNearbyVenuesPermission event,
    Emitter<NearbyVenuesState> emit,
  ) async {
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    final next = await Geolocator.requestPermission();
    if (next == LocationPermission.always ||
        next == LocationPermission.whileInUse) {
      add(LoadNearbyVenues());
    } else {
      emit(NearbyVenuesPermissionDenied(
        canRetry: next != LocationPermission.deniedForever,
      ));
    }
  }

  Future<NearbyVenuesState?> _ensureLocationReady() async {
    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) return const NearbyVenuesLocationDisabled();

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      return const NearbyVenuesPermissionDenied(canRetry: true);
    }
    if (perm == LocationPermission.deniedForever) {
      return const NearbyVenuesPermissionDenied(canRetry: false);
    }
    return null;
  }
}
