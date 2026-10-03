class IncomingNotification {
  final String? title;

  final String? body;

  final Map<String, String> data;

  const IncomingNotification({
    this.title,
    this.body,
    required this.data,
  });

  String? get titleAr => data['titleAr'];
  String? get titleEn => data['titleEn'];
  String? get bodyAr => data['bodyAr'];
  String? get bodyEn => data['bodyEn'];

  String? get deepLink => data['deepLink'];

  String? get actorAvatarUrl => data['actorAvatarUrl'];
  String? get actorUsername => data['actorUsername'];
  String? get type => data['type'];
  String? get entityId => data['entityId'];
  String? get entityType => data['entityType'];

  String? localizedTitle({required bool isAr}) {
    if (isAr) return titleAr ?? title;
    return titleEn ?? title;
  }

  String? localizedBody({required bool isAr}) {
    if (isAr) return bodyAr ?? body;
    return bodyEn ?? body;
  }
}
