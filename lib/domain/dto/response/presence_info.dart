import 'package:json_annotation/json_annotation.dart';

part 'presence_info.g.dart';

@JsonSerializable()
class PresenceInfo {
  final bool online;
  final String? lastSeenAt;

  const PresenceInfo({required this.online, this.lastSeenAt});

  factory PresenceInfo.fromJson(Map<String, dynamic> json) =>
      _$PresenceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PresenceInfoToJson(this);
}

class PresenceMapResponse {
  final Map<String, PresenceInfo> presences;

  const PresenceMapResponse(this.presences);

  factory PresenceMapResponse.fromJson(Map<String, dynamic> json) {
    return PresenceMapResponse(
      json.map(
        (k, v) =>
            MapEntry(k, PresenceInfo.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toJson() =>
      presences.map((k, v) => MapEntry(k, v.toJson()));
}
