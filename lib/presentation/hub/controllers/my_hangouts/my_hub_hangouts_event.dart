part of 'my_hub_hangouts_bloc.dart';

sealed class MyHubHangoutsEvent {
  const MyHubHangoutsEvent();
}

class LoadMyHubHangouts extends MyHubHangoutsEvent {
  const LoadMyHubHangouts();
}

class LoadMoreMyHubHangouts extends MyHubHangoutsEvent {
  const LoadMoreMyHubHangouts();
}
