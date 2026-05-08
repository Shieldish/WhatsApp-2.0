import 'package:drift/drift.dart';

import '../../../../../core/local_database/app_database.dart';
import '../tables/conversations_table.dart';
import '../tables/messages_table.dart';

part 'conversation_dao.g.dart';

/// Data Access Object for [ConversationsTable].
///
/// Provides typed query methods for managing conversation records, including
/// archive/unarchive, unread-count management, and cascade deletion.
@DriftAccessor(tables: [ConversationsTable, MessagesTable])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts a new conversation row.
  Future<void> insertConversation(ConversationsTableCompanion conversation) =>
      into(conversationsTable).insert(conversation);

  /// Updates an existing conversation row matched by its primary key.
  Future<bool> updateConversation(ConversationsTableCompanion conversation) =>
      update(conversationsTable).replace(conversation);

  /// Archives the conversation with the given [id] (sets `isArchived = true`).
  Future<int> archiveConversation(String id) =>
      (update(conversationsTable)..where((t) => t.id.equals(id))).write(
        const ConversationsTableCompanion(isArchived: Value(true)),
      );

  /// Unarchives the conversation with the given [id] (sets `isArchived = false`).
  Future<int> unarchiveConversation(String id) =>
      (update(conversationsTable)..where((t) => t.id.equals(id))).write(
        const ConversationsTableCompanion(isArchived: Value(false)),
      );

  /// Deletes the conversation with [id] and cascade-deletes all its messages.
  Future<void> deleteConversation(String id) async {
    await transaction(() async {
      // Delete all messages belonging to this conversation first.
      await (delete(
        messagesTable,
      )..where((t) => t.conversationId.equals(id))).go();
      // Then delete the conversation itself.
      await (delete(conversationsTable)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Increments the unread message count for the conversation with [id] by 1.
  Future<void> incrementUnreadCount(String id) async {
    await customUpdate(
      'UPDATE conversations SET unread_count = unread_count + 1 WHERE id = ?',
      variables: [Variable.withString(id)],
      updates: {conversationsTable},
    );
  }

  /// Resets the unread message count for the conversation with [id] to 0.
  Future<int> resetUnreadCount(String id) =>
      (update(conversationsTable)..where((t) => t.id.equals(id))).write(
        const ConversationsTableCompanion(unreadCount: Value(0)),
      );

  /// Updates the last-message preview text and timestamp for the conversation
  /// with [id].
  Future<int> updateLastMessage(String id, String preview, int timestamp) =>
      (update(conversationsTable)..where((t) => t.id.equals(id))).write(
        ConversationsTableCompanion(
          lastMessagePreview: Value(preview),
          lastMessageAt: Value(timestamp),
        ),
      );

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Returns the conversation with [id], or `null` if not found.
  Future<ConversationsTableData?> getConversationById(String id) => (select(
    conversationsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  // ---------------------------------------------------------------------------
  // Reactive streams
  // ---------------------------------------------------------------------------

  /// Emits the list of non-archived conversations ordered by [lastMessageAt]
  /// descending (most recent first) whenever the underlying data changes.
  Stream<List<ConversationsTableData>> watchConversations() =>
      (select(conversationsTable)
            ..where((t) => t.isArchived.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch();

  /// Emits the list of archived conversations ordered by [lastMessageAt]
  /// descending whenever the underlying data changes.
  Stream<List<ConversationsTableData>> watchArchivedConversations() =>
      (select(conversationsTable)
            ..where((t) => t.isArchived.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.lastMessageAt)]))
          .watch();
}
