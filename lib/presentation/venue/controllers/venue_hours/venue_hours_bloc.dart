import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';

part 'venue_hours_event.dart';
part 'venue_hours_state.dart';

class VenueHoursBloc extends Bloc<VenueHoursEvent, VenueHoursState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  static const Duration soonWindow = Duration(minutes: 60);

  static const Duration slack = Duration(seconds: 5);
  static const Duration minRefreshDelay = Duration(seconds: 30);
  static const Duration maxRefreshDelay = Duration(hours: 6);

  static const Duration _firstRetry = Duration(seconds: 30);
  static const Duration _maxRetry = Duration(minutes: 10);

  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _refreshing = false;
  int _failures = 0;

  bool _notFound = false;

  VenueHoursBloc({required this.venueId, bool observeLifecycle = true})
    : super(const VenueHoursInitial()) {
    on<VenueHoursSeeded>(_onSeeded);
    on<VenueHoursRefreshRequested>(_onRefresh);
    if (observeLifecycle) {
      _lifecycle = AppLifecycleListener(
        onResume: () {
          if (!isClosed) {
            add(const VenueHoursRefreshRequested(scheduled: true));
          }
        },
      );
    }
  }

  static Duration refreshDelay(VenueOpeningHoursDto dto) {
    final evaluated = DateTime.tryParse(dto.evaluatedAt);
    if (evaluated == null) return maxRefreshDelay;

    DateTime? earliest;
    void consider(DateTime? t) {
      if (t != null && (earliest == null || t.isBefore(earliest!))) {
        earliest = t;
      }
    }

    for (final scope in [dto.summary, ...dto.branches]) {
      final s = scope.status;
      consider(_instant(s.nextChangeAt));
      if (s.state == OpenState.open && !s.closingSoon) {
        consider(_instant(s.closesAt?.at)?.subtract(soonWindow));
      }
      if (s.state == OpenState.closed && !s.openingSoon) {
        consider(_instant(s.opensAt?.at)?.subtract(soonWindow));
      }
    }
    consider(nextBaghdadMidnight(dto.evaluatedAt));

    final target = earliest;
    if (target == null) return maxRefreshDelay;
    final delay = target.difference(evaluated) + slack;
    if (delay < minRefreshDelay) return minRefreshDelay;
    if (delay > maxRefreshDelay) return maxRefreshDelay;
    return delay;
  }

  static DateTime? nextBaghdadMidnight(String evaluatedAt) {
    if (evaluatedAt.length < 10) return null;
    final day = parseYmd(evaluatedAt.substring(0, 10));
    if (day == null) return null;
    return day.add(const Duration(days: 1)).subtract(const Duration(hours: 3));
  }

  static DateTime? _instant(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);

  void _onSeeded(VenueHoursSeeded event, Emitter<VenueHoursState> emit) {
    _accept(event.hours, emit);
  }

  Future<void> _onRefresh(
    VenueHoursRefreshRequested event,
    Emitter<VenueHoursState> emit,
  ) async {
    if (event.scheduled && (state.dto == null || _notFound)) return;
    if (_refreshing) return;
    _refreshing = true;
    try {
      final res = await _api.getVenueOpeningHours(venueId);
      final dto = res.data;
      if (res.success && dto != null) {
        _accept(dto, emit);
      } else {
        _fail(emit);
      }
    } catch (error, stackTrace) {
      log('VenueHoursRefresh($venueId) failed: $error', stackTrace: stackTrace);
      _fail(
        emit,
        notFound: error is DioException && error.response?.statusCode == 404,
      );
    } finally {
      _refreshing = false;
    }
  }

  void _accept(VenueOpeningHoursDto dto, Emitter<VenueHoursState> emit) {
    final current = state.dto;
    if (current != null && _evaluatedBefore(dto, current)) {
      if (_timer?.isActive != true) _schedule(refreshDelay(current));
      return;
    }
    _failures = 0;
    _notFound = false;
    emit(VenueHoursReady(dto));
    _schedule(refreshDelay(dto));
  }

  void _fail(Emitter<VenueHoursState> emit, {bool notFound = false}) {
    _failures++;
    _notFound = notFound;
    emit(VenueHoursRefreshFailed(state.dto));
    if (notFound || state.dto == null) {
      _timer?.cancel();
      return;
    }
    final backoff = _firstRetry * (1 << (_failures - 1).clamp(0, 5));
    _schedule(backoff > _maxRetry ? _maxRetry : backoff);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      if (!isClosed) add(const VenueHoursRefreshRequested(scheduled: true));
    });
  }

  static bool _evaluatedBefore(VenueOpeningHoursDto a, VenueOpeningHoursDto b) {
    final ta = DateTime.tryParse(a.evaluatedAt);
    final tb = DateTime.tryParse(b.evaluatedAt);
    return ta != null && tb != null && ta.isBefore(tb);
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _lifecycle?.dispose();
    return super.close();
  }
}

VenueHoursBloc? maybeVenueHoursBloc(BuildContext context) =>
    context.read<VenueHoursBloc?>();
