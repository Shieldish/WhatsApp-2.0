import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../result.dart';
import 'domain/entities/key_bundle.dart';
import 'signal_protocol_store.dart';

/// Secure storage key used to check whether keys have already been generated.
const String _registrationIdKey = 'signal_registration_id';

/// Secure storage key for the serialised identity key pair.
const String _identityKeyPairStorageKey = 'signal_identity_key_pair';

/// Number of one-time pre-keys generated on first registration.
const int _initialPreKeyCount = 100;

/// Number of one-time pre-keys generated during a refresh.
const int _refreshPreKeyCount = 100;

/// The signed pre-key ID used for the initial signed pre-key.
const int _signedPreKeyId = 1;

/// Orchestrates Signal Protocol key generation, local storage, and upload of
/// the public [KeyBundle] to Firestore.
///
/// ## Responsibilities
///
/// 1. **Key generation** – uses top-level helpers from `libsignal_protocol_dart`
///    (`generateIdentityKeyPair`, `generateRegistrationId`, `generateSignedPreKey`,
///    `generatePreKeys`) to create all required key material.
/// 2. **Local storage** – delegates persistence to [DriftSignalProtocolStore]:
///    - Identity key pair and registration ID → `flutter_secure_storage`.
///    - Pre-keys and signed pre-key → Drift [PreKeysTable].
/// 3. **Firestore upload** – publishes the public [KeyBundle] to
///    `/users/{userId}` as the `publicKeyBundle` field so that other users
///    can initiate encrypted sessions.
///
/// ## Security invariant
///
/// The identity *private* key never leaves `flutter_secure_storage`. Only
/// public key material is written to Firestore.
class KeyManager {
  KeyManager({
    required DriftSignalProtocolStore store,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
  }) : _store = store,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final DriftSignalProtocolStore _store;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Initialises Signal Protocol keys for [userId].
  ///
  /// If keys already exist (detected by the presence of the registration ID
  /// in secure storage), this method skips key generation and only uploads
  /// the public key bundle to Firestore.
  ///
  /// Returns [Ok] on success or [Err] with an [AppError] on failure.
  Future<Result<void, AppError>> initialize(String userId) async {
    try {
      final alreadyInitialized = await _keysExist();

      if (!alreadyInitialized) {
        await _generateAndStoreKeys();
      }

      return await _uploadPublicKeyBundle(userId);
    } on Exception catch (e) {
      return Err(
        UnknownError(message: 'KeyManager.initialize failed', cause: e),
      );
    }
  }

  /// Returns the public [KeyBundle] for [userId] by reading it from Firestore.
  ///
  /// Returns [Err] if the document does not exist or the bundle cannot be
  /// parsed.
  Future<Result<KeyBundle, AppError>> getPublicKeyBundle(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return Err(
          NetworkError(message: 'User document not found for userId: $userId'),
        );
      }

      final data = doc.data();
      if (data == null) {
        return Err(
          NetworkError(message: 'User document is empty for userId: $userId'),
        );
      }

      final bundleData = data['publicKeyBundle'];
      if (bundleData == null) {
        return Err(
          NetworkError(message: 'No publicKeyBundle found for userId: $userId'),
        );
      }

