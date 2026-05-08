import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../local_database/app_database.dart';
import 'local/daos/signal_dao.dart';
import 'local/pre_keys_table.dart';
import 'local/signal_sessions_table.dart';

/// Offset applied to signed pre-key IDs so they can be stored in the same
/// [PreKeysTable] as one-time pre-keys without colliding.
///
/// Signed pre-key IDs are stored as `_signedPreKeyOffset + signedPreKeyId`.
const int _signedPreKeyOffset = 0x80000000;

/// Secure storage keys.
const String _identityKeyPairKey = 'signal_identity_key_pair';
const String _registrationIdKey = 'signal_registration_id';
String _trustedIdentityKey(String recipientId) =>
    'trusted_identity_$recipientId';

/// A persistent [SignalProtocolStore] implementation backed by:
///
/// - [flutter_secure_storage] for the identity key pair, registration ID, and
///   trusted identity keys (sensitive material that must never touch SQLite).
/// - [SignalDao] / Drift for session records ([SignalSessionsTable]) and
///   pre-keys ([PreKeysTable]).
///
/// This class implements all four Signal Protocol store interfaces:
/// [IdentityKeyStore], [PreKeyStore], [SignedPreKeyStore], and [SessionStore].
///
/// **Security invariant:** The identity private key is stored exclusively in
/// the device keychain/keystore via [flutter_secure_storage] and is never
/// written to Drift or Firestore.
class DriftSignalProtocolStore implements SignalProtocolStore {
  DriftSignalProtocolStore({
    required AppDatabase database,
    FlutterSecureStorage? secureStorage,
  }) : _dao = database.signalDao,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SignalDao _dao;
  final FlutterSecureStorage _secureStorage;

  // ---------------------------------------------------------------------------
  // IdentityKeyStore
  // ---------------------------------------------------------------------------

  /// Returns the local identity key pair, reading it from secure storage.
  ///
  /// Throws a [StateError] if no identity key pair has been stored yet (i.e.
  /// the device has not been registered).
  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async {
    final encoded = await _secureStorage.read(key: _identityKeyPairKey);
    if (encoded == null) {
      throw StateError(
        'No identity key pair found in secure storage. '
        'Call KeyManager.initialize() before using the store.',
      );
    }
    final bytes = base64.decode(encoded);
    return IdentityKeyPair.fromSerialized(Uint8List.fromList(bytes));
  }

  /// Returns the local Signal Protocol registration ID from secure storage.
  ///
  /// Throws a [StateError] if no registration ID has been stored yet.
  @override
  Future<int> getLocalRegistrationId() async {
    final stored = await _secureStorage.read(key: _registrationIdKey);
    if (stored == null) {
      throw StateError(
        'No registration ID found in secure storage. '
        'Call KeyManager.initialize() before using the store.',
      );
    }
    return int.parse(stored);
  }

