import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class ChatCacheRepository {
  static const _dbName = 'hangout_chat.db';
  static const _schemaVersion = 1;

  Database? _db;
  Future<Database>? _opening;

  Future<Database> _open() {
    if (_db != null) return Future.value(_db!);
    return _opening ??= _openImpl();
  }

  Future<Database> _openImpl() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_dbName';
    final db = await openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            title TEXT,
            avatarUrl TEXT,
            unreadCount INTEGER NOT NULL,
            viewerRequestState TEXT NOT NULL,
            muted INTEGER NOT NULL,
            retentionDays INTEGER,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            membersJson TEXT NOT NULL,
            lastMessageJson TEXT
          );
        ''');
        await db.execute(
          'CREATE INDEX idx_conversations_updatedAt ON conversations(updatedAt DESC);',
        );
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversationId TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            json TEXT NOT NULL
          );
        ''');
        await db.execute(
          'CREATE INDEX idx_messages_conv_time ON messages(conversationId, createdAt DESC);',
        );
        await db.execute('''
          CREATE TABLE pending_sends (
            localId TEXT PRIMARY KEY,
            conversationId TEXT NOT NULL,
            contentType TEXT NOT NULL,
            content TEXT,
            audioFilePath TEXT,
            audioDurationSeconds INTEGER,
            audioWaveform TEXT,
            replyToMessageId TEXT,
            failedAt TEXT NOT NULL,
            attempts INTEGER NOT NULL
          );
        ''');
        await db.execute(
          'CREATE INDEX idx_pending_conv ON pending_sends(conversationId);',
        );
      },
    );
    _db = db;
    return db;
  }

  Future<void> upsertConversations(
    List<ConversationResponse> conversations,
  ) async {
    if (conversations.isEmpty) return;
    final db = await _open();
    final batch = db.batch();
    for (final c in conversations) {
      batch.insert(
        'conversations',
        _conversationToRow(c),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertConversation(ConversationResponse c) =>
      upsertConversations([c]);

  Future<void> removeConversation(String id) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete('conversations', where: 'id = ?', whereArgs: [id]);
      await txn.delete('messages',
          where: 'conversationId = ?', whereArgs: [id]);
      await txn.delete('pending_sends',
          where: 'conversationId = ?', whereArgs: [id]);
    });
  }

  Future<List<ConversationResponse>> loadInbox({int limit = 50}) async {
    final db = await _open();
    final rows = await db.query(
      'conversations',
      where: 'viewerRequestState = ?',
      whereArgs: ['ACCEPTED'],
      orderBy: 'updatedAt DESC',
      limit: limit,
    );
    return rows
        .map(_rowToConversation)
        .whereType<ConversationResponse>()
        .toList(growable: false);
  }

  Future<List<ConversationResponse>> loadRequests({int limit = 50}) async {
    final db = await _open();
    final rows = await db.query(
      'conversations',
      where: 'viewerRequestState = ?',
      whereArgs: ['PENDING'],
      orderBy: 'updatedAt DESC',
      limit: limit,
    );
    return rows
        .map(_rowToConversation)
        .whereType<ConversationResponse>()
        .toList(growable: false);
  }

  Future<ConversationResponse?> loadConversation(String id) async {
    final db = await _open();
    final rows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _rowToConversation(rows.first);
  }

  Future<void> upsertMessages(
    String conversationId,
    List<MessageResponse> messages,
  ) async {
    if (messages.isEmpty) return;
    final db = await _open();
    final batch = db.batch();
    for (final m in messages) {
      batch.insert(
        'messages',
        {
          'id': m.id,
          'conversationId': conversationId,
          'createdAt': m.createdAt,
          'json': jsonEncode(m.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertMessage(
    String conversationId,
    MessageResponse message,
  ) =>
      upsertMessages(conversationId, [message]);

  Future<void> removeMessage(String messageId) async {
    final db = await _open();
    await db.delete('messages', where: 'id = ?', whereArgs: [messageId]);
  }

  Future<List<MessageResponse>> loadLatestMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    final db = await _open();
    final rows = await db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    final messages = rows
        .map((r) => _rowToMessage(r['json'] as String?))
        .whereType<MessageResponse>()
        .toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  Future<void> enqueuePending(PendingSend send) async {
    final db = await _open();
    await db.insert(
      'pending_sends',
      send.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removePending(String localId) async {
    final db = await _open();
    await db.delete(
      'pending_sends',
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  Future<List<PendingSend>> loadPendingFor(String conversationId) async {
    final db = await _open();
    final rows = await db.query(
      'pending_sends',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'failedAt ASC',
    );
    return rows.map(PendingSend.fromRow).toList(growable: false);
  }

  Future<void> clear() async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete('conversations');
      await txn.delete('messages');
      await txn.delete('pending_sends');
    });
  }

  Map<String, Object?> _conversationToRow(ConversationResponse c) {
    return {
      'id': c.id,
      'type': _conversationTypeToWire(c.type),
      'title': c.title,
      'avatarUrl': c.avatarUrl,
      'unreadCount': c.unreadCount,
      'viewerRequestState': _requestStateToWire(c.viewerRequestState),
      'muted': c.muted ? 1 : 0,
      'retentionDays': c.retentionDays,
      'createdAt': c.createdAt,
      'updatedAt': c.updatedAt,
      'membersJson':
          jsonEncode(c.members.map((m) => m.toJson()).toList(growable: false)),
      'lastMessageJson':
          c.lastMessage == null ? null : jsonEncode(c.lastMessage!.toJson()),
    };
  }

  ConversationResponse? _rowToConversation(Map<String, Object?> row) {
    try {
      final membersRaw = row['membersJson'] as String? ?? '[]';
      final lastRaw = row['lastMessageJson'] as String?;
      final members = (jsonDecode(membersRaw) as List)
          .whereType<Map<String, dynamic>>()
          .map(ChatMemberResponse.fromJson)
          .toList(growable: false);
      final lastMessage = lastRaw == null
          ? null
          : MessageResponse.fromJson(jsonDecode(lastRaw) as Map<String, dynamic>);
      return ConversationResponse(
        id: row['id'] as String,
        type: _wireToConversationType(row['type'] as String),
        title: row['title'] as String?,
        avatarUrl: row['avatarUrl'] as String?,
        members: members,
        lastMessage: lastMessage,
        unreadCount: row['unreadCount'] as int? ?? 0,
        viewerRequestState:
            _wireToRequestState(row['viewerRequestState'] as String),
        muted: (row['muted'] as int? ?? 0) == 1,
        retentionDays: row['retentionDays'] as int?,
        createdAt: row['createdAt'] as String,
        updatedAt: row['updatedAt'] as String,
      );
    } catch (e) {
      log('ChatCache: row → ConversationResponse failed: $e');
      return null;
    }
  }

  MessageResponse? _rowToMessage(String? json) {
    if (json == null) return null;
    try {
      return MessageResponse.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      log('ChatCache: row → MessageResponse failed: $e');
      return null;
    }
  }

  String _conversationTypeToWire(ConversationType t) =>
      t == ConversationType.group ? 'GROUP' : 'DIRECT';

  ConversationType _wireToConversationType(String s) =>
      s == 'GROUP' ? ConversationType.group : ConversationType.direct;

  String _requestStateToWire(ChatRequestState s) =>
      s == ChatRequestState.pending ? 'PENDING' : 'ACCEPTED';

  ChatRequestState _wireToRequestState(String s) =>
      s == 'PENDING' ? ChatRequestState.pending : ChatRequestState.accepted;
}

class PendingSend {
  final String localId;
  final String conversationId;
  final MessageContentType contentType;
  final String? content;
  final String? audioFilePath;
  final int? audioDurationSeconds;
  final String? audioWaveform;
  final String? replyToMessageId;
  final DateTime failedAt;
  final int attempts;

  const PendingSend({
    required this.localId,
    required this.conversationId,
    required this.contentType,
    this.content,
    this.audioFilePath,
    this.audioDurationSeconds,
    this.audioWaveform,
    this.replyToMessageId,
    required this.failedAt,
    this.attempts = 0,
  });

  bool get audioFileStillExists =>
      audioFilePath != null && File(audioFilePath!).existsSync();

  Map<String, Object?> toRow() => {
        'localId': localId,
        'conversationId': conversationId,
        'contentType': _wireFor(contentType),
        'content': content,
        'audioFilePath': audioFilePath,
        'audioDurationSeconds': audioDurationSeconds,
        'audioWaveform': audioWaveform,
        'replyToMessageId': replyToMessageId,
        'failedAt': failedAt.toUtc().toIso8601String(),
        'attempts': attempts,
      };

  factory PendingSend.fromRow(Map<String, Object?> row) {
    return PendingSend(
      localId: row['localId'] as String,
      conversationId: row['conversationId'] as String,
      contentType: _typeFromWire(row['contentType'] as String),
      content: row['content'] as String?,
      audioFilePath: row['audioFilePath'] as String?,
      audioDurationSeconds: row['audioDurationSeconds'] as int?,
      audioWaveform: row['audioWaveform'] as String?,
      replyToMessageId: row['replyToMessageId'] as String?,
      failedAt: DateTime.tryParse(row['failedAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      attempts: row['attempts'] as int? ?? 0,
    );
  }

  static String _wireFor(MessageContentType t) {
    switch (t) {
      case MessageContentType.text:
        return 'TEXT';
      case MessageContentType.voice:
        return 'VOICE';
      case MessageContentType.share:
        return 'SHARE';
    }
  }

  static MessageContentType _typeFromWire(String s) {
    switch (s) {
      case 'VOICE':
        return MessageContentType.voice;
      case 'SHARE':
        return MessageContentType.share;
      case 'TEXT':
      default:
        return MessageContentType.text;
    }
  }
}
