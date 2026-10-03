part of 'manage_services_bloc.dart';

sealed class ManageServicesState {
  const ManageServicesState();
}

final class ManageServicesInitial extends ManageServicesState {
  const ManageServicesInitial();
}

final class ManageServicesLoading extends ManageServicesState {
  const ManageServicesLoading();
}

final class ManageServicesError extends ManageServicesState {
  final String message;
  const ManageServicesError(this.message);
}

final class ManageServicesLoaded extends ManageServicesState {
  final List<VenueServiceResponse> services;
  const ManageServicesLoaded(this.services);
}

final class ManageServicesMutating extends ManageServicesState {
  final List<VenueServiceResponse> services;
  const ManageServicesMutating(this.services);
}

final class ManageServicesActionSucceeded extends ManageServicesState {
  final List<VenueServiceResponse> services;
  final String message;
  const ManageServicesActionSucceeded(this.services, this.message);
}

final class ManageServicesActionFailed extends ManageServicesState {
  final List<VenueServiceResponse> services;
  final String message;
  const ManageServicesActionFailed(this.services, this.message);
}
