part of 'manage_announcements_bloc.dart';

sealed class ManageAnnouncementsEvent {
  const ManageAnnouncementsEvent();
}

class LoadAnnouncements extends ManageAnnouncementsEvent {
  const LoadAnnouncements();
}

class LoadMoreAnnouncements extends ManageAnnouncementsEvent {
  const LoadMoreAnnouncements();
}

class CreateAnnouncementSubmitted extends ManageAnnouncementsEvent {
  final CreateAnnouncementRequest body;
  const CreateAnnouncementSubmitted(this.body);
}

class UpdateAnnouncementSubmitted extends ManageAnnouncementsEvent {
  final String announcementId;
  final UpdateAnnouncementRequest body;

  final String? successMessage;
  const UpdateAnnouncementSubmitted({
    required this.announcementId,
    required this.body,
    this.successMessage,
  });
}

class DeleteAnnouncementRequested extends ManageAnnouncementsEvent {
  final String announcementId;
  const DeleteAnnouncementRequested(this.announcementId);
}
