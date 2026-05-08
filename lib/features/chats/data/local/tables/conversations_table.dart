import 'package:drift/drift.dart';

/// Drift table definition for locally stored conversations.
///
/// Tracks both direct and group conversations with metadata needed to render
/// the chat list screen without hitting the network.
class ConversationsTable extends Table {
  @override
  String get tableName => 'conversations';

  TextColumn get id => text()();

  /// Conversation type: direct | group
  TextColumn get type => text()();

  TextColumn get lastMessagePreview => text().nullable()();
  IntColumn get lastMessageAt => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  /// Unix timestamp (ms) until which notifications are muted; null = not muted.
  IntColumn get mutedUntil => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
