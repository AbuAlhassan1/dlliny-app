import 'package:hangout/domain/dto/response/chat_response.dart';

enum MessageDeliveryState {
  pending,

  sent,

  failed,
}

class MessageDisplayItem {
  final MessageResponse message;
  final MessageDeliveryState state;

  final String? localId;

  final String? localFilePath;

  const MessageDisplayItem({
    required this.message,
    this.state = MessageDeliveryState.sent,
    this.localId,
    this.localFilePath,
  });

  bool get isPending => state == MessageDeliveryState.pending;
  bool get isFailed => state == MessageDeliveryState.failed;
  bool get isSent => state == MessageDeliveryState.sent;

  MessageDisplayItem copyWith({
    MessageResponse? message,
    MessageDeliveryState? state,
    String? localId,
    String? localFilePath,
  }) {
    return MessageDisplayItem(
      message: message ?? this.message,
      state: state ?? this.state,
      localId: localId ?? this.localId,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
