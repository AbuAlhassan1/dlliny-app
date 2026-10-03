import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/presentation/chat/models/message_display_item.dart';

String messageSnippet(MessageDisplayItem item) {
  if (item.message.deletedForEveryone) return 'Message unsent';
  switch (item.message.contentType) {
    case MessageContentType.text:
      final t = (item.message.content ?? '').trim();
      return t.length > 80 ? '${t.substring(0, 80)}…' : t;
    case MessageContentType.voice:
      return '🎤 Voice message';
    case MessageContentType.share:
      return 'Shared content';
  }
}
