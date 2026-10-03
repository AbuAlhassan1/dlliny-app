import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';

sealed class ShareTarget {
  String get stableKey;

  String get title;

  String? get subtitle;

  String? get avatarUrl;

  bool get isGroup;
}

class ConversationTarget extends ShareTarget {
  final ConversationResponse conversation;

  final String? peerUserId;
  final String? peerVenueId;

  ConversationTarget({
    required this.conversation,
    required this.peerUserId,
    required this.peerVenueId,
  });

  @override
  String get stableKey => 'conv:${conversation.id}';

  @override
  String get title {
    final c = conversation;
    if (c.type == ConversationType.group) {
      return c.title?.trim().isNotEmpty == true ? c.title! : 'Group';
    }
    return _peerDisplayName ?? 'Conversation';
  }

  String? get _peerDisplayName {
    for (final m in conversation.members) {
      if (m.memberId == peerUserId || m.memberId == peerVenueId) {
        return m.displayName;
      }
    }
    return conversation.members.isNotEmpty
        ? conversation.members.first.displayName
        : null;
  }

  @override
  String? get subtitle => null;

  @override
  String? get avatarUrl {
    if (conversation.type == ConversationType.group) return conversation.avatarUrl;
    for (final m in conversation.members) {
      if (m.memberId == peerUserId || m.memberId == peerVenueId) {
        return m.avatarUrl;
      }
    }
    return conversation.members.isNotEmpty
        ? conversation.members.first.avatarUrl
        : null;
  }

  @override
  bool get isGroup => conversation.type == ConversationType.group;
}

class UserTarget extends ShareTarget {
  final String id;
  final String? displayName;
  final String? username;
  @override
  final String? avatarUrl;
  final bool verified;

  UserTarget({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.verified,
  });

  factory UserTarget.fromSummary(UserSummaryResponse u) => UserTarget(
        id: u.id,
        displayName: u.displayName,
        username: u.username,
        avatarUrl: u.avatarUrl,
        verified: u.verified,
      );

  factory UserTarget.fromSearch(UserSearchResultDto u) => UserTarget(
        id: u.id,
        displayName: u.displayName,
        username: u.username,
        avatarUrl: u.avatarUrl,
        verified: u.verified,
      );

  @override
  String get stableKey => 'user:$id';

  @override
  String get title =>
      (displayName?.trim().isNotEmpty == true ? displayName! : (username ?? ''));

  @override
  String? get subtitle {
    final u = username;
    if (u == null || u.isEmpty) return null;
    return '@$u';
  }

  @override
  bool get isGroup => false;

  ChatMemberType get memberType => ChatMemberType.user;
}

class VenueTarget extends ShareTarget {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? districtNameAr;
  final String? cityNameAr;
  @override
  final String? avatarUrl;
  final bool verified;

  VenueTarget({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.districtNameAr,
    required this.cityNameAr,
    required this.avatarUrl,
    required this.verified,
  });

  factory VenueTarget.fromSummary(VenueSummaryResponse v) => VenueTarget(
        id: v.id,
        nameAr: v.nameAr,
        nameEn: v.nameEn,
        districtNameAr: v.districtNameAr,
        cityNameAr: v.cityNameAr,
        avatarUrl: v.logoUrl,
        verified: v.verified,
      );

  factory VenueTarget.fromSearch(VenueSearchResultDto v) => VenueTarget(
        id: v.id,
        nameAr: v.nameAr,
        nameEn: v.nameEn,
        districtNameAr: v.district,
        cityNameAr: null,
        avatarUrl: null,
        verified: v.verified,
      );

  @override
  String get stableKey => 'venue:$id';

  @override
  String get title => nameAr;

  @override
  String? get subtitle {
    if (districtNameAr != null && cityNameAr != null) {
      return '$districtNameAr، $cityNameAr';
    }
    return districtNameAr ?? cityNameAr;
  }

  @override
  bool get isGroup => false;

  ChatMemberType get memberType => ChatMemberType.venue;
}
