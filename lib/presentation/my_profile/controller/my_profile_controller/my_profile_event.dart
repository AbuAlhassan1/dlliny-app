part of 'my_profile_bloc.dart';

sealed class MyProfileEvent {}
class GetMyProfile extends MyProfileEvent {}
class EditAvatar extends MyProfileEvent {
  final File file;
  EditAvatar(this.file);
}
class CompleteMyProfile extends MyProfileEvent {
  final String displayName;

  final String? username;
  final String? bio;
  final String? city;
  final String? district;
  final String? gender;

  final int? cityId;
  final int? districtId;

  CompleteMyProfile({
    required this.displayName,
    this.username,
    this.bio,
    this.city,
    this.district,
    this.gender,
    this.cityId,
    this.districtId,
  });
}

class UpdateAccountType extends MyProfileEvent {
  final bool isPrivate;
  UpdateAccountType(this.isPrivate);
}

class UpdateMyProfile extends MyProfileEvent {
  final String displayName;
  final String? bio;
  final String? city;
  final String? district;
  final int? cityId;
  final int? districtId;

  UpdateMyProfile({
    required this.displayName,
    this.bio,
    this.city,
    this.district,
    this.cityId,
    this.districtId,
  });
}
