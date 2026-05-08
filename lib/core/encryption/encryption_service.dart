import 'dart:typed_data';

import '../result.dart';
import 'domain/entities/key_bundle.dart';

/// Abstract facade for the Signal Protocol end-to-end encryption layer.
///
/// All message content is encrypted before leaving the device and decrypted
/// only on the recipient's device. The server never has access to plaintext.
///
/// ## Lifecycle
///
/// 1. Call [initialize] once per app session (after authentication) to set up
///    or restore the local Signal Protocol key material.
/// 2. Use [encryptMessage] / [decryptMessage] for every message sent/received.
/// 3. Use [getPublicKeyBundle] to fetch a contact's public keys from Firestore.
/// 4. Use [verifySecurityCode] to confirm an E2EE session with a contact.
///
/// ## Error handling
///
/// All methods return [Result<T, AppError>] so callers can pattern-match on
/// success/failure without relying on exceptions.
abstract class EncryptionService {
  /// Initialises Signal Protocol keys for [userId].
  ///
  /// Generates a new identity key pair, signed pre-key, and one-time pre-keys
  /// on first registration. On subsequent calls, skips key generation and only
  /// ensures the public key bundle is up-to-date in Firestore.
  ///
  /// Returns [Ok(null)] on success or [Err] with an [AppError] on failure.
  Future<Result<void, AppError>> initialize(String userId);

  /// Encrypts [plaintext] for [recipientId] using the Signal Protocol.
  ///
  /// Fetches the recipient's public key bundle from Firestore, establishes a
  /// session if one does not already exist, and returns the serialised
  /// ciphertext as a [Uint8List].
  ///
  /// Returns [Err] with an [EncryptionError] if:
  /// - The recipient's key bundle cannot be fetched.
  /// - The recipient's identity key has changed (untrusted identity).
  /// - Session establishment fails.
  Future<Result<Uint8List, AppError>> encryptMessage(
    String recipientId,
    String plaintext,
  );

  /// Decrypts [ciphertext] received from [senderId].
  ///
  /// Automatically determines whether the ciphertext is a
  /// [PreKeySignalMessage] (first message in a new session) or a regular
  /// [SignalMessage] and decrypts accordingly.
  ///
  /// Returns [Err] with an [EncryptionError] if:
  /// - No session exists for [senderId] and the message is not a pre-key
  ///   message.
  /// - The message is a duplicate.
  /// - Decryption fails for any other reason.
  Future<Result<String, AppError>> decryptMessage(
    String senderId,
    Uint8List ciphertext,
  );

  /// Returns the public [KeyBundle] for [userId] from Firestore.
  ///
  /// Returns [Err] with a [NetworkError] if the user document does not exist
  /// or the bundle cannot be parsed.
  Future<Result<KeyBundle, AppError>> getPublicKeyBundle(String userId);

  /// Verifies the 60-digit security code for the E2EE session with [contactId].
  ///
  /// Generates the expected security code by combining the local identity key
  /// fingerprint and the contact's identity key fingerprint (sorted by user ID
  /// so both parties see the same code), then compares it with [code].
  ///
  /// Returns [Ok(true)] if the codes match, [Ok(false)] if they do not.
  /// Returns [Err] if the contact's identity key cannot be retrieved.
  Future<Result<bool, AppError>> verifySecurityCode(
    String contactId,
    String code,
  );
}
