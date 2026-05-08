import 'package:drift/drift.dart';

/// Drift table definition for persisted Signal Protocol session records.
///
/// Each row represents a serialised session state for a specific
/// (recipientId, deviceId) pair. The composite primary key ensures a single
/// session record per device of each recipient.
class SignalSessionsTable extends Table {
  @override
  String get tableName => 'signal_sessions';

  TextColumn get recipientId => text()();
  TextColumn get deviceId => text()();

  /// Serialised Signal Protocol session state (opaque binary blob).
  BlobColumn get sessionRecord => blob()();

  @override
  Set<Column> get primaryKey => {recipientId, deviceId};
}
