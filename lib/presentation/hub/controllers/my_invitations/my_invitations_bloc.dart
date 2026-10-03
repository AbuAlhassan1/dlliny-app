import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/respond_invitation_request.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';

sealed class MyInvitationsEvent {}

class LoadMyInvitations extends MyInvitationsEvent {}

class RespondMyInvitation extends MyInvitationsEvent {
  final String invitationId;
  final bool accept;
  RespondMyInvitation(this.invitationId, {required this.accept});
}

sealed class MyInvitationsState {}

class MyInvitationsInitial extends MyInvitationsState {}

class MyInvitationsLoading extends MyInvitationsState {}

class MyInvitationsError extends MyInvitationsState {}

class MyInvitationsLoaded extends MyInvitationsState {
  final List<InvitationResponse> items;

  final Set<String> responding;

  MyInvitationsLoaded({required this.items, required this.responding});
}

class MyInvitationsBloc extends Bloc<MyInvitationsEvent, MyInvitationsState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  List<InvitationResponse> _items = const [];
  final Set<String> _responding = {};

  MyInvitationsBloc() : super(MyInvitationsInitial()) {
    on<LoadMyInvitations>(_onLoad);
    on<RespondMyInvitation>(_onRespond);
  }

  MyInvitationsLoaded get _snapshot => MyInvitationsLoaded(
        items: List.unmodifiable(_items),
        responding: Set.unmodifiable(_responding),
      );

  Future<void> _onLoad(
    LoadMyInvitations event,
    Emitter<MyInvitationsState> emit,
  ) async {
    if (_items.isEmpty) emit(MyInvitationsLoading());
    try {
      final res = await _api.getMyInvitations();
      if (!res.success || res.data == null) {
        if (_items.isEmpty) emit(MyInvitationsError());
        return;
      }
      _items = res.data!
          .where((i) => i.status.toLowerCase() == 'pending')
          .toList()
        ..sort((a, b) => a.hangoutScheduledAt.compareTo(b.hangoutScheduledAt));
      emit(_snapshot);
    } catch (_) {
      if (_items.isEmpty) emit(MyInvitationsError());
    }
  }

  Future<void> _onRespond(
    RespondMyInvitation event,
    Emitter<MyInvitationsState> emit,
  ) async {
    final id = event.invitationId;
    if (_responding.contains(id)) return;
    _responding.add(id);
    emit(_snapshot);

    try {
      final res = await _api.respondToInvitation(
        id,
        RespondInvitationRequest(status: event.accept ? 'accepted' : 'rejected'),
      );
      if (res.success) {
        _items = _items.where((i) => i.id != id).toList();
      }
    } catch (_) {
    }

    _responding.remove(id);
    emit(_snapshot);
  }
}
