const String tierUpgradeRequiredCode = 'TIER_UPGRADE_REQUIRED';

class TierUpgradeRequiredException implements Exception {
  final String feature;

  const TierUpgradeRequiredException(this.feature);

  @override
  String toString() => 'TierUpgradeRequiredException: $feature';
}

TierUpgradeRequiredException? tierUpgradeFromMessage(String? message) {
  if (message == null) return null;
  if (!message.startsWith(tierUpgradeRequiredCode)) return null;
  final colon = message.indexOf(': ', tierUpgradeRequiredCode.length);
  if (colon < 0) return TierUpgradeRequiredException('Pro feature');
  final body = message.substring(colon + 2);
  final featureColon = body.lastIndexOf(': ');
  final feature = featureColon >= 0 ? body.substring(featureColon + 2) : body;
  return TierUpgradeRequiredException(feature);
}
