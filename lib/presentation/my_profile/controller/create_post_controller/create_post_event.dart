part of 'create_post_bloc.dart';

sealed class CreatePostEvent {}

class UploadPostMedia extends CreatePostEvent {
  final String filePath;
  UploadPostMedia(this.filePath);
}
class AddNewPost extends CreatePostEvent {
  final CreatePostRequest body;
  final List<File>? files;
  final String? asVenueId;
  AddNewPost(this.body, [this.files, this.asVenueId]);
}

class SearchToMention extends CreatePostEvent {
  final String query;
  SearchToMention(this.query);
}