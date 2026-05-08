import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';

import '../result.dart';
import 'domain/entities/key_bundle.dart';
import 'encryption_service.dart';
import 'key_manager.dart';
import 'signal_protocol_store.dart';

/// Concrete implementation of [EncryptionService] backed by
/// `libsignal_protocol_dart`.
///
/// ## Session establishment
///
/// On the first message to a recipient, [encryptMessage] fetches the
/// recipient's public [KeyBundle] from Firestore via [KeyManager], constructs
/// a [PreKeyBundle], and calls [SessionBuilder.processPreKeyBundle] to perform
/// the X3DH key agreement. Subsequent messages reuse the established Double
/// Ratchet session stored in [DriftSignalProtocolStore].
///
/// ## Security code
///
/// [verifySecurityCode] uses [NumericFingerprintGenerator] — the same
/// algorithm used by the Signal app — to derive a 60-digit code from both
/// parties' identity keys. The code is identical on both devices because the
/// generator sorts the two fingerprints lexicographically before concatenating
/// them.
class SignalEncryptionService implements EncryptionService {
  SignalEncryptionService({
    required KeyManager keyManager,
    required DriftSignalProtocolStore store,
    required String localUserId,
  }) : _keyManager = keyManager,
       _store = store,
       _localUserId = localUserId;

  final KeyManager _keyManager;
  final DriftSignalProtocolStore _store;
  final String _localUserId;

  // ---------------------------------------------------------------------------
  // EncryptionService interface
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> initialize(String userId) {
    return _keyManager.initialize(userId);
  }

  @override
  Future<Result<Uint8List, AppError>> encryptMessage(
    String recipientId,
    String plaintext,
  ) async {
    try {
      // 1. Fetch the recipient's public key bundle from Firestore.
      final bundleResult = await _keyManager.getPublicKeyBundle(recipientId);
      if (bundleResult.isErr) {
        return Err(bundleResult.errorOrNull!);
      }
      final keyBundle = bundleResult.valueOrNull!;

      // 2. Build the Signal Protocol address for the recipient (device ID 1).
      final recipientAddress = SignalProtocolAddress(recipientId, 1);

      // 3. Establish a session if one does not already exist.
      final hasSession = await _store.containsSession(recipientAddress);
      if (!hasSession) {
        final preKeyBundle = _buildPreKeyBundle(keyBundle);
        final sessionBuilder = SessionBuilder.fromSignalStore(
          _store,
          recipientAddress,
        );
        await sessionBuilder.processPreKeyBundle(preKeyBundle);
      }

      // 4. Encrypt the plaintext using the established session.
      final sessionCipher = SessionCipher.fromStore(_store, recipientAddress);
      final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));
      final ciphertextMessage = await sessionCipher.encrypt(plaintextBytes);

