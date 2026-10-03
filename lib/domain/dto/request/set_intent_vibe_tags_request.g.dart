// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_intent_vibe_tags_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetIntentVibeTagsRequest _$SetIntentVibeTagsRequestFromJson(
  Map<String, dynamic> json,
) => SetIntentVibeTagsRequest(
  vibeTagCodes: (json['vibeTagCodes'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$SetIntentVibeTagsRequestToJson(
  SetIntentVibeTagsRequest instance,
) => <String, dynamic>{'vibeTagCodes': instance.vibeTagCodes};
