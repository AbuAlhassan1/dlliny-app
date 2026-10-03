final _kHandleAllowedChars = RegExp(r'^[a-z0-9_.]+$');
final _kHandleStartsAlnum = RegExp(r'^[a-z0-9]');
final _kHandleEndsAlnum = RegExp(r'[a-z0-9]$');
final _kHandleNoAdjacentSeparators = RegExp(r'[._]{2}');

String? validateVenueHandle(
  String? raw, {
  bool required = false,
  String? currentHandle,
}) {
  final v = (raw ?? '').trim().toLowerCase();
  if (v.isEmpty) {
    return required ? 'مطلوب' : null;
  }
  if (v.length < 3) return 'لا تقل عن 3 خانات';
  if (v.length > 30) return 'لا تزيد عن 30 خانة';
  if (!_kHandleAllowedChars.hasMatch(v)) {
    return 'حروف إنجليزية صغيرة أو أرقام أو _ أو . فقط';
  }
  if (!_kHandleStartsAlnum.hasMatch(v)) {
    return 'يجب أن يبدأ بحرف أو رقم';
  }
  if (!_kHandleEndsAlnum.hasMatch(v)) {
    return 'يجب أن ينتهي بحرف أو رقم';
  }
  if (_kHandleNoAdjacentSeparators.hasMatch(v)) {
    return 'لا يجوز تكرار _ أو . متجاورتين';
  }
  if (currentHandle != null && v == currentHandle.toLowerCase()) {
    return 'هذا المعرّف الحالي — اختر معرّفاً مختلفاً';
  }
  return null;
}