  /// Persists the identity key for [address] in secure storage.
  ///
  /// Returns `true` if the key was new or changed (i.e. a key-change event
  /// occurred), `false` if the key was already known and unchanged.
  @override
  Future<bool> saveIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
  ) async {
    if (identityKey == null) return false;

    final storageKey = _trustedIdentityKey(address.getName());
    final existing = await _secureStorage.read(key: storageKey);
    final newEncoded = base64.encode(identityKey.serialize());

    if (existing == newEncoded) {
      // Key unchanged — no key-change event.
      return false;
    }

    await _secureStorage.write(key: storageKey, value: newEncoded);
    // Key was new or changed — signal a key-change event to callers.
    return true;
  }

  /// Returns `true` if [identityKey] is trusted for [address].
  ///
  /// A key is trusted when:
  /// - No key has been stored for this address yet (first contact), or
  /// - The stored key matches [identityKey] exactly.
  ///
  /// The [direction] parameter is accepted for interface compatibility but
  /// does not affect the trust decision in this implementation.
  @override
  Future<bool> isTrustedIdentity(
    SignalProtocolAddress address,
    IdentityKey? identityKey,
    Direction direction,
  ) async {
    if (identityKey == null) return false;

    final storageKey = _trustedIdentityKey(address.getName());
    final stored = await _secureStorage.read(key: storageKey);

    if (stored == null) {
      // No prior key — trust on first use (TOFU).
      return true;
    }

    final storedBytes = base64.decode(stored);
    final storedKey = IdentityKey.fromBytes(Uint8List.fromList(storedBytes), 0);
    return storedKey == identityKey;
  }

  /// Returns the stored identity key for [address], or `null` if unknown.
  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async {
    final storageKey = _trustedIdentityKey(address.getName());
    final stored = await _secureStorage.read(key: storageKey);
    if (stored == null) return null;

    final bytes = base64.decode(stored);
    return IdentityKey.fromBytes(Uint8List.fromList(bytes), 0);
  }

  // ---------------------------------------------------------------------------
  // PreKeyStore
  // ---------------------------------------------------------------------------

  /// Loads the one-time pre-key with [preKeyId] from [PreKeysTable].
  ///
  /// Throws [InvalidKeyIdException] if the key does not exist.
  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    final row = await _dao.getPreKey(preKeyId);
    if (row == null) {
      throw InvalidKeyIdException('No pre-key found for id $preKeyId');
    }
    return PreKeyRecord.fromBuffer(row.keyRecord);
  }

  /// Persists a one-time pre-key to [PreKeysTable].
  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    await _dao.savePreKey(
      PreKeysTableCompanion.insert(
        keyId: Value(preKeyId),
        keyRecord: record.serialize(),
      ),
    );
  }

  /// Returns `true` if a one-time pre-key with [preKeyId] exists in the store.
  @override
  Future<bool> containsPreKey(int preKeyId) async {
    final row = await _dao.getPreKey(preKeyId);
    return row != null;
  }

  /// Deletes the one-time pre-key with [preKeyId] from [PreKeysTable].
  @override
  Future<void> removePreKey(int preKeyId) async {
    await _dao.deletePreKey(preKeyId);
  }

  // ---------------------------------------------------------------------------
  // SignedPreKeyStore
  //
  // Signed pre-keys are stored in [PreKeysTable] using IDs offset by
  // [_signedPreKeyOffset] to avoid collisions with one-time pre-key IDs.
  // ---------------------------------------------------------------------------

  /// Loads the signed pre-key with [signedPreKeyId] from [PreKeysTable].
  ///
  /// Throws [InvalidKeyIdException] if the key does not exist.
  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    final storageId = _signedPreKeyOffset + signedPreKeyId;
    final row = await _dao.getPreKey(storageId);
    if (row == null) {
      throw InvalidKeyIdException(
        'No signed pre-key found for id $signedPreKeyId',
      );
    }
    return SignedPreKeyRecord.fromSerialized(row.keyRecord);
  }

  /// Returns all signed pre-keys stored in [PreKeysTable].
  ///
  /// Signed pre-keys are identified by their storage ID being ≥
  /// [_signedPreKeyOffset].
  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    final allRows = await _dao.getAllPreKeys();
    final results = <SignedPreKeyRecord>[];
    for (final row in allRows) {
      if (row.keyId >= _signedPreKeyOffset) {
        results.add(SignedPreKeyRecord.fromSerialized(row.keyRecord));
      }
    }
    return results;
  }

  /// Persists a signed pre-key to [PreKeysTable] using an offset ID.
  @override
  Future<void> storeSignedPreKey(
    int signedPreKeyId,
    SignedPreKeyRecord record,
  ) async {
    final storageId = _signedPreKeyOffset + signedPreKeyId;
    await _dao.savePreKey(
      PreKeysTableCompanion.insert(
        keyId: Value(storageId),
        keyRecord: record.serialize(),
      ),
    );
  }

  /// Returns `true` if a signed pre-key with [signedPreKeyId] exists.
  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
    final storageId = _signedPreKeyOffset + signedPreKeyId;
    final row = await _dao.getPreKey(storageId);
    return row != null;
  }

  /// Deletes the signed pre-key with [signedPreKeyId] from [PreKeysTable].
  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    final storageId = _signedPreKeyOffset + signedPreKeyId;
    await _dao.deletePreKey(storageId);
  }

  // ---------------------------------------------------------------------------
  // SessionStore
  // ---------------------------------------------------------------------------

  /// Loads the session record for [address] from [SignalSessionsTable].
  ///
  /// Returns a fresh (empty) [SessionRecord] if no session exists yet,
  /// matching the behaviour expected by the Signal Protocol library.
  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    final row = await _dao.getSession(
      address.getName(),
      address.getDeviceId().toString(),
    );
    if (row == null) {
      return SessionRecord();
    }
    return SessionRecord.fromSerialized(row.sessionRecord);
  }

  /// Returns the device IDs of all sub-device sessions for [name].
  ///
  /// The primary device (device ID 1) is excluded from the result, matching
  /// the Signal Protocol convention for `getSubDeviceSessions`.
  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    final rows = await _dao.getAllSessions(name);
    return rows
        .map((r) => int.parse(r.deviceId))
        .where((id) => id != 1)
        .toList();
  }

  /// Persists the session record for [address] to [SignalSessionsTable].
  @override
  Future<void> storeSession(
    SignalProtocolAddress address,
    SessionRecord record,
  ) async {
    await _dao.saveSession(
      SignalSessionsTableCompanion.insert(
        recipientId: address.getName(),
        deviceId: address.getDeviceId().toString(),
        sessionRecord: record.serialize(),
      ),
    );
  }

  /// Returns `true` if a session record exists for [address].
  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    final row = await _dao.getSession(
      address.getName(),
      address.getDeviceId().toString(),
    );
    return row != null;
  }

  /// Deletes the session record for [address] from [SignalSessionsTable].
  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    await _dao.deleteSession(
      address.getName(),
      address.getDeviceId().toString(),
    );
  }

  /// Deletes all session records for the user identified by [name].
  @override
  Future<void> deleteAllSessions(String name) async {
    final rows = await _dao.getAllSessions(name);
    for (final row in rows) {
      await _dao.deleteSession(row.recipientId, row.deviceId);
    }
  }
}
