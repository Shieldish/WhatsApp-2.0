import 'package:flutter/foundation.dart';

/// An immutable domain entity representing a user's public Signal Protocol
/// key bundle.
///
/// The [KeyBundle] contains all public keys required for X3DH key agreement.
/// The corresponding private keys are stored exclusively in
/// [flutter_secure_storage] and never leave the device.
///
/// This bundle is uploaded to Firestore at `/users/{userId}.publicKeyBundle`
/// so that other users can initiate encrypted sessions.
@immutable
class KeyBundle {
  const KeyBundle({
    required this.userId,
    required this.identityKey,
    required this.signedPreKey,
    required this.signedPreKeyId,
    required this.signedPreKeySignature,
    required this.oneTimePreKeys,
    required this.registrationId,
  });

  /// The user ID that owns this key bundle.
  final String userId;

  /// The long-term identity public key (Curve25519, 32 bytes).
  final Uint8List identityKey;

  /// The signed pre-key public key (Curve25519, 32 bytes).
  final Uint8List signedPreKey;

  /// Numeric identifier for the signed pre-key, used to look up the
  /// corresponding private key during session establishment.
  final int signedPreKeyId;

  /// Ed25519 signature over [signedPreKey], produced with the identity
  /// private key.
  final Uint8List signedPreKeySignature;

  /// A batch of one-time pre-keys (Curve25519, 32 bytes each).
  ///
  /// Each key is consumed once during X3DH and then discarded.
  final List<Uint8List> oneTimePreKeys;

  /// The Signal Protocol registration ID for this device.
  final int registrationId;

  /// Returns a copy of this [KeyBundle] with the given fields replaced.
  KeyBundle copyWith({
    String? userId,
    Uint8List? identityKey,
    Uint8List? signedPreKey,
    int? signedPreKeyId,
    Uint8List? signedPreKeySignature,
    List<Uint8List>? oneTimePreKeys,
    int? registrationId,
  }) {
    return KeyBundle(
      userId: userId ?? this.userId,
      identityKey: identityKey ?? this.identityKey,
      signedPreKey: signedPreKey ?? this.signedPreKey,
      signedPreKeyId: signedPreKeyId ?? this.signedPreKeyId,
      signedPreKeySignature:
          signedPreKeySignature ?? this.signedPreKeySignature,
      oneTimePreKeys: oneTimePreKeys ?? this.oneTimePreKeys,
      registrationId: registrationId ?? this.registrationId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! KeyBundle) return false;
    if (!_uint8ListEquals(identityKey, other.identityKey)) return false;
    if (!_uint8ListEquals(signedPreKey, other.signedPreKey)) return false;
    if (!_uint8ListEquals(signedPreKeySignature, other.signedPreKeySignature)) {
      return false;
    }
    if (oneTimePreKeys.length != other.oneTimePreKeys.length) return false;
    for (var i = 0; i < oneTimePreKeys.length; i++) {
      if (!_uint8ListEquals(oneTimePreKeys[i], other.oneTimePreKeys[i])) {
        return false;
      }
    }
    return other.userId == userId &&
        other.signedPreKeyId == signedPreKeyId &&
        other.registrationId == registrationId;
  }

  @override
  int get hashCode => Object.hash(
    userId,
    Object.hashAll(identityKey),
    Object.hashAll(signedPreKey),
    signedPreKeyId,
    Object.hashAll(signedPreKeySignature),
    Object.hashAll(oneTimePreKeys.expand((k) => k)),
    registrationId,
  );

  @override
  String toString() =>
      'KeyBundle('
      'userId: $userId, '
      'signedPreKeyId: $signedPreKeyId, '
      'registrationId: $registrationId, '
      'oneTimePreKeys: ${oneTimePreKeys.length} keys'
      ')';
}

/// Byte-by-byte equality check for [Uint8List] values.
bool _uint8ListEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
