import 'package:drift/drift.dart';

/// Drift table definition for locally stored messages.
///
/// Stores encrypted message payloads and metadata for offline-first access.
/// The [plaintextCache] column is populated only after successful decryption
/// and is considered in-memory/transient — it should be cleared on logout.
class MessagesTable extends Table {
  @override
  String get tableName => 'messages';

  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  BlobColumn get ciphertext => blob()();

  /// Decrypted plaintext cache — in-memory only, cleared on logout.
  TextColumn get plaintextCache => text().nullable()();

  TextColumn get mediaLocalPath => text().nullable()();
  TextColumn get type => text()();
  IntColumn get sentAt => integer()();
  IntColumn get deliveredAt => integer().nullable()();
  IntColumn get readAt => integer().nullable()();
  BoolColumn get deletedForEveryone =>
      boolean().withDefault(const Constant(false))();
  TextColumn get quotedMessageId => text().nullable()();

  /// Message delivery status: sending | sent | delivered | read | failed
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {id};
}