      return Ok(Uint8List.fromList(ciphertextMessage.serialize()));
    } on UntrustedIdentityException catch (e) {
      return Err(
        EncryptionError(
          message:
              'Security code changed for $recipientId. '
              'Verify the security code before sending messages. '
              'Details: $e',
        ),
      );
    } on InvalidKeyException catch (e) {
      return Err(
        EncryptionError(message: 'Invalid key during session setup: $e'),
      );
    } on Exception catch (e) {
      return Err(
        EncryptionError(message: 'Encryption failed for $recipientId: $e'),
      );
    }
  }

  @override
  Future<Result<String, AppError>> decryptMessage(
    String senderId,
    Uint8List ciphertext,
  ) async {
    try {
      final senderAddress = SignalProtocolAddress(senderId, 1);
      final sessionCipher = SessionCipher.fromStore(_store, senderAddress);

      // Determine the message type from the first byte of the serialised
      // ciphertext. PreKeySignalMessage has type 3 (CiphertextMessage.prekeyType)
      // and SignalMessage has type 2 (CiphertextMessage.whisperType).
      final messageType = _detectMessageType(ciphertext);

      Uint8List plaintextBytes;
      if (messageType == CiphertextMessage.prekeyType) {
        // First message in a new session — establishes the Double Ratchet.
        final preKeyMessage = PreKeySignalMessage(ciphertext);
        plaintextBytes = await sessionCipher.decrypt(preKeyMessage);
      } else {
        // Subsequent message in an existing session.
        final signalMessage = SignalMessage.fromSerialized(ciphertext);
        plaintextBytes = await sessionCipher.decryptFromSignal(signalMessage);
      }

      return Ok(utf8.decode(plaintextBytes));
    } on UntrustedIdentityException catch (e) {
      return Err(
        EncryptionError(
          message:
              'Security code changed for $senderId. '
              'Verify the security code to restore the session. '
              'Details: $e',
        ),
      );
    } on DuplicateMessageException catch (e) {
      return Err(
        EncryptionError(
          message: 'Duplicate message received from $senderId: $e',
        ),
      );
    } on InvalidMessageException catch (e) {
      return Err(
        EncryptionError(
          message:
              'Unable to decrypt message from $senderId. '
              'The session may be out of sync. Details: $e',
        ),
      );
    } on Exception catch (e) {
      return Err(
        EncryptionError(message: 'Decryption failed for $senderId: $e'),
      );
    }
  }

  @override
  Future<Result<KeyBundle, AppError>> getPublicKeyBundle(String userId) {
    return _keyManager.getPublicKeyBundle(userId);
  }

  @override
  Future<Result<bool, AppError>> verifySecurityCode(
    String contactId,
    String code,
  ) async {
    try {
      // 1. Retrieve the local identity key.
      final localIdentityKeyPair = await _store.getIdentityKeyPair();
      final localIdentityKey = localIdentityKeyPair.getPublicKey();

      // 2. Retrieve the contact's identity key from the trusted identity store.
      //    Fall back to fetching from Firestore if not yet stored locally.
      final contactAddress = SignalProtocolAddress(contactId, 1);
      IdentityKey? contactIdentityKey = await _store.getIdentity(
        contactAddress,
      );

      if (contactIdentityKey == null) {
        // Not yet in the local store — fetch from Firestore.
        final bundleResult = await _keyManager.getPublicKeyBundle(contactId);
        if (bundleResult.isErr) {
          return Err(bundleResult.errorOrNull!);
        }
        final bundle = bundleResult.valueOrNull!;
        contactIdentityKey = IdentityKey.fromBytes(bundle.identityKey, 0);
      }

      // 3. Generate the 60-digit security code using NumericFingerprintGenerator.
      //    5200 iterations matches the Signal app's default.
      final generator = NumericFingerprintGenerator(5200);
      final localStableId = Uint8List.fromList(utf8.encode(_localUserId));
      final remoteStableId = Uint8List.fromList(utf8.encode(contactId));

      final fingerprint = generator.createFor(
        1, // version
        localStableId,
        localIdentityKey,
        remoteStableId,
        contactIdentityKey,
      );

      final expectedCode = fingerprint.displayableFingerprint.getDisplayText();

      return Ok(expectedCode == code);
    } on StateError catch (e) {
      return Err(
        StorageError(
          message:
              'Local identity key not found. '
              'Call initialize() before verifying security codes. '
              'Details: ${e.message}',
        ),
      );
    } on Exception catch (e) {
      return Err(
        EncryptionError(
          message: 'Failed to verify security code for $contactId: $e',
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Constructs a [PreKeyBundle] from a domain [KeyBundle].
  ///
  /// Uses the first available one-time pre-key if present, otherwise passes
  /// `null` (the Signal Protocol allows sessions without a one-time pre-key,
  /// though it is less secure).
  PreKeyBundle _buildPreKeyBundle(KeyBundle bundle) {
    final identityKey = IdentityKey.fromBytes(bundle.identityKey, 0);
    final signedPreKey = Curve.decodePoint(bundle.signedPreKey, 0);

    ECPublicKey? oneTimePreKey;
    int? oneTimePreKeyId;
    if (bundle.oneTimePreKeys.isNotEmpty) {
      oneTimePreKey = Curve.decodePoint(bundle.oneTimePreKeys.first, 0);
      oneTimePreKeyId = 0; // Key ID 0 corresponds to the first pre-key.
    }

    return PreKeyBundle(
      bundle.registrationId,
      1, // device ID — always 1 for mobile clients
      oneTimePreKeyId,
      oneTimePreKey,
      bundle.signedPreKeyId,
      signedPreKey,
      bundle.signedPreKeySignature,
      identityKey,
    );
  }

  /// Detects the Signal Protocol message type from the first byte of the
  /// serialised [ciphertext].
  ///
  /// The first byte encodes `(version << 4) | type`. The lower nibble is the
  /// message type:
  /// - [CiphertextMessage.prekeyType] (3) → [PreKeySignalMessage]
  /// - [CiphertextMessage.whisperType] (2) → [SignalMessage]
  int _detectMessageType(Uint8List ciphertext) {
    if (ciphertext.isEmpty) {
      throw InvalidMessageException('Empty ciphertext');
    }
    // The lower nibble of the first byte is the message type.
    return ciphertext[0] & 0x0F;
  }
}
