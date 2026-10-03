// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_vibes_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnboardingVibesRequest _$OnboardingVibesRequestFromJson(
  Map<String, dynamic> json,
) => OnboardingVibesRequest(
  loves: (json['loves'] as List<dynamic>).map((e) => e as String).toList(),
  avoids: (json['avoids'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$OnboardingVibesRequestToJson(
  OnboardingVibesRequest instance,
) => <String, dynamic>{'loves': instance.loves, 'avoids': instance.avoids};
