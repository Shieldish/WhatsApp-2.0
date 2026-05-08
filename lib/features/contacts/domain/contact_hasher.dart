import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Hashes device phone numbers with SHA-256 before any network call.
///
/// Privacy guarantee: raw phone numbers MUST never be returned or transmitted
/// to the server. Only hex-encoded SHA-256 hashes are produced by this class.
///
/// Requirements: 2.1
class ContactHasher {
  // Private constructor — all methods are static.
  ContactHasher._();

  /// Returns the hex-encoded SHA-256 hash of [phoneE164].
  ///
  /// [phoneE164] should be a phone number in E.164 format (e.g. `+14155552671`).
  /// The raw number is never stored or returned; only the hash is produced.
  static String hash(String phoneE164) {
    final bytes = utf8.encode(phoneE164);
    final digest = sha256.convert(bytes);
    return digest.toString(); // hex string, e.g. "a9f3..."
  }

  /// Returns a list of hex-encoded SHA-256 hashes for each phone number in
  /// [phones].
  ///
  /// The order of the output list matches the order of [phones].
  /// Raw phone numbers are never returned — only hashes.
  static List<String> hashAll(List<String> phones) {
    return phones.map(hash).toList();
  }
}
