part of 'venue_campaigns_bloc.dart';

@immutable
sealed class VenueCampaignsEvent {
  const VenueCampaignsEvent();
}

class LoadVenueCampaigns extends VenueCampaignsEvent {
  const LoadVenueCampaigns();
}
