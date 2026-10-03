import 'package:flutter/material.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/domain/dto/request/create_conversation_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/presentation/chat/screens/conversation_page_wrapper.dart';

Future<void> openDirectConversation(
  BuildContext context, {
  required ChatMemberType peerType,
  required String peerId,
}) async {
  final repo = serviceLocator.get<ChatRepository>();
  final navigator = Navigator.of(context);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      ),
    ),
  );

  try {
    final conversation = await repo.createConversation(
      CreateConversationRequest(
        type: ConversationType.direct,
        participants: [Participant(type: peerType, id: peerId)],
      ),
    );
    if (!context.mounted) return;
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ConversationPageWrapper(
          conversationId: conversation.id,
        ),
      ),
    );
  } on ChatException catch (e) {
    if (context.mounted) navigator.pop();
    appToast.error(e.message);
  }
}
