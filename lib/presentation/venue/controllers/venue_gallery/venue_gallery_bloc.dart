import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/utils/gallery_filters.dart';

part 'venue_gallery_event.dart';
part 'venue_gallery_state.dart';

class VenueGalleryBloc extends Bloc<VenueGalleryEvent, VenueGalleryState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  VenueGalleryBloc({
    required this.venueId,
    List<GalleryPhotoDto> seed = const [],
    String? tag,
    String? locationId,
  }) : super(
         VenueGalleryState(
           status: seed.isEmpty
               ? VenueGalleryStatus.loading
               : VenueGalleryStatus.ready,
           photos: seed,
           tag: tag,
           locationId: locationId,
         ),
       ) {
    on<VenueGalleryRequested>(_onRequested);
    on<VenueGalleryTagSelected>(
      (event, emit) => emit(state.copyWith(tag: () => event.tag)),
    );
    on<VenueGalleryBranchSelected>(_onBranchSelected);
  }

  Future<void> _onRequested(
    VenueGalleryRequested event,
    Emitter<VenueGalleryState> emit,
  ) async {
    if (state.photos.isEmpty) {
      emit(state.copyWith(status: VenueGalleryStatus.loading));
    }
    try {
      final res = await _api.listVenueGallery(venueId);
      final photos = res.data;
      if (!res.success || photos == null) {
        _fail(emit);
        return;
      }
      emit(state.copyWith(status: VenueGalleryStatus.ready, photos: photos));
    } catch (error, stackTrace) {
      log('listVenueGallery($venueId) failed: $error', stackTrace: stackTrace);
      _fail(emit);
    }
  }

  void _fail(Emitter<VenueGalleryState> emit) {
    emit(
      state.copyWith(
        status: state.photos.isEmpty
            ? VenueGalleryStatus.error
            : VenueGalleryStatus.ready,
      ),
    );
  }

  void _onBranchSelected(
    VenueGalleryBranchSelected event,
    Emitter<VenueGalleryState> emit,
  ) {
    final tag = state.tag;
    final keepTag =
        tag != null &&
        (countKnownTags(photosForBranch(state.photos, event.locationId))[tag] ??
                0) >
            0;
    emit(
      state.copyWith(
        locationId: () => event.locationId,
        tag: () => keepTag ? tag : null,
      ),
    );
  }
}
