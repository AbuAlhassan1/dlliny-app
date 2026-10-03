import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/map/controller/map_bloc.dart';
import 'package:hangout/presentation/map/widgets/place_marker_widget.dart';
import 'package:hangout/presentation/map/widgets/venue_details_sheet.dart';
import 'package:hangout/presentation/shared/widgets/permission_chip.dart';
import 'package:latlong2/latlong.dart';

class MapWidgetOSM extends StatefulWidget {
  const MapWidgetOSM({super.key});

  @override
  State<MapWidgetOSM> createState() => _MapWidgetOSMState();
}

class _MapWidgetOSMState extends State<MapWidgetOSM>
    with TickerProviderStateMixin {
  bool isLoading = true;
  bool isMapReady = false;
  LatLng? _pendingInitialCamera;
  Position? currentPosition;
  bool _locationBlocked = false;
  late AnimatedMapController _animatedMapController;
  final MapController _mapController = MapController();
  LatLng? _lastPosition;
  final ValueNotifier<double> _tiltRotation = ValueNotifier(0.0);
  Timer? _fetchDebounce;
  double _currentZoom = 15.0;
  static const String _darkTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String _lightTemplate =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationBlocked = true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationBlocked = true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationBlocked = true);
      return;
    }

    currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (!mounted) return;
    setState(() {
      isLoading = false;
      _locationBlocked = false;
    });

    final dest = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    if (isMapReady) {
      _animateToInitial(dest);
    } else {
      _pendingInitialCamera = dest;
    }
  }

  Future<void> _requestLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    final current = await Geolocator.checkPermission();
    if (current == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    final next = await Geolocator.requestPermission();
    if (next == LocationPermission.always ||
        next == LocationPermission.whileInUse) {
      determinePosition();
    } else if (mounted) {
      setState(() => _locationBlocked = true);
    }
  }

  void _animateToInitial(LatLng dest) {
    _animatedMapController.animateTo(
      dest: dest,
      duration: const Duration(seconds: 2),
      zoom: 15,
      curve: Curves.easeInOut,
      rotation: 30,
    );
  }

  void _onMapReady() {
    if (!mounted) return;
    setState(() => isMapReady = true);
    final pending = _pendingInitialCamera;
    if (pending != null) {
      _pendingInitialCamera = null;
      _animateToInitial(pending);
    }
  }

  @override
  void initState() {
    super.initState();
    determinePosition();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MapBloc>().animatedMapController = _animatedMapController;
      _scheduleViewportFetch(
        const LatLng(33.3152, 44.3661),
        _radiusFromZoom(15),
        immediate: true,
      );
    });
  }

  @override
  void dispose() {
    _fetchDebounce?.cancel();
    _animatedMapController.dispose();
    _mapController.dispose();
    _tiltRotation.dispose();
    super.dispose();
  }

  int _radiusFromZoom(double zoom) {
    final radius = 40000 / (1 << (zoom.round() - 13).clamp(0, 9));
    return radius.clamp(200, 50000).toInt();
  }

  void _scheduleViewportFetch(
    LatLng center,
    int radiusMeters, {
    bool immediate = false,
  }) {
    _fetchDebounce?.cancel();
    void fire() {
      if (!mounted) return;
      context.read<MapBloc>().add(
            GetVenuesInViewport(
              lat: center.latitude,
              lng: center.longitude,
              radiusMeters: radiusMeters,
            ),
          );
    }

    if (immediate) {
      fire();
    } else {
      _fetchDebounce = Timer(const Duration(milliseconds: 400), fire);
    }
  }

  @override
  Widget build(BuildContext _) {
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (prev, curr) =>
          curr is MapVenuesLoaded ||
          curr is MapVenuesError ||
          curr is MapInitial,
      builder: (context, state) {
        final pins = context.read<MapBloc>().pins;
        final logoByKey = {
          for (final pin in pins) (pin.locationId ?? pin.id): pin.logoUrl,
        };
        return Stack(
          children: [
            Positioned.fill(child: _buildMap(context, pins, logoByKey)),
            if (_locationBlocked)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: SafeArea(
                  top: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: PermissionChip(
                      icon: TablerIcons.map_pin_off,
                      label: LocaleKeys.map_enable_location_button.tr(),
                      onTap: _requestLocation,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMap(
    BuildContext context,
    List<MapVenuePinResponse> pins,
    Map<String, String?> logoByKey,
  ) {
    return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(33.3152, 44.3661),
            initialZoom: 15,
            maxZoom: 20,
            minZoom: 13,
            onPositionChanged: onPositionChanged,
            onMapReady: _onMapReady,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.beestar.dlliny',
            ),
            MarkerLayer(
              rotate: true,
              markers: [
                if (!isLoading)
                  Marker(
                    point: LatLng(
                      currentPosition!.latitude,
                      currentPosition!.longitude,
                    ),
                    width: 80,
                    height: 80,
                    child: const Icon(
                      TablerIcons.circle_filled,
                      color: Colors.blue,
                      size: 15,
                    ).animate().fade().slide(),
                  ),
              ],
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                size: Size(_markerSize, _markerSize),
                alignment: Alignment.center,
                rotate: true,
                markers: [
                  for (final pin in pins)
                    Marker(
                      key: ValueKey(pin.locationId ?? pin.id),
                      point: LatLng(pin.latitude, pin.longitude),
                      height: _markerSize,
                      width: _markerSize,
                      child: PlaceMarkerWidget(
                        tiltRotation: _tiltRotation,
                        pin: pin,
                        onTap: () => showVenueDetailsSheet(
                          context: context,
                          venueId: pin.id,
                          locationId: pin.locationId,
                        ),
                      ),
                    ),
                ],
                builder: (context, markers) {
                  final logos = <String>[];
                  for (final m in markers) {
                    if (logos.length >= 2) break;
                    final k = m.key;
                    if (k is! ValueKey<String>) continue;
                    final url = logoByKey[k.value];
                    if (url != null && url.isNotEmpty) logos.add(url);
                  }
                  return _ClusterBubble(
                    count: markers.length,
                    size: _markerSize,
                    logoUrls: logos,
                  );
                },
              ),
            ),
          ],
        );
  }

  void onPositionChanged(MapCamera camera, bool hasGesture) {
    final snapped = (camera.zoom * 2).roundToDouble() / 2;
    if (snapped != _currentZoom) {
      setState(() => _currentZoom = snapped);
    }

    if (_lastPosition != null) {
      double deltaX = camera.center.longitude - _lastPosition!.longitude;
      double tiltGoal = deltaX * -500;
      _tiltRotation.value = tiltGoal.clamp(-0.5, 0.5);
    }
    _lastPosition = camera.center;
    if (!hasGesture) {
      _tiltRotation.value = 0.0;
    }

    if (hasGesture) {
      _scheduleViewportFetch(camera.center, _radiusFromZoom(camera.zoom));
    }
  }

  double get _markerSize {
    const minSize = 40.0;
    const maxSize = 100.0;
    const minZ = 13.0;
    const maxZ = 20.0;
    final t = ((_currentZoom - minZ) / (maxZ - minZ)).clamp(0.0, 1.0);
    return minSize + (maxSize - minSize) * t;
  }
}

class _ClusterBubble extends StatelessWidget {
  final int count;
  final double size;
  final List<String> logoUrls;

  const _ClusterBubble({
    required this.count,
    required this.size,
    required this.logoUrls,
  });

  @override
  Widget build(BuildContext context) {
    final discSize = size * 0.6;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orangeAccent, width: 2),
      ),
      child: logoUrls.isEmpty
          ? _CountLabel(count: count)
          : Stack(
              clipBehavior: Clip.none,
              children: [
                if (logoUrls.length > 1)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: _ClusterAvatar(
                      url: logoUrls[1],
                      size: discSize,
                    ),
                  ),
                Positioned(
                  left: 4,
                  top: 4,
                  child: _ClusterAvatar(
                    url: logoUrls[0],
                    size: discSize,
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: _CountBadge(count: count, parentSize: size),
                ),
              ],
            ),
    );
  }
}

class _ClusterAvatar extends StatelessWidget {
  final String url;
  final double size;
  const _ClusterAvatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: (size * 3).round(),
          errorWidget: (_, _, _) => const Icon(
            TablerIcons.map_pin,
            color: Colors.black54,
            size: 14,
          ),
        ),
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  final int count;
  const _CountLabel({required this.count});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final double parentSize;
  const _CountBadge({required this.count, required this.parentSize});

  @override
  Widget build(BuildContext context) {
    final fontSize = (parentSize * 0.22).clamp(10.0, 16.0);
    final pad = (parentSize * 0.06).clamp(4.0, 8.0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad / 2),
      constraints: BoxConstraints(minWidth: parentSize * 0.34),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          height: 1.0,
        ),
      ),
    );
  }
}
