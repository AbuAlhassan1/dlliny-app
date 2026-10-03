import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/public_event_response.dart';

sealed class PublicEventsEvent {}

class LoadPublicEvents extends PublicEventsEvent {}

class ToggleEventInterest extends PublicEventsEvent {
  final String eventId;
  ToggleEventInterest(this.eventId);
}

sealed class PublicEventsState {}

class PublicEventsInitial extends PublicEventsState {}

class PublicEventsLoading extends PublicEventsState {}

class PublicEventsError extends PublicEventsState {}

class PublicEventsLoaded extends PublicEventsState {
  final List<PublicEventResponse> events;
  PublicEventsLoaded(this.events);
}

class PublicEventsBloc extends Bloc<PublicEventsEvent, PublicEventsState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  List<PublicEventResponse> _events = const [];

  PublicEventsBloc() : super(PublicEventsInitial()) {
    on<LoadPublicEvents>(_onLoad);
    on<ToggleEventInterest>(_onToggle);
  }

  Future<void> _onLoad(
    LoadPublicEvents event,
    Emitter<PublicEventsState> emit,
  ) async {
    if (_events.isEmpty) emit(PublicEventsLoading());
    try {
      final res = await _api.listPublicEvents(status: 'UPCOMING', page: 0, size: 12);
      if (!res.success || res.data == null) {
        if (_events.isEmpty) emit(PublicEventsError());
        return;
      }
      _events = res.data!.content;
      emit(PublicEventsLoaded(List.unmodifiable(_events)));
    } catch (_) {
      if (_events.isEmpty) emit(PublicEventsError());
    }
  }

  Future<void> _onToggle(
    ToggleEventInterest event,
    Emitter<PublicEventsState> emit,
  ) async {
    final index = _events.indexWhere((e) => e.id == event.eventId);
    if (index < 0) return;
    final original = _events[index];
    final nowInterested = !original.interestedByMe;

    _events = List.of(_events)
      ..[index] = original.copyWithInterest(
        interestedByMe: nowInterested,
        interestedCount:
            (original.interestedCount + (nowInterested ? 1 : -1)).clamp(0, 1 << 31),
      );
    emit(PublicEventsLoaded(List.unmodifiable(_events)));

    try {
      final res = nowInterested
          ? await _api.markEventInterested(event.eventId)
          : await _api.unmarkEventInterested(event.eventId);
      if (res.success && res.data != null) {
        final i = _events.indexWhere((e) => e.id == event.eventId);
        if (i >= 0) {
          _events = List.of(_events)..[i] = res.data!;
          emit(PublicEventsLoaded(List.unmodifiable(_events)));
        }
      }
    } catch (_) {
      final i = _events.indexWhere((e) => e.id == event.eventId);
      if (i >= 0) {
        _events = List.of(_events)..[i] = original;
        emit(PublicEventsLoaded(List.unmodifiable(_events)));
      }
    }
  }
}
