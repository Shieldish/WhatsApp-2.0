import 'package:whatsapp2_0/core/local_database/app_database.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/data/local/daos/conversation_dao.dart';
import 'package:whatsapp2_0/features/chats/data/local/daos/message_dao.dart';
import 'package:whatsapp2_0/features/chats/domain/conversation_repository.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/search_result.dart';

/// Concrete implementation of [ConversationRepository] backed by Drift SQLite.
///
/// Maps [ConversationsTableData] rows to [Conversation] domain entities and
/// delegates all persistence operations to [ConversationDao].
///
/// Full-text search is implemented via the FTS5 virtual table `messages_fts`
/// (created in [AppDatabase.migration]) through [MessageDao.searchMessages].
///
/// Requirements: 3.1, 3.2, 3.4, 3.5, 3.6
class ConversationRepositoryImpl implements ConversationRepository {
  const ConversationRepositoryImpl({
    required ConversationDao conversationDao,
    required MessageDao messageDao,
  }) : _conversationDao = conversationDao,
       _messageDao = messageDao;

  final ConversationDao _conversationDao;
  final MessageDao _messageDao;

  // ---------------------------------------------------------------------------
  // Reactive streams
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Conversation>> watchConversations() {
    return _conversationDao.watchConversations().map(
      (rows) => rows.map(_mapRow).toList(),
    );
  }

  @override
  Stream<List<Conversation>> watchArchivedConversations() {
    return _conversationDao.watchArchivedConversations().map(
      (rows) => rows.map(_mapRow).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> archiveConversation(String id) async {
    try {
      await _conversationDao.archiveConversation(id);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to archive conversation: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> unarchiveConversation(String id) async {
    try {
      await _conversationDao.unarchiveConversation(id);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to unarchive conversation: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> deleteConversation(String id) async {
    try {
      await _conversationDao.deleteConversation(id);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to delete conversation: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Full-text search (FTS5)
  // ---------------------------------------------------------------------------

  @override
  Future<Result<List<SearchResult>, AppError>> search(String query) async {
    if (query.trim().isEmpty) {
      return const Ok([]);
    }

    try {
      final messages = await _messageDao.searchMessages(query);

      final results = messages.map((msg) {
        // Build a short snippet from the plaintext cache.
        final text = msg.plaintextCache ?? '';
        final snippet = _buildSnippet(text, query);

        return SearchResult(
          conversationId: msg.conversationId,
          conversationName: null, // populated from Firestore in later tasks
          messageId: msg.id,
          snippet: snippet,
          sentAt: DateTime.fromMillisecondsSinceEpoch(msg.sentAt),
        );
      }).toList();

      return Ok(results);
    } catch (e) {
      return Err(StorageError(message: 'Search failed: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Maps a [ConversationsTableData] row to a [Conversation] domain entity.
  ///
  /// Fields not stored locally (participantIds, adminIds, groupName, etc.) are
  /// set to empty/default values; they will be populated from Firestore in
  /// later tasks.
  static Conversation _mapRow(ConversationsTableData row) {
    return Conversation(
      id: row.id,
      type: row.type == 'group'
          ? ConversationType.group
          : ConversationType.direct,
      participantIds: const [], // populated from Firestore in later tasks
      lastMessagePreview: row.lastMessagePreview,
      lastMessageAt: row.lastMessageAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastMessageAt!)
          : null,
      unreadCount: row.unreadCount,
      isArchived: row.isArchived,
      mutedUntil: row.mutedUntil != null
          ? DateTime.fromMillisecondsSinceEpoch(row.mutedUntil!)
          : null,
      groupName: null,
      groupIconUrl: null,
      adminIds: null,
      messagingRestricted: false,
    );
  }

  /// Builds a short text snippet around the first occurrence of [query] in
  /// [text], suitable for display in search results.
  static String _buildSnippet(String text, String query) {
    if (text.isEmpty) return '';

    const maxLength = 100;
    const contextChars = 30;

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      // Query not found in plaintext — return the beginning of the text.
      return text.length <= maxLength
          ? text
          : '${text.substring(0, maxLength)}…';
    }

    final start = (index - contextChars).clamp(0, text.length);
    final end = (index + lowerQuery.length + contextChars).clamp(
      0,
      text.length,
    );

    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';

    return '$prefix${text.substring(start, end)}$suffix';
  }
}
