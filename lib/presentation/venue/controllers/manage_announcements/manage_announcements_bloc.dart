import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_announcement_request.dart';
import 'package:hangout/domain/dto/request/update_announcement_request.dart';
import 'package:hangout/domain/dto/response/announcement_management_response.dart';

part 'manage_announcements_event.dart';
part 'manage_announcements_state.dart';

class ManageAnnouncementsBloc
    extends Bloc<ManageAnnouncementsEvent, ManageAnnouncementsState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  final List<AnnouncementResponse> _items = [];
  int _nextPage = 0;
  bool _exhausted = false;

  static const int _pageSize = 20;

  ManageAnnouncementsBloc({required this.venueId})
      : super(const ManageAnnouncementsInitial()) {
    on<LoadAnnouncements>(_onLoad);
    on<LoadMoreAnnouncements>(_onLoadMore);
    on<CreateAnnouncementSubmitted>(_onCreate);
    on<UpdateAnnouncementSubmitted>(_onUpdate);
    on<DeleteAnnouncementRequested>(_onDelete);
  }

  Future<void> _onLoad(
    LoadAnnouncements event,
    Emitter<ManageAnnouncementsState> emit,
  ) async {
    _items.clear();
    _nextPage = 0;
    _exhausted = false;
    emit(const ManageAnnouncementsLoading());
    await _fetchPage(emit);
  }

  Future<void> _onLoadMore(
    LoadMoreAnnouncements event,
    Emitter<ManageAnnouncementsState> emit,
  ) async {
    if (_exhausted) return;
    await _fetchPage(emit);
  }

  Future<void> _fetchPage(Emitter<ManageAnnouncementsState> emit) async {
    try {
      final res = await _api.listMyVenueAnnouncements(
        venueId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!res.success || res.data == null) {
        emit(ManageAnnouncementsError(res.error ?? 'تعذر تحميل الإعلانات'));
        return;
      }
      final page = res.data!;
      _items.addAll(page.content);
      _nextPage = page.page + 1;
      _exhausted = page.last;
      emit(ManageAnnouncementsLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
      ));
    } on DioException catch (e) {
      emit(ManageAnnouncementsError(_msg(e, 'تعذر تحميل الإعلانات')));
    }
  }

  Future<void> _onCreate(
    CreateAnnouncementSubmitted event,
    Emitter<ManageAnnouncementsState> emit,
  ) async {
    emit(ManageAnnouncementsMutating(List.unmodifiable(_items)));
    try {
      final res = await _api.createAnnouncement(venueId, event.body);
      if (!res.success || res.data == null) {
        emit(ManageAnnouncementsActionFailed(
          List.unmodifiable(_items),
          res.error ?? 'تعذر إنشاء الإعلان',
        ));
        return;
      }
      _items.insert(0, res.data!);
      emit(ManageAnnouncementsActionSucceeded(
        List.unmodifiable(_items),
        'تم نشر الإعلان',
      ));
      emit(ManageAnnouncementsLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
      ));
    } on DioException catch (e) {
      emit(ManageAnnouncementsActionFailed(
        List.unmodifiable(_items),
        _msg(e, 'تعذر إنشاء الإعلان'),
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateAnnouncementSubmitted event,
    Emitter<ManageAnnouncementsState> emit,
  ) async {
    emit(ManageAnnouncementsMutating(List.unmodifiable(_items)));
    try {
      final res = await _api.updateAnnouncement(
        venueId,
        event.announcementId,
        event.body,
      );
      if (!res.success || res.data == null) {
        emit(ManageAnnouncementsActionFailed(
          List.unmodifiable(_items),
          res.error ?? 'تعذر حفظ التعديلات',
        ));
        return;
      }
      final idx = _items.indexWhere((a) => a.id == event.announcementId);
      if (idx >= 0) {
        _items[idx] = res.data!;
      }
      emit(ManageAnnouncementsActionSucceeded(
        List.unmodifiable(_items),
        event.successMessage ?? 'تم حفظ التعديلات',
      ));
      emit(ManageAnnouncementsLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
      ));
    } on DioException catch (e) {
      emit(ManageAnnouncementsActionFailed(
        List.unmodifiable(_items),
        _msg(e, 'تعذر حفظ التعديلات'),
      ));
    }
  }

  Future<void> _onDelete(
    DeleteAnnouncementRequested event,
    Emitter<ManageAnnouncementsState> emit,
  ) async {
    emit(ManageAnnouncementsMutating(List.unmodifiable(_items)));
    try {
      final res = await _api.deleteAnnouncement(venueId, event.announcementId);
      if (!res.success) {
        emit(ManageAnnouncementsActionFailed(
          List.unmodifiable(_items),
          res.error ?? 'تعذر حذف الإعلان',
        ));
        return;
      }
      _items.removeWhere((a) => a.id == event.announcementId);
      emit(ManageAnnouncementsActionSucceeded(
        List.unmodifiable(_items),
        'تم حذف الإعلان',
      ));
      emit(ManageAnnouncementsLoaded(
        items: List.unmodifiable(_items),
        hasMore: !_exhausted,
      ));
    } on DioException catch (e) {
      emit(ManageAnnouncementsActionFailed(
        List.unmodifiable(_items),
        _msg(e, 'تعذر حذف الإعلان'),
      ));
    }
  }

  String _msg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
