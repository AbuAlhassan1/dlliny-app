part of 'intents_bloc.dart';

sealed class HubIntentsEvent {}

class LoadIntents extends HubIntentsEvent {}

class SelectHubIntent extends HubIntentsEvent {
  final String code;
  SelectHubIntent(this.code);
}
