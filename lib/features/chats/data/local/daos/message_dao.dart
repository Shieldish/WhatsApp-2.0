import 'package:drift/drift.dart';

import '../../../../../core/local_database/app_database.dart';
import '../tables/messages_table.dart';

part 'message_dao.g.dart';

/// Data Access Object for [MessagesTable].
///
/// Provides typed query methods for inserting, updating, querying, and
/// deleting message records in the local Drift database.
@DriftAccessor(tables: [MessagesTable])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Inserts a new message row.
  Future<void> insertMessage(MessagesTableCompanion message) =>
      into(messagesTable).insert(message);

  /// Updates an existing message row matched by its primary key.
  Future<bool> updateMessage(MessagesTableCompanion message) =>
      update(messagesTable).replace(message);

  /// Deletes the message with the given [id].
  Future<int> deleteMessage(String id) =>
      (delete(messagesTable)..where((t) => t.id.equals(id))).go();

  /// Updates only the [status] field of the message identified by [id].
  Future<int> updateMessageStatus(String id, String status) =>
      (update(messagesTable)..where((t) => t.id.equals(id))).write(
        MessagesTableCompanion(status: Value(status)),
      );

  /// Updates the [deliveredAt] and/or [readAt] timestamps for a message.
  ///
  /// Pass `null` for a timestamp to leave it unchanged.
  Future<int> updateDeliveryTimestamps({
    required String id,
    int? deliveredAt,
    int? readAt,
  }) => (update(messagesTable)..where((t) => t.id.equals(id))).write(
    MessagesTableCompanion(
      deliveredAt: deliveredAt != null
          ? Value(deliveredAt)
          : const Value.absent(),
      readAt: readAt != null ? Value(readAt) : const Value.absent(),
    ),
  );

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Returns a single message by [id], or `null` if not found.
  Future<MessagesTableData?> getMessageById(String id) =>
      (select(messagesTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns all messages whose [status] is `'failed'`, suitable for retry.
  Future<List<MessagesTableData>> getFailedMessages() =>
      (select(messagesTable)..where((t) => t.status.equals('failed'))).get();

  // ---------------------------------------------------------------------------
  // Reactive streams
  // ---------------------------------------------------------------------------

  /// Emits the ordered list of messages for [conversationId] whenever the
  /// underlying data changes. Messages are sorted by [sentAt] ascending so
  /// the oldest message appears first in the chat view.
  Stream<List<MessagesTableData>> watchMessages(String conversationId) =>
      (select(messagesTable)
            ..where((t) => t.conversationId.equals(conversationId))
            ..orderBy([(t) => OrderingTerm.asc(t.sentAt)]))
          .watch();

  // ---------------------------------------------------------------------------
  // Full-text search (FTS5)
  // ---------------------------------------------------------------------------

  /// Searches messages using the FTS5 virtual table `messages_fts`.
  ///
  /// Returns rows from [MessagesTable] whose [plaintextCache] matches [query].
  /// Results are ordered by [sentAt] descending (most recent first).
  ///
  /// The FTS5 table is created in [AppDatabase.migration] `onCreate`.
  ///
  /// Requirements: 3.6
  Future<List<MessagesTableData>> searchMessages(String query) async {
    if (query.trim().isEmpty) return const [];

    // Sanitise the query: escape double-quotes and wrap in double-quotes so
    // FTS5 treats it as a phrase search rather than a bare token that could
    // contain special FTS5 syntax characters.
    final sanitised = query.replaceAll('"', '""');

    final rows = await customSelect(
      '''
      SELECT m.*
      FROM messages m
      INNER JOIN messages_fts fts ON fts.rowid = m.rowid
      WHERE messages_fts MATCH ?
      ORDER BY m.sent_at DESC
      ''',
      variables: [Variable.withString('"$sanitised"')],
      readsFrom: {messagesTable},
    ).get();

    return rows.map((row) => messagesTable.map(row.data)).toList();
  }
}
