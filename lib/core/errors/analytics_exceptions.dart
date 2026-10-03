sealed class AnalyticsException implements Exception {
  final String message;
  const AnalyticsException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class AnalyticsValidationException extends AnalyticsException {
  const AnalyticsValidationException(super.message);
}

class AnalyticsForbiddenException extends AnalyticsException {
  const AnalyticsForbiddenException(super.message);
}

class AnalyticsNotFoundException extends AnalyticsException {
  const AnalyticsNotFoundException(super.message);
}

class AnalyticsTransientException extends AnalyticsException {
  const AnalyticsTransientException(super.message);
}

class AnalyticsUnexpectedException extends AnalyticsException {
  const AnalyticsUnexpectedException(super.message);
}
