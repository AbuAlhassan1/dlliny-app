import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/request/create_review_request.dart';
import 'package:hangout/domain/dto/response/pending_venue_review_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

part 'awaiting_review_event.dart';
part 'awaiting_review_state.dart';

class AwaitingReviewBloc
    extends Bloc<AwaitingReviewEvent, AwaitingReviewState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final AppCacheRepository _cache = serviceLocator.get<AppCacheRepository>();

  AwaitingReviewBloc() : super(const AwaitingReviewInitial()) {
    on<LoadAwaitingReview>(_onLoad);
    on<SelectRating>(_onSelect);
    on<CancelRating>(_onCancel);
    on<ConfirmRating>(_onConfirm);
  }

  Future<void> _onLoad(
    LoadAwaitingReview event,
    Emitter<AwaitingReviewState> emit,
  ) async {
    final cached = await _readCache();
    if (cached != null) {
      emit(AwaitingReviewLoaded(cached, isRefreshing: true));
    } else {
      emit(const AwaitingReviewLoading());
    }
    try {
      final response = await _api.getAwaitingVenueReview();
      if (!response.success) {
        emit(cached != null
            ? AwaitingReviewLoaded(cached)
            : const AwaitingReviewEmpty());
        return;
      }
      final item = response.data;
      if (item == null) {
        await _cache.remove(HubCacheKeys.awaitingReview);
        emit(const AwaitingReviewEmpty());
      } else {
        await _cache.write(HubCacheKeys.awaitingReview, item.toJson());
        emit(AwaitingReviewLoaded(item));
      }
    } on DioException catch (_) {
      emit(cached != null
          ? AwaitingReviewLoaded(cached)
          : const AwaitingReviewEmpty());
    } catch (_) {
      emit(cached != null
          ? AwaitingReviewLoaded(cached)
          : const AwaitingReviewEmpty());
    }
  }

  Future<PendingVenueReviewResponse?> _readCache() async {
    final raw = await _cache.read(HubCacheKeys.awaitingReview);
    if (raw is! Map<String, dynamic>) return null;
    try {
      return PendingVenueReviewResponse.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  void _onSelect(SelectRating event, Emitter<AwaitingReviewState> emit) {
    final current = state;
    PendingVenueReviewResponse? item;
    if (current is AwaitingReviewLoaded) item = current.item;
    if (current is AwaitingReviewConfirming) item = current.item;
    if (item == null) return;
    final stars = event.stars.clamp(1, 5);
    emit(AwaitingReviewConfirming(item: item, selectedRating: stars));
  }

  void _onCancel(CancelRating event, Emitter<AwaitingReviewState> emit) {
    final current = state;
    if (current is AwaitingReviewConfirming) {
      emit(AwaitingReviewLoaded(current.item));
    }
  }

  Future<void> _onConfirm(
    ConfirmRating event,
    Emitter<AwaitingReviewState> emit,
  ) async {
    final current = state;
    if (current is! AwaitingReviewConfirming) return;
    final item = current.item;
    final rating = current.selectedRating;

    emit(AwaitingReviewSubmitting(item: item, selectedRating: rating));

    try {
      final response = await _api.createReview(
        CreateReviewRequest(
          venueId: item.venueId,
          hangoutId: item.hangoutId,
          ratingOverall: rating,
        ),
      );
      if (!response.success) {
        emit(AwaitingReviewSubmitError(
          item: item,
          message: response.error ?? LocaleKeys.home_awaiting_review_submit_failed.tr(),
        ));
        return;
      }
      await _cache.remove(HubCacheKeys.awaitingReview);
      add(LoadAwaitingReview());
    } on DioException catch (_) {
      emit(AwaitingReviewSubmitError(
        item: item,
        message: LocaleKeys.home_awaiting_review_submit_failed.tr(),
      ));
    } catch (_) {
      emit(AwaitingReviewSubmitError(
        item: item,
        message: LocaleKeys.home_awaiting_review_submit_failed.tr(),
      ));
    }
  }
}
