part of 'venue_campaigns_bloc.dart';

@immutable
sealed class VenueCampaignsState {
  const VenueCampaignsState();
}

final class VenueCampaignsInitial extends VenueCampaignsState {
  const VenueCampaignsInitial();
}

final class VenueCampaignsLoading extends VenueCampaignsState {
  const VenueCampaignsLoading();
}

final class VenueCampaignsLoaded extends VenueCampaignsState {
  final List<CampaignResponse> items;
  const VenueCampaignsLoaded({required this.items});
}

final class VenueCampaignsError extends VenueCampaignsState {
  final String message;
  const VenueCampaignsError(this.message);
}