      final bundle = _keyBundleFromFirestoreMap(
        userId,
        Map<String, dynamic>.from(bundleData as Map),
      );
      return Ok(bundle);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Firestore error fetching key bundle: ${e.message}',
          statusCode: e.code.isNotEmpty ? int.tryParse(e.code) : null,
        ),
      );
    } on Exception catch (e) {
      return Err(
        UnknownError(message: 'Failed to fetch public key bundle', cause: e),
      );
    }
  }

  /// Generates and uploads additional one-time pre-keys when the supply is low.
  ///
  /// Returns [Ok] on success or [Err] on failure.
  Future<Result<void, AppError>> refreshOneTimePreKeys(String userId) async {
    try {
      final startId = _computeNextPreKeyStartId();
      final newPreKeys = generatePreKeys(startId, _refreshPreKeyCount);

      for (final preKey in newPreKeys) {
        await _store.storePreKey(preKey.id, preKey);
      }

      return await _uploadPublicKeyBundle(userId);
    } on Exception catch (e) {
      return Err(
        UnknownError(
          message: 'KeyManager.refreshOneTimePreKeys failed',
          cause: e,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<bool> _keysExist() async {
    final stored = await _secureStorage.read(key: _registrationIdKey);
    return stored != null;
  }

  Future<void> _generateAndStoreKeys() async {
    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(false);

    await _secureStorage.write(
      key: _registrationIdKey,
      value: registrationId.toString(),
    );
    await _secureStorage.write(
      key: _identityKeyPairStorageKey,
      value: base64.encode(identityKeyPair.serialize()),
    );

    final signedPreKey = generateSignedPreKey(identityKeyPair, _signedPreKeyId);
    await _store.storeSignedPreKey(signedPreKey.id, signedPreKey);

    final preKeys = generatePreKeys(0, _initialPreKeyCount);
    for (final preKey in preKeys) {
      await _store.storePreKey(preKey.id, preKey);
    }
  }

  Future<Result<void, AppError>> _uploadPublicKeyBundle(String userId) async {
    try {
      final bundleResult = await _buildLocalPublicKeyBundle(userId);
      if (bundleResult.isErr) {
        return Err(bundleResult.errorOrNull!);
      }
      final bundle = bundleResult.valueOrNull!;
      final firestoreMap = _keyBundleToFirestoreMap(bundle);

      await _firestore.collection('users').doc(userId).set({
        'publicKeyBundle': firestoreMap,
      }, SetOptions(merge: true));

      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Firestore error uploading key bundle: ${e.message}',
          statusCode: e.code.isNotEmpty ? int.tryParse(e.code) : null,
        ),
      );
    } on Exception catch (e) {
      return Err(
        UnknownError(message: 'Failed to upload public key bundle', cause: e),
      );
    }
  }

  Future<Result<KeyBundle, AppError>> _buildLocalPublicKeyBundle(
    String userId,
  ) async {
    try {
      final identityKeyPair = await _store.getIdentityKeyPair();
      final registrationId = await _store.getLocalRegistrationId();
      final signedPreKeyRecord = await _store.loadSignedPreKey(_signedPreKeyId);
      final allPreKeyRecords = await _loadOneTimePreKeys();

      final identityKeyBytes = Uint8List.fromList(
        identityKeyPair.getPublicKey().serialize(),
      );
      final signedPreKeyBytes = Uint8List.fromList(
        signedPreKeyRecord.getKeyPair().publicKey.serialize(),
      );
      final signedPreKeySignatureBytes = Uint8List.fromList(
        signedPreKeyRecord.signature,
      );
      final oneTimePreKeyBytes = allPreKeyRecords
          .map(
            (pk) => Uint8List.fromList(pk.getKeyPair().publicKey.serialize()),
          )
          .toList();

      return Ok(
        KeyBundle(
          userId: userId,
          identityKey: identityKeyBytes,
          signedPreKey: signedPreKeyBytes,
          signedPreKeyId: signedPreKeyRecord.id,
          signedPreKeySignature: signedPreKeySignatureBytes,
          oneTimePreKeys: oneTimePreKeyBytes,
          registrationId: registrationId,
        ),
      );
    } on StateError catch (e) {
      return Err(StorageError(message: e.message));
    } on InvalidKeyIdException catch (e) {
      return Err(EncryptionError(message: 'Key not found: $e'));
    } on Exception catch (e) {
      return Err(
        UnknownError(message: 'Failed to build local key bundle', cause: e),
      );
    }
  }

  Future<List<PreKeyRecord>> _loadOneTimePreKeys() async {
    final records = <PreKeyRecord>[];
    for (var i = 1; i <= _initialPreKeyCount; i++) {
      final exists = await _store.containsPreKey(i);
      if (exists) {
        final record = await _store.loadPreKey(i);
        records.add(record);
      }
    }
    return records;
  }

  Map<String, dynamic> _keyBundleToFirestoreMap(KeyBundle bundle) {
    return {
      'identityKey': base64.encode(bundle.identityKey),
      'signedPreKeyId': bundle.signedPreKeyId,
      'signedPreKey': base64.encode(bundle.signedPreKey),
      'signedPreKeySignature': base64.encode(bundle.signedPreKeySignature),
      'oneTimePreKeys': bundle.oneTimePreKeys
          .asMap()
          .entries
          .map((e) => {'keyId': e.key, 'key': base64.encode(e.value)})
          .toList(),
      'registrationId': bundle.registrationId,
    };
  }

  KeyBundle _keyBundleFromFirestoreMap(
    String userId,
    Map<String, dynamic> map,
  ) {
    final identityKey = base64.decode(map['identityKey'] as String);
    final signedPreKeyId = map['signedPreKeyId'] as int;
    final signedPreKey = base64.decode(map['signedPreKey'] as String);
    final signedPreKeySignature = base64.decode(
      map['signedPreKeySignature'] as String,
    );
    final registrationId = map['registrationId'] as int;

    final rawOneTimePreKeys = map['oneTimePreKeys'] as List<dynamic>;
    final oneTimePreKeys = rawOneTimePreKeys
        .map(
          (e) => Uint8List.fromList(
            base64.decode((e as Map<String, dynamic>)['key'] as String),
          ),
        )
        .toList();

    return KeyBundle(
      userId: userId,
      identityKey: Uint8List.fromList(identityKey),
      signedPreKey: Uint8List.fromList(signedPreKey),
      signedPreKeyId: signedPreKeyId,
      signedPreKeySignature: Uint8List.fromList(signedPreKeySignature),
      oneTimePreKeys: oneTimePreKeys,
      registrationId: registrationId,
    );
  }

  int _computeNextPreKeyStartId() {
    return DateTime.now().millisecondsSinceEpoch & 0xFFFFFF;
  }
}
