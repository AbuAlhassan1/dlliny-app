import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_map_carousel.dart';
import 'package:hangout/presentation/map/controller/map_bloc.dart';
import 'package:hangout/presentation/map/widgets/map_widget_osm.dart';
import 'package:hangout/presentation/map/widgets/shake_chip.dart';
import 'package:hangout/presentation/map/widgets/shake_results_sheet.dart';
import 'package:hangout/presentation/map/widgets/venue_search_bar.dart';
import 'package:shake/shake.dart';

class MapPageWrapper extends StatefulWidget {
  const MapPageWrapper({super.key});

  @override
  State<MapPageWrapper> createState() => _MapPageWrapperState();
}

class _MapPageWrapperState extends State<MapPageWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => MapBloc(),
      child: const _MapPageBody(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _MapPageBody extends StatefulWidget {
  const _MapPageBody();

  @override
  State<_MapPageBody> createState() => _MapPageBodyState();
}

class _MapPageBodyState extends State<_MapPageBody>
    with WidgetsBindingObserver {
  ShakeDetector? _shakeDetector;

  DateTime? _lastShakeAt;

  bool _locationAvailable = false;

  bool _resolvingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshLocationState();
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) => _onShakeDetected(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLocationState();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shakeDetector?.stopListening();
    super.dispose();
  }

  Future<void> _refreshLocationState() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    final available = serviceEnabled &&
        (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse);
    if (!mounted) return;
    if (available != _locationAvailable) {
      setState(() => _locationAvailable = available);
    }
  }

  void _onShakeDetected() {
    final now = DateTime.now();
    if (_lastShakeAt != null &&
        now.difference(_lastShakeAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastShakeAt = now;
    if (!_locationAvailable) {
      return;
    }
    HapticFeedback.mediumImpact();
    _fireShakeFlow();
  }

  void _onChipTapped() {
    if (!_locationAvailable) {
      appToast.error(LocaleKeys.map_location_required_toast.tr());
      return;
    }
    _fireShakeFlow();
  }

  Future<void> _fireShakeFlow() async {
    if (_resolvingLocation) return;
    _resolvingLocation = true;

    Position? pos;
    try {
      pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 8),
      );
    } on TimeoutException {
      pos = null;
    } catch (_) {
      pos = null;
    } finally {
      _resolvingLocation = false;
    }
    if (!mounted) return;
    if (pos == null) {
      appToast.error(LocaleKeys.map_location_failed_toast.tr());
      return;
    }

    context.read<MapBloc>().add(ShakeRequested(
          mode: 'LOVE_IT',
          lat: pos.latitude,
          lng: pos.longitude,
        ));
    ShakeResultsSheet.show(context, lat: pos.latitude, lng: pos.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: MapWidgetOSM()),

          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.05,
                  color: Colors.transparent,
                ),
                Expanded(
                  child: IgnorePointer(
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.05,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: VenueSearchBar(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.only(top: 10),
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            color: c.background.withValues(alpha: 0.2),
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const NearbyVenuesMapCarousel(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_locationAvailable)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ShakeChip(onTap: _onChipTapped),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
