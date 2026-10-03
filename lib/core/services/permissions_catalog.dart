import 'package:hangout/domain/dto/response/permission_catalog_entry.dart';

class PermissionsCatalog {
  PermissionsCatalog._();

  static Set<String> _knownCodes = const {};
  static Map<String, PermissionCatalogEntry> _entriesByCode = const {};
  static bool _hydrated = false;

  static void hydrate(List<PermissionCatalogEntry> entries) {
    _entriesByCode = {for (final e in entries) e.code: e};
    _knownCodes = _entriesByCode.keys.toSet();
    _hydrated = true;
  }

  static bool get isHydrated => _hydrated;

  static bool isKnown(String code) =>
      !_hydrated || _knownCodes.contains(code);

  static String validated(String code) {
    assert(
      isKnown(code),
      'Unknown permission code: "$code". '
      'Check spelling or hydrate PermissionsCatalog before this call. '
      'Known codes: $_knownCodes',
    );
    return code;
  }

  static String labelFor(String code, {required bool arabic}) {
    final entry = _entriesByCode[code];
    if (entry == null) return code;
    return entry.labelFor(arabic: arabic);
  }

  static String descriptionFor(String code, {required bool arabic}) {
    final entry = _entriesByCode[code];
    if (entry == null) return code;
    return entry.descriptionFor(arabic: arabic);
  }

  static PermissionCatalogEntry? entryFor(String code) =>
      _entriesByCode[code];

  static void resetForTests() {
    _knownCodes = const {};
    _entriesByCode = const {};
    _hydrated = false;
  }
}
