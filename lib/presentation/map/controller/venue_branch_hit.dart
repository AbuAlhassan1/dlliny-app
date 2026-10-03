class VenueBranchHit {
  final String venueId;
  final String venueNameAr;
  final String venueNameEn;
  final String? venueLogoUrl;
  final bool venueVerified;

  final String? locationId;

  final String? labelAr;
  final String? labelEn;

  final String? cityNameAr;
  final String? districtNameAr;

  final double latitude;
  final double longitude;

  final bool isPrimary;

  const VenueBranchHit({
    required this.venueId,
    required this.venueNameAr,
    required this.venueNameEn,
    required this.venueVerified,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
    this.venueLogoUrl,
    this.locationId,
    this.labelAr,
    this.labelEn,
    this.cityNameAr,
    this.districtNameAr,
  });
}
