import 'package:dio/dio.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/add_members_request.dart';
import 'package:hangout/domain/dto/request/create_conversation_request.dart';
import 'package:hangout/domain/dto/request/edit_message_request.dart';
import 'package:hangout/domain/dto/request/mark_read_request.dart';
import 'package:hangout/domain/dto/request/mute_conversation_request.dart';
import 'package:hangout/domain/dto/request/send_message_request.dart';
import 'package:hangout/domain/dto/request/update_conversation_request.dart';
import 'package:hangout/domain/dto/request/update_member_role_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';

class ChatRepository {
  final ApiService _api;
  ChatRepository(this._api);

  Future<ConversationResponse> createConversation(
    CreateConversationRequest request,
  ) =>
      _unwrap(() => _api.createConversation(request));

  Future<PagedResponse<ConversationResponse>> getInbox({
    int page = 0,
    int size = 20,
  }) =>
      _unwrap(() => _api.getChatInbox(page: page, size: size));

  Future<PagedResponse<ConversationResponse>> getMessageRequests({
    int page = 0,
    int size = 20,
  }) =>
      _unwrap(() => _api.getMessageRequests(page: page, size: size));

  Future<ConversationResponse> getConversation(String conversationId) =>
      _unwrap(() => _api.getConversation(conversationId));

  Future<void> acceptRequest(String conversationId) =>
      _unwrapVoid(() => _api.acceptMessageRequest(conversationId));

  Future<void> rejectRequest(String conversationId) =>
      _unwrapVoid(() => _api.rejectMessageRequest(conversationId));

  Future<void> leaveConversation(String conversationId) =>
      _unwrapVoid(() => _api.leaveConversation(conversationId));

  Future<PagedResponse<MessageResponse>> getMessages(
    String conversationId, {
    int page = 0,
    int size = 50,
  }) =>
      _unwrap(() => _api.getMessages(conversationId, page: page, size: size));

  Future<MessageResponse> sendMessage(
    String conversationId,
    SendMessageRequest request,
  ) =>
      _unwrap(() => _api.sendMessage(conversationId, request));

  Future<void> markRead(String conversationId, String latestMessageId) =>
      _unwrapVoid(
        () => _api.markConversationRead(
          conversationId,
          MarkReadRequest(messageId: latestMessageId),
        ),
      );

  Future<MessageResponse> editMessage(String messageId, String content) =>
      _unwrap(
        () => _api.editMessage(messageId, EditMessageRequest(content: content)),
      );

  Future<void> deleteMessage(String messageId, {required String scope}) =>
      _unwrapVoid(() => _api.deleteMessage(messageId, scope: scope));

  Future<VoiceUploadUrlResponse> getVoiceUploadUrl(String contentType) =>
      _unwrap(() => _api.getVoiceUploadUrl(contentType));

  Future<ConversationResponse> updateConversation(
    String conversationId,
    UpdateConversationRequest request,
  ) =>
      _unwrap(() => _api.updateConversation(conversationId, request));

  Future<void> setMuted(String conversationId, bool muted) =>
      _unwrapVoid(
        () => _api.muteConversation(
          conversationId,
          MuteConversationRequest(muted: muted),
        ),
      );

  Future<ConversationResponse> addMembers(
    String conversationId,
    List<String> userIds,
  ) =>
      _unwrap(
        () => _api.addMembers(
          conversationId,
          AddMembersRequest(userIds: userIds),
        ),
      );

  Future<void> removeMember(String conversationId, String userId) =>
      _unwrapVoid(() => _api.removeMember(conversationId, userId));

  Future<void> updateMemberRole(
    String conversationId,
    String userId,
    ChatMemberRole role,
  ) =>
      _unwrapVoid(
        () => _api.updateMemberRole(
          conversationId,
          userId,
          UpdateMemberRoleRequest(role: role),
        ),
      );

  Future<T> _unwrap<T>(Future<ApiResponse<T>> Function() call) async {
    try {
      final response = await call();
      if (response.success && response.data != null) {
        return response.data as T;
      }
      throw ChatUnexpectedException(response.error ?? 'Unknown error');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> _unwrapVoid(Future<ApiResponse<dynamic>> Function() call) async {
    try {
      final response = await call();
      if (response.success) return;
      throw ChatUnexpectedException(response.error ?? 'Unknown error');
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ChatException _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final serverMessage = _extractMessage(body);

    if (status == null) {
      return ChatTransientException(e.message ?? 'Network error');
    }
    if (status == 400) {
      if (serverMessage.toLowerCase().contains('edit window')) {
        return EditWindowExpiredException(serverMessage);
      }
      return ChatValidationException(serverMessage);
    }
    if (status == 403) return ChatForbiddenException(serverMessage);
    if (status == 404) return ResourceMissingException(serverMessage);
    if (status == 409) return ChatTransientException(serverMessage);
    if (status >= 500) return ChatTransientException(serverMessage);
    return ChatUnexpectedException(serverMessage);
  }

  String _extractMessage(dynamic body) {
    if (body is Map) {
      final m = body['error'] ?? body['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    if (body is String && body.isNotEmpty) return body;
    return 'Request failed';
  }
}
