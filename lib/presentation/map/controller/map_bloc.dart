import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/domain/dto/response/shake_recommendation_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/map/controller/venue_branch_hit.dart';
import 'package:latlong2/latlong.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  final MapController mapController = MapController();

  AnimatedMapController? animatedMapController;

  List<MapVenuePinResponse> pins = [];

  List<VenueBranchHit> searchResults = [];

  List<VenueCategoryDto> categories = [];

  int? selectedCategoryId;

  LatLng? _lastViewportCenter;
  int? _lastViewportRadius;

  String? _lastSearchQuery;

  final Set<String> _seenShakeVenueIds = {};

  bool _shakeInFlight = false;

  MapBloc() : super(MapInitial()) {
    on<MapEvent>((event, emit) {});

    on<GetVenuesInViewport>((event, emit) async {
      emit(MapVenuesLoading());
      _lastViewportCenter = LatLng(event.lat, event.lng);
      _lastViewportRadius = event.radiusMeters;
      ApiResponse<List<MapVenuePinResponse>> response;
      try {
        response = await apiService.getMapVenuePins(
          event.lat,
          event.lng,
          radiusMeters: event.radiusMeters.clamp(500, 50000),
          categoryId: selectedCategoryId,
        );
      } on DioException catch (e) {
        log('GetVenuesInViewport: dio failure: ${e.message}');
        emit(MapVenuesError('Failed to load venues: ${e.message}'));
        return;
      }

      if (!response.success || response.data == null) {
        emit(MapVenuesError(response.error ?? 'Failed to load venues'));
        return;
      }

      pins = response.data!;
      log('GetVenuesInViewport: loaded ${pins.length} pins');
      emit(MapVenuesLoaded());
    });

    on<SearchVenues>((event, emit) async {
      final query = event.query.trim();
      if (query.length < 2) {
        searchResults = [];
        _lastSearchQuery = null;
        emit(VenueSearchCleared());
        return;
      }

      _lastSearchQuery = query;
      emit(VenueSearchLoading());

      ApiResponse<PagedResponse<VenueSummaryResponse>> response;
      try {
        response = await apiService.getVenues(
          q: query,
          categoryId: selectedCategoryId,
          page: 0,
          size: 10,
        );
      } on DioException catch (e) {
        emit(VenueSearchError('Search failed: ${e.message}'));
        return;
      }

      if (!response.success || response.data == null) {
        emit(VenueSearchError(response.error ?? 'Search failed'));
        return;
      }

      final summaries = response.data!.content;
      final detailFutures =
          summaries.map((s) => _safeFetchVenue(s.id)).toList();
      final details = await Future.wait(detailFutures);
      final hits = <VenueBranchHit>[];
      for (var i = 0; i < summaries.length; i++) {
        final summary = summaries[i];
        final venue = details[i];
        if (summary.onlineOnly) continue;
        if (venue != null && venue.onlineOnly) continue;
        if (venue == null) {
          final hit = _hitFromSummary(summary);
          if (hit != null) hits.add(hit);
          continue;
        }
        if (venue.locations.isEmpty) {
          final hit = _hitFromVenueTopLevel(venue);
          if (hit != null) hits.add(hit);
          continue;
        }
        final sorted = [...venue.locations]..sort((a, b) {
            if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
            return a.sortOrder.compareTo(b.sortOrder);
          });
        for (final loc in sorted) {
          hits.add(_hitFromBranch(venue, loc));
        }
      }
      searchResults = hits;
      emit(VenueSearchLoaded());
    });

    on<ClearVenueSearch>((event, emit) {
      searchResults = [];
      _lastSearchQuery = null;
      emit(VenueSearchCleared());
    });

    on<LoadMapCategories>((event, emit) async {
      if (categories.isNotEmpty) {
        emit(MapCategoriesLoaded());
        return;
      }
      emit(MapCategoriesLoading());
      try {
        final res = await apiService.getVenueCategories();
        if (res.success && res.data != null) {
          categories = res.data!;
          emit(MapCategoriesLoaded());
        } else {
          emit(MapCategoriesLoaded());
        }
      } on DioException catch (e) {
        log('LoadMapCategories: dio failure: ${e.message}');
        emit(MapCategoriesLoaded());
      }
    });

    on<ShakeRequested>((event, emit) async {
      if (_shakeInFlight) return;
      _shakeInFlight = true;
      emit(ShakeLoading());
      try {
        final res = await apiService.getShakeRandomRecommendations(
          event.lat,
          event.lng,
          includeFar: event.includeFar,
          excludeIds: _seenShakeVenueIds.isEmpty
              ? null
              : _seenShakeVenueIds.toList(),
        );
        if (!res.success || res.data == null) {
          emit(ShakeError(
            res.error ?? LocaleKeys.map_shake_errors_fetch_failed.tr(),
          ));
          return;
        }
        final payload = res.data!;
        if (payload.status == 'OK') {
          for (final v in payload.venues) {
            _seenShakeVenueIds.add(v.venueId);
          }
        }
        emit(ShakeLoaded(
          mode: payload.mode,
          status: payload.status,
          items: payload.venues,
        ));
      } on DioException catch (e) {
        log('ShakeRequested: dio failure: ${e.message}');
        final (message, rateLimited) = _translateShakeError(e);
        emit(ShakeError(message, rateLimited: rateLimited));
      } finally {
        _shakeInFlight = false;
      }
    });

    on<ClearShakeResults>((event, emit) {
      _seenShakeVenueIds.clear();
    });

    on<SetMapCategoryFilter>((event, emit) async {
      if (selectedCategoryId == event.categoryId) return;
      selectedCategoryId = event.categoryId;
      emit(MapCategoryFilterChanged());

      final center = _lastViewportCenter;
      final radius = _lastViewportRadius;
      if (center != null && radius != null) {
        add(GetVenuesInViewport(
          lat: center.latitude,
          lng: center.longitude,
          radiusMeters: radius,
        ));
      }

      final q = _lastSearchQuery;
      if (q != null && q.isNotEmpty) {
        add(SearchVenues(q));
      }
    });
  }

  Future<VenueResponse?> _safeFetchVenue(String venueId) async {
    try {
      final res = await apiService.getVenue(venueId);
      if (!res.success || res.data == null) return null;
      return res.data;
    } on DioException catch (_) {
      return null;
    } catch (e, st) {
      log('_safeFetchVenue($venueId) failed: $e', stackTrace: st);
      return null;
    }
  }

  VenueBranchHit _hitFromBranch(
    VenueResponse venue,
    VenueLocationResponse loc,
  ) {
    return VenueBranchHit(
      venueId: venue.id,
      venueNameAr: venue.nameAr,
      venueNameEn: venue.nameEn,
      venueLogoUrl: venue.logoUrl,
      venueVerified: venue.verified,
      locationId: loc.id,
      labelAr: loc.labelAr,
      labelEn: loc.labelEn,
      cityNameAr: loc.cityNameAr,
      districtNameAr: loc.districtNameAr,
      latitude: loc.latitude,
      longitude: loc.longitude,
      isPrimary: loc.isPrimary,
    );
  }

  VenueBranchHit? _hitFromVenueTopLevel(VenueResponse venue) {
    final lat = venue.latitude;
    final lng = venue.longitude;
    if (lat == null || lng == null) return null;
    return VenueBranchHit(
      venueId: venue.id,
      venueNameAr: venue.nameAr,
      venueNameEn: venue.nameEn,
      venueLogoUrl: venue.logoUrl,
      venueVerified: venue.verified,
      cityNameAr: venue.cityNameAr,
      districtNameAr: venue.districtNameAr,
      latitude: lat,
      longitude: lng,
      isPrimary: true,
    );
  }

  VenueBranchHit? _hitFromSummary(VenueSummaryResponse summary) {
    final lat = summary.latitude;
    final lng = summary.longitude;
    if (lat == null || lng == null) return null;
    return VenueBranchHit(
      venueId: summary.id,
      venueNameAr: summary.nameAr,
      venueNameEn: summary.nameEn,
      venueLogoUrl: summary.logoUrl,
      venueVerified: summary.verified,
      cityNameAr: summary.cityNameAr,
      districtNameAr: summary.districtNameAr,
      latitude: lat,
      longitude: lng,
      isPrimary: true,
    );
  }

}

(String, bool) _translateShakeError(DioException e) {
  final raw = e.response?.data;
  String? serverError;
  if (raw is Map && raw['error'] is String) {
    serverError = raw['error'] as String;
  }
  if (serverError == null || serverError.isEmpty) {
    return (LocaleKeys.map_shake_errors_connection_failed.tr(), false);
  }
  if (serverError.toLowerCase().contains('slow down')) {
    return (LocaleKeys.map_shake_errors_rate_limit.tr(), true);
  }
  return (serverError, false);
}
