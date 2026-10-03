import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/notifications/fcm_service.dart';
import 'package:hangout/core/notifications/incoming_notification.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/user_points_response.dart';

part 'user_points_event.dart';
part 'user_points_state.dart';

class UserPointsBloc extends Bloc<UserPointsEvent, UserPointsState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  late final StreamSubscription<IncomingNotification> _fcmSub;

  UserPointsResponse? _points;
  UserPointsResponse? get points => state.points ?? _points;

  UserPointsBloc() : super(const UserPointsInitial()) {
    _fcmSub = FcmService.instance.onIncomingNotification.listen((n) {
      if (n.type == 'LEVEL_UP') add(RefreshUserPoints());
    });

    on<UserPointsEvent>((event, emit) {});

    on<LoadUserPoints>(_onLoad);
    on<RefreshUserPoints>(_onLoad);

    on<ClearUserPoints>((event, emit) {
      _points = null;
      emit(const UserPointsInitial());
    });
  }

  @override
  Future<void> close() {
    _fcmSub.cancel();
    return super.close();
  }

  Future<void> _onLoad(
    UserPointsEvent event,
    Emitter<UserPointsState> emit,
  ) async {
    final previousLevel = _points?.level;
    emit(UserPointsLoading(points: _points));

    ApiResponse<UserPointsResponse> response;
    try {
      response = await apiService.getMyPoints();
    } on DioException catch (_) {
      if (emit.isDone) return;
      emit(UserPointsError('Failed to load points', points: _points));
      return;
    }
    if (emit.isDone) return;

    if (response.success && response.data != null) {
      _points = response.data;
      emit(UserPointsLoaded(
        points: _points,
        previousLevel: previousLevel != null && previousLevel != _points!.level
            ? previousLevel
            : null,
      ));
    } else {
      emit(UserPointsError(
        response.error ?? 'Failed to load points',
        points: _points,
      ));
    }
  }
}
