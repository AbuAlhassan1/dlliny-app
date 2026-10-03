import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

part 'venue_campaigns_event.dart';
part 'venue_campaigns_state.dart';

class VenueCampaignsBloc
    extends Bloc<VenueCampaignsEvent, VenueCampaignsState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  VenueCampaignsBloc({required this.venueId})
      : super(const VenueCampaignsInitial()) {
    on<LoadVenueCampaigns>(_onLoad);
  }

  Future<void> _onLoad(
    LoadVenueCampaigns event,
    Emitter<VenueCampaignsState> emit,
  ) async {
    emit(const VenueCampaignsLoading());
    try {
      final res = await _api.getMyCampaigns();
      if (!res.success || res.data == null) {
        emit(VenueCampaignsError(
          res.error ?? LocaleKeys.business_campaigns_load_error_fetch.tr(),
        ));
        return;
      }
      final mine =
          res.data!.where((c) => c.venueId == venueId).toList(growable: false);
      emit(VenueCampaignsLoaded(items: mine));
    } on DioException catch (e) {
      emit(VenueCampaignsError(
        e.message ?? LocaleKeys.common_connection_failed.tr(),
      ));
    }
  }
}
