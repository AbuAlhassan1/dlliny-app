sealed class MemoryException implements Exception {
  final String message;
  const MemoryException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class MemoryExpiredException extends MemoryException {
  const MemoryExpiredException([
    super.message = 'Memory not found or expired',
  ]);
}

class MemoryForbiddenException extends MemoryException {
  const MemoryForbiddenException([super.message = 'Action not allowed']);
}

class EngagementInvalidException extends MemoryException {
  const EngagementInvalidException(super.message);
}

class MemoryValidationException extends MemoryException {
  const MemoryValidationException(super.message);
}

class MemoryTransientException extends MemoryException {
  const MemoryTransientException([super.message = 'Temporary error']);
}

class MemoryUnexpectedException extends MemoryException {
  const MemoryUnexpectedException([super.message = 'Unexpected error']);
}
