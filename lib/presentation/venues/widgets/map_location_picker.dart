import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:latlong2/latlong.dart';

class MapLocationPicker extends StatefulWidget {
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  const MapLocationPicker({
    super.key,
    required this.latitudeController,
    required this.longitudeController,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> with TickerProviderStateMixin {

  bool isLoading = true;
  bool isMapReady = false;
  Position? currentPosition;
  late AnimatedMapController _animatedMapController;
  final MapController _mapController = MapController();
  LatLng? pickedLocation;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _searching = false;

  final Dio _geo = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'hangout-app/1.0'},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  LatLng? _seededCenter;

  final String sataliteTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  final String darkTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  final String lightTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      isLoading = false;
    });

    _animatedMapController.animateTo(
      dest: LatLng(currentPosition!.latitude, currentPosition!.longitude),
      duration: const Duration(seconds: 5),
      zoom: 15,
      curve: Curves.easeInOut,
      rotation: 30,
    );
  }

  @override
  void initState() {
    super.initState();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
    );

    final preLat = double.tryParse(widget.latitudeController.text);
    final preLng = double.tryParse(widget.longitudeController.text);
    if (preLat != null && preLng != null) {
      _seededCenter = LatLng(preLat, preLng);
      pickedLocation = _seededCenter;
      isLoading = false;
    } else {
      determinePosition();
    }
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _mapController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _geo.close(force: true);
    super.dispose();
  }

  void _applyLocation(LatLng point, {double zoom = 16}) {
    widget.latitudeController.text = point.latitude.toString();
    widget.longitudeController.text = point.longitude.toString();
    setState(() => pickedLocation = point);
    _animatedMapController.animateTo(
      dest: point,
      duration: const Duration(milliseconds: 700),
      zoom: zoom,
      curve: Curves.easeInOut,
    );
  }

  LatLng? _parseCoordinates(String raw) {
    final match = RegExp(
      r'^\s*(-?\d+(?:\.\d+)?)\s*[, ;]\s*(-?\d+(?:\.\d+)?)\s*$',
    ).firstMatch(raw);
    if (match == null) return null;
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  Future<void> _onSearchSubmitted(String raw) async {
    final query = raw.trim();
    if (query.isEmpty) return;

    final coords = _parseCoordinates(query);
    if (coords != null) {
      _applyLocation(coords);
      FocusScope.of(context).unfocus();
      return;
    }

    setState(() => _searching = true);
    try {
      final res = await _geo.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
      );
      final hits = res.data ?? const [];
      if (hits.isEmpty) {
        if (mounted) {
          appToast.info(LocaleKeys.create_venue_map_search_not_found.tr());
        }
        return;
      }
      final hit = hits.first as Map<String, dynamic>;
      final lat = double.tryParse(hit['lat']?.toString() ?? '');
      final lng = double.tryParse(hit['lon']?.toString() ?? '');
      if (lat == null || lng == null) {
        if (mounted) {
          appToast.info(LocaleKeys.create_venue_map_search_not_found.tr());
        }
        return;
      }
      _applyLocation(LatLng(lat, lng));
      if (mounted) FocusScope.of(context).unfocus();
    } on DioException catch (_) {
      if (mounted) {
        appToast.error(LocaleKeys.create_venue_map_search_failed.tr());
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _seededCenter ?? LatLng(33.3152, 44.3661),
              initialZoom: 15,
              onPositionChanged: onPositionChanged,
              onMapReady: () => setState(() => isMapReady = true),
              onTap: (tapPosition, point) {
                widget.latitudeController.text = point.latitude.toString();
                widget.longitudeController.text = point.longitude.toString();

                setState(() => pickedLocation = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? darkTemplate
                    : lightTemplate,
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: pickedLocation != null
                    ? [
                        Marker(
                          rotate: true,
                          point: pickedLocation ?? LatLng(33.3152, 44.3661),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ]
                    : [],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: _MapSearchField(
            controller: _searchController,
            focusNode: _searchFocus,
            busy: _searching,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
      ],
    );
  }

  LatLng? _lastPosition;
  final ValueNotifier<double> _tiltRotation = ValueNotifier(0.0);

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    if (_lastPosition != null) {
      double deltaX = camera.center.longitude - _lastPosition!.longitude;
      double tiltGoal = deltaX * -500;
      _tiltRotation.value = tiltGoal.clamp(-0.5, 0.5);
    }
    _lastPosition = camera.center;
    if (!hasGesture) {
      _tiltRotation.value = 0.0;
    }
  }

}

class _MapSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final ValueChanged<String> onSubmitted;

  const _MapSearchField({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surfaceElevated.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 2, 6, 2),
        child: Row(
          children: [
            Icon(
              TablerIcons.search,
              size: 18,
              color: c.onSurfaceSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmitted,
                style: TextStyle(color: c.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: LocaleKeys.create_venue_map_search_hint.tr(),
                  hintStyle: TextStyle(
                    color: c.onSurfaceMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (busy)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.onSurfaceSecondary,
                  ),
                ),
              )
            else
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, v, _) {
                  if (v.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.clear(),
                    icon: Icon(
                      TablerIcons.x,
                      size: 16,
                      color: c.onSurfaceSecondary,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

