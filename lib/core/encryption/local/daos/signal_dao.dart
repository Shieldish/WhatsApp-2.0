import 'package:drift/drift.dart';

import '../../../local_database/app_database.dart';
import '../pre_keys_table.dart';
import '../signal_sessions_table.dart';

part 'signal_dao.g.dart';

/// Data Access Object for Signal Protocol persistence tables.
///
/// Covers both [SignalSessionsTable] (Double Ratchet session state) and
/// [PreKeysTable] (one-time pre-keys used in X3DH key agreement).
@DriftAccessor(tables: [SignalSessionsTable, PreKeysTable])
class SignalDao extends DatabaseAccessor<AppDatabase> with _$SignalDaoMixin {
  SignalDao(super.db);

  // ---------------------------------------------------------------------------
  // Session operations
  // ---------------------------------------------------------------------------

  /// Returns the session record for the given [recipientId] and [deviceId],
  /// or `null` if no session exists.
  Future<SignalSessionsTableData?> getSession(
    String recipientId,
    String deviceId,
  ) =>
      (select(signalSessionsTable)..where(
            (t) =>
                t.recipientId.equals(recipientId) & t.deviceId.equals(deviceId),
          ))
          .getSingleOrNull();

  /// Inserts or replaces the session record (upsert semantics).
  Future<void> saveSession(SignalSessionsTableCompanion session) =>
      into(signalSessionsTable).insertOnConflictUpdate(session);

  /// Deletes the session for the given [recipientId] and [deviceId].
  Future<int> deleteSession(String recipientId, String deviceId) =>
      (delete(signalSessionsTable)..where(
            (t) =>
                t.recipientId.equals(recipientId) & t.deviceId.equals(deviceId),
          ))
          .go();

  /// Returns all session records for the given [recipientId] (one per device).
  Future<List<SignalSessionsTableData>> getAllSessions(String recipientId) =>
      (select(
        signalSessionsTable,
      )..where((t) => t.recipientId.equals(recipientId))).get();

  // ---------------------------------------------------------------------------
  // Pre-key operations
  // ---------------------------------------------------------------------------

  /// Returns the pre-key with the given [keyId], or `null` if not found.
  Future<PreKeysTableData?> getPreKey(int keyId) => (select(
    preKeysTable,
  )..where((t) => t.keyId.equals(keyId))).getSingleOrNull();

  /// Inserts or replaces a pre-key record (upsert semantics).
  ///
  /// Uses [insertOnConflictUpdate] so that re-storing a key with the same
  /// [keyId] (e.g. refreshing a signed pre-key) overwrites the existing row.
  Future<void> savePreKey(PreKeysTableCompanion preKey) =>
      into(preKeysTable).insertOnConflictUpdate(preKey);

  /// Marks the pre-key with [keyId] as used (sets `used = true`).
  Future<int> markPreKeyUsed(int keyId) =>
      (update(preKeysTable)..where((t) => t.keyId.equals(keyId))).write(
        const PreKeysTableCompanion(used: Value(true)),
      );

  /// Returns all pre-keys that have not yet been consumed in a key exchange.
  Future<List<PreKeysTableData>> getUnusedPreKeys() =>
      (select(preKeysTable)..where((t) => t.used.equals(false))).get();

  /// Returns every row in [PreKeysTable] regardless of [used] status.
  ///
  /// Used by [DriftSignalProtocolStore.loadSignedPreKeys] to enumerate all
  /// signed pre-keys (which are stored with IDs ≥ 0x80000000 and are never
  /// marked as used).
  Future<List<PreKeysTableData>> getAllPreKeys() => select(preKeysTable).get();

  /// Deletes the pre-key with the given [keyId].
  Future<int> deletePreKey(int keyId) =>
      (delete(preKeysTable)..where((t) => t.keyId.equals(keyId))).go();
}
