import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

part 'hangout_details_event.dart';
part 'hangout_details_state.dart';

class HangoutDetailsBloc
    extends Bloc<HangoutDetailsEvent, HangoutDetailsState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  HangoutDetailsBloc() : super(HangoutDetailsInitial()) {
    on<LoadHangoutDetails>(_onLoad);
  }

  Future<void> _onLoad(
    LoadHangoutDetails event,
    Emitter<HangoutDetailsState> emit,
  ) async {
    emit(HangoutDetailsLoading());

    late ApiResponse<HangoutResponse> hangoutRes;
    try {
      hangoutRes = await _api.getHangout(event.hangoutId);
    } on DioException catch (e) {
      emit(HangoutDetailsError(e.message ?? LocaleKeys.hangout_load_failed.tr()));
      return;
    } catch (e, st) {
      log('LoadHangoutDetails(${event.hangoutId}) failed: $e', stackTrace: st);
      emit(HangoutDetailsError(LocaleKeys.hangout_load_failed.tr()));
      return;
    }

    if (!hangoutRes.success || hangoutRes.data == null) {
      emit(HangoutDetailsError(hangoutRes.error ?? LocaleKeys.hangout_load_failed.tr()));
      return;
    }
    final hangout = hangoutRes.data!;

    final mediaFuture = _loadMedia(event.hangoutId);
    final venueFuture = _loadVenue(hangout.venueId);
    final media = await mediaFuture;
    final venue = await venueFuture;

    emit(HangoutDetailsLoaded(hangout: hangout, media: media, venue: venue));
  }

  Future<List<HangoutMediaResponse>> _loadMedia(String hangoutId) async {
    try {
      final res = await _api.getHangoutMedia(hangoutId);
      return res.success && res.data != null ? res.data! : const [];
    } on DioException catch (_) {
      return const [];
    } catch (e, st) {
      log('getHangoutMedia($hangoutId) failed: $e', stackTrace: st);
      return const [];
    }
  }

  Future<VenueResponse?> _loadVenue(String venueId) async {
    try {
      final res = await _api.getVenue(venueId);
      return res.success ? res.data : null;
    } on DioException catch (_) {
      return null;
    } catch (e, st) {
      log('getVenue($venueId) failed: $e', stackTrace: st);
      return null;
    }
  }
}
