import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/proximity_reporter.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/proximity_settings_request.dart';
import 'package:hangout/domain/dto/response/follow_action_response.dart';
import 'package:hangout/domain/dto/response/nearby_suggestion_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

part 'people_nearby_event.dart';
part 'people_nearby_state.dart';

class PeopleNearbyBloc extends Bloc<PeopleNearbyEvent, PeopleNearbyState> {
  static const int _limit = 10;

  final ApiService _api = serviceLocator.get<ApiService>();

  List<NearbySuggestionResponse> _people = <NearbySuggestionResponse>[];

  final Map<String, FollowStatus> _followed = <String, FollowStatus>{};

  final Set<String> _followInFlight = <String>{};

  PeopleNearbyBloc() : super(const PeopleNearbyInitial()) {
    on<LoadPeopleNearby>(_onLoad);
    on<EnableNearbyDiscovery>(_onEnable);
    on<DismissPerson>(_onDismiss);
    on<FollowPerson>(_onFollow);
  }

  Future<void> _onLoad(
    LoadPeopleNearby event,
    Emitter<PeopleNearbyState> emit,
  ) async {
    emit(const PeopleNearbyLoading());
    try {
      final response = await _api.getNearbySuggestions(limit: _limit);
      if (emit.isDone) return;
      if (!response.success || response.data == null) {
        emit(const PeopleNearbyError());
        return;
      }

      final payload = response.data!;
      if (!payload.discoverable) {
        _people = <NearbySuggestionResponse>[];
        _followed.clear();
        emit(const PeopleNearbyNeedsOptIn());
        return;
      }

      _people = List<NearbySuggestionResponse>.of(payload.suggestions);
      _followed.removeWhere(
        (userId, _) => !_people.any((person) => person.userId == userId),
      );

      if (_people.isEmpty) {
        emit(const PeopleNearbyEmpty());
        return;
      }
      emit(_loaded());
    } on DioException catch (_) {
      if (emit.isDone) return;
      emit(const PeopleNearbyError());
      return;
    } catch (_) {
      if (emit.isDone) return;
      emit(const PeopleNearbyError());
    }
  }

  Future<void> _onEnable(
    EnableNearbyDiscovery event,
    Emitter<PeopleNearbyState> emit,
  ) async {
    if (state is PeopleNearbyEnabling) return;
    emit(const PeopleNearbyEnabling());

    final gate = await _ensureLocationPermission();
    if (emit.isDone) return;
    if (gate != _LocationGate.ready) {
      if (gate == _LocationGate.serviceOff) {
        appToast.error(
          LocaleKeys.people_nearby_enable_error_service_disabled.tr(),
        );
      } else if (gate == _LocationGate.blocked) {
        appToast.error(
          LocaleKeys.people_nearby_enable_error_permission_blocked.tr(),
        );
        await Geolocator.openAppSettings();
        if (emit.isDone) return;
      } else {
        appToast.error(
          LocaleKeys.people_nearby_enable_error_permission_denied.tr(),
        );
      }
      emit(const PeopleNearbyNeedsOptIn());
      return;
    }

    try {
      final response = await _api.updateProximitySettings(
        const ProximitySettingsRequest(discoverable: true),
      );
      if (emit.isDone) return;
      if (!response.success) {
        appToast.error(LocaleKeys.people_nearby_enable_failed.tr());
        emit(const PeopleNearbyNeedsOptIn());
        return;
      }
    } on DioException catch (_) {
      if (emit.isDone) return;
      appToast.error(LocaleKeys.people_nearby_enable_failed.tr());
      emit(const PeopleNearbyNeedsOptIn());
      return;
    } catch (_) {
      if (emit.isDone) return;
      appToast.error(LocaleKeys.people_nearby_enable_failed.tr());
      emit(const PeopleNearbyNeedsOptIn());
      return;
    }

    await ProximityReporter.instance.reportIfPermitted();
    if (emit.isDone) return;

    appToast.success(LocaleKeys.people_nearby_enable_success.tr());
    add(LoadPeopleNearby());
  }

  Future<void> _onDismiss(
    DismissPerson event,
    Emitter<PeopleNearbyState> emit,
  ) async {
    final index = _people.indexWhere((person) => person.userId == event.userId);
    if (index < 0) return;

    final removed = _people.removeAt(index);
    _followed.remove(event.userId);
    emit(_people.isEmpty ? const PeopleNearbyEmpty() : _loaded());

    try {
      final response = await _api.dismissNearbySuggestion(event.userId);
      if (emit.isDone) return;
      if (response.success) return;
    } on DioException catch (_) {
      if (emit.isDone) return;
    } catch (_) {
      if (emit.isDone) return;
    }

    _reinsert(index, removed);
    appToast.error(LocaleKeys.people_nearby_dismiss_failed.tr());
    emit(_loaded());
  }

  Future<void> _onFollow(
    FollowPerson event,
    Emitter<PeopleNearbyState> emit,
  ) async {
    if (_followed.containsKey(event.userId)) return;
    if (!_people.any((person) => person.userId == event.userId)) return;

    if (!_followInFlight.add(event.userId)) return;

    try {
      final response = await _api.followUser(event.userId);
      if (emit.isDone) return;
      if (!response.success || response.data == null) {
        appToast.error(LocaleKeys.people_nearby_follow_failed.tr());
        return;
      }
      _followed[event.userId] = response.data!.status;
    } on DioException catch (_) {
      if (emit.isDone) return;
      appToast.error(LocaleKeys.people_nearby_follow_failed.tr());
    } catch (_) {
      if (emit.isDone) return;
      appToast.error(LocaleKeys.people_nearby_follow_failed.tr());
    } finally {
      _followInFlight.remove(event.userId);
    }
    if (emit.isDone) return;
    emit(_loaded());
  }

  void _reinsert(int index, NearbySuggestionResponse person) {
    final at = index < _people.length ? index : _people.length;
    _people.insert(at, person);
  }

  PeopleNearbyLoaded _loaded() => PeopleNearbyLoaded(
        List<NearbySuggestionResponse>.unmodifiable(_people),
        followed: Map<String, FollowStatus>.unmodifiable(_followed),
      );

  Future<_LocationGate> _ensureLocationPermission() async {
    try {
      final servicesOn = await Geolocator.isLocationServiceEnabled();
      if (!servicesOn) return _LocationGate.serviceOff;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return _LocationGate.blocked;
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return _LocationGate.ready;
      }
      return _LocationGate.denied;
    } catch (_) {
      return _LocationGate.denied;
    }
  }
}

enum _LocationGate { ready, serviceOff, denied, blocked }
