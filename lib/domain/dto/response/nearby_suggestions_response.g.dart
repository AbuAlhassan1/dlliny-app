// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_suggestions_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearbySuggestionsResponse _$NearbySuggestionsResponseFromJson(
  Map<String, dynamic> json,
) => NearbySuggestionsResponse(
  discoverable: json['discoverable'] as bool,
  suggestions:
      (json['suggestions'] as List<dynamic>?)
          ?.map(
            (e) => NearbySuggestionResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$NearbySuggestionsResponseToJson(
  NearbySuggestionsResponse instance,
) => <String, dynamic>{
  'discoverable': instance.discoverable,
  'suggestions': instance.suggestions.map((e) => e.toJson()).toList(),
};
