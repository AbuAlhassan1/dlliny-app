import 'package:json_annotation/json_annotation.dart';

part 'react_to_memory_request.g.dart';

@JsonSerializable()
class ReactToMemoryRequest {
  final String emoji;

  const ReactToMemoryRequest({required this.emoji});

  factory ReactToMemoryRequest.fromJson(Map<String, dynamic> json) =>
      _$ReactToMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReactToMemoryRequestToJson(this);
}
