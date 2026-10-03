// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresenceInfo _$PresenceInfoFromJson(Map<String, dynamic> json) => PresenceInfo(
  online: json['online'] as bool,
  lastSeenAt: json['lastSeenAt'] as String?,
);

Map<String, dynamic> _$PresenceInfoToJson(PresenceInfo instance) =>
    <String, dynamic>{
      'online': instance.online,
      'lastSeenAt': instance.lastSeenAt,
    };
