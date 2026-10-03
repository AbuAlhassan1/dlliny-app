part of 'venues_bloc.dart';

sealed class VenuesEvent {}

class GetVenuesByBusinessId extends VenuesEvent {
  final String businessId;
  GetVenuesByBusinessId(this.businessId);
}
