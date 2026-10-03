part of 'manage_services_bloc.dart';

sealed class ManageServicesEvent {
  const ManageServicesEvent();
}

class LoadMyServices extends ManageServicesEvent {
  const LoadMyServices();
}

class AddServiceSubmitted extends ManageServicesEvent {
  final int serviceTypeId;
  final double? price;
  final File? image;
  const AddServiceSubmitted({
    required this.serviceTypeId,
    this.price,
    this.image,
  });
}

class UpdateServiceSubmitted extends ManageServicesEvent {
  final String serviceId;
  final double? price;
  final bool? active;
  final File? image;
  final bool keepExistingImage;
  final bool clearImage;
  const UpdateServiceSubmitted({
    required this.serviceId,
    this.price,
    this.active,
    this.image,
    this.keepExistingImage = true,
    this.clearImage = false,
  });
}

class DeleteServiceRequested extends ManageServicesEvent {
  final String serviceId;
  const DeleteServiceRequested(this.serviceId);
}

class ToggleServiceActiveRequested extends ManageServicesEvent {
  final String serviceId;
  final bool nextActive;
  const ToggleServiceActiveRequested({
    required this.serviceId,
    required this.nextActive,
  });
}
