import 'package:json_annotation/json_annotation.dart';

import 'nearby_suggestion_response.dart';

part 'nearby_suggestions_response.g.dart';

@JsonSerializable(explicitToJson: true)
class NearbySuggestionsResponse {
  final bool discoverable;

  @JsonKey(defaultValue: <NearbySuggestionResponse>[])
  final List<NearbySuggestionResponse> suggestions;

  const NearbySuggestionsResponse({
    required this.discoverable,
    this.suggestions = const [],
  });

  factory NearbySuggestionsResponse.fromJson(Map<String, dynamic> json) =>
      _$NearbySuggestionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NearbySuggestionsResponseToJson(this);
}
