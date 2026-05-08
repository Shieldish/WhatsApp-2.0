import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/chats/data/local/daos/conversation_dao.dart';
import '../../features/chats/data/local/daos/message_dao.dart';
import '../../features/chats/data/local/tables/conversations_table.dart';
import '../../features/chats/data/local/tables/messages_table.dart';
import '../encryption/local/daos/signal_dao.dart';
import '../encryption/local/pre_keys_table.dart';
import '../encryption/local/signal_sessions_table.dart';

part 'app_database.g.dart';

/// The main Drift database for the WhatsApp clone.
///
/// Includes all four local tables and the three DAOs that provide typed
/// query access to those tables. The database file is opened in the
/// background using [NativeDatabase.createInBackground] so that the main
/// isolate is never blocked by I/O.
///
/// Schema version history:
///   v1 – initial schema (messages, conversations, signal_sessions, pre_keys)
@DriftDatabase(
  tables: [
    MessagesTable,
    ConversationsTable,
    SignalSessionsTable,
    PreKeysTable,
  ],
  daos: [MessageDao, ConversationDao, SignalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor used in tests to inject a custom [QueryExecutor] (e.g. an
  /// in-memory SQLite database).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Create the FTS5 virtual table that mirrors the plaintext_cache and
      // conversation_id columns from the messages table.  The `content`
      // option makes this a content table so FTS5 reads from `messages`
      // directly and we only need to keep the index in sync via triggers.
      //
      // Requirements: 3.6
      await customStatement('''
        CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts
        USING fts5(
          plaintext_cache,
          conversation_id UNINDEXED,
          content=messages,
          content_rowid=rowid
        )
      ''');

      // Triggers to keep the FTS5 index in sync with the messages table.
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS messages_ai
        AFTER INSERT ON messages BEGIN
          INSERT INTO messages_fts(rowid, plaintext_cache, conversation_id)
          VALUES (new.rowid, new.plaintext_cache, new.conversation_id);
        END
      ''');

      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS messages_ad
        AFTER DELETE ON messages BEGIN
          INSERT INTO messages_fts(messages_fts, rowid, plaintext_cache, conversation_id)
          VALUES ('delete', old.rowid, old.plaintext_cache, old.conversation_id);
        END
      ''');

      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS messages_au
        AFTER UPDATE ON messages BEGIN
          INSERT INTO messages_fts(messages_fts, rowid, plaintext_cache, conversation_id)
          VALUES ('delete', old.rowid, old.plaintext_cache, old.conversation_id);
          INSERT INTO messages_fts(rowid, plaintext_cache, conversation_id)
          VALUES (new.rowid, new.plaintext_cache, new.conversation_id);
        END
      ''');
    },
  );
}

/// Opens the SQLite database file in the application's documents directory.
///
/// [NativeDatabase.createInBackground] spawns a dedicated isolate for all
/// database I/O, keeping the UI thread responsive.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'whatsapp_clone.db'));
    return NativeDatabase.createInBackground(file);
  });
}
