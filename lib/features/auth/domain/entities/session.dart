import 'package:flutter/foundation.dart';

/// An immutable domain entity representing an authenticated user session.
///
/// A [Session] is created after successful OTP verification and persisted
/// securely in the device keychain via [flutter_secure_storage].
@immutable
class Session {
  const Session({
    required this.userId,
    required this.phoneNumber,
    required this.token,
    required this.createdAt,
  });

  /// The unique user ID assigned by the backend upon registration.
  final String userId;

  /// The verified phone number in E.164 format associated with this session.
  final String phoneNumber;

  /// The Firebase ID token (or equivalent auth token) for this session.
  final String token;

  /// UTC timestamp when this session was created.
  final DateTime createdAt;

  /// Returns a copy of this [Session] with the given fields replaced.
  Session copyWith({
    String? userId,
    String? phoneNumber,
    String? token,
    DateTime? createdAt,
  }) {
    return Session(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session &&
        other.userId == userId &&
        other.phoneNumber == phoneNumber &&
        other.token == token &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(userId, phoneNumber, token, createdAt);

  @override
  String toString() =>
      'Session('
      'userId: $userId, '
      'phoneNumber: $phoneNumber, '
      'createdAt: $createdAt'
      ')';
}
