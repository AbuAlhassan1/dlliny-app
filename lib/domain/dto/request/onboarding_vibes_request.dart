import 'package:json_annotation/json_annotation.dart';

part 'onboarding_vibes_request.g.dart';

@JsonSerializable()
class OnboardingVibesRequest {
  final List<String> loves;

  final List<String> avoids;

  const OnboardingVibesRequest({
    required this.loves,
    required this.avoids,
  });

  factory OnboardingVibesRequest.fromJson(Map<String, dynamic> json) =>
      _$OnboardingVibesRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OnboardingVibesRequestToJson(this);
}
