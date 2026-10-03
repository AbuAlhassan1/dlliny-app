import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';

bool userHasOnVenue(
  BuildContext context,
  String permission,
  String venueId,
) {
  final access = context.read<AccessBloc>().myAccess?.data;
  if (access == null) return false;
  final venue = _findVenue(access, venueId);
  if (venue == null) return false;
  return venue.effectivePermissions.contains(permission);
}

VenueAccess? _findVenue(UserAccessResponse access, String venueId) {
  for (final biz in access.businesses) {
    for (final v in biz.venues) {
      if (v.venueId == venueId) return v;
    }
  }
  for (final v in access.orphanVenues) {
    if (v.venueId == venueId) return v;
  }
  return null;
}

abstract class VenuePerm {
  static const update = 'venue:update';
  static const mediaUpload = 'venue:media:upload';
  static const mediaDelete = 'venue:media:delete';
  static const verifySubmit = 'venue:verify:submit';
  static const reviewsReply = 'venue:reviews:reply';
  static const staffManage = 'venue:staff:manage';
  static const campaignsCreate = 'venue:campaigns:create';
  static const campaignsRead = 'venue:campaigns:read';
  static const servicesManage = 'venue:services:manage';
  static const announcementsManage = 'venue:announcements:manage';
  static const menuManage = 'venue:menu:manage';

  static const hoursManage = 'venue:hours:manage';
}
