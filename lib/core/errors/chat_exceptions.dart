sealed class ChatException implements Exception {
  final String message;
  const ChatException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class EditWindowExpiredException extends ChatException {
  const EditWindowExpiredException([
    super.message = 'Edit window has closed',
  ]);
}

class ChatForbiddenException extends ChatException {
  const ChatForbiddenException([super.message = 'Action not allowed']);
}

class ResourceMissingException extends ChatException {
  const ResourceMissingException([super.message = 'Resource not found']);
}

class ChatTransientException extends ChatException {
  const ChatTransientException([super.message = 'Temporary error']);
}

class ChatValidationException extends ChatException {
  const ChatValidationException(super.message);
}

class ChatUnexpectedException extends ChatException {
  const ChatUnexpectedException([super.message = 'Unexpected error']);
}
