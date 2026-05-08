import 'package:flutter/foundation.dart';

/// An immutable domain entity representing a device contact who is also a
/// registered app user.
@immutable
class AppContact {
  const AppContact({
    required this.userId,
    required this.phoneNumber,
    required this.displayName,
    this.photoUrl,
    required this.isBlocked,
  });

  /// The unique user ID of this contact within the app.
  final String userId;

  /// The contact's phone number in E.164 format.
  final String phoneNumber;

  /// The display name shown in the contact list and conversation headers.
  final String displayName;

  /// Remote URL of the contact's profile photo, if set.
  final String? photoUrl;

  /// Whether the current user has blocked this contact.
  final bool isBlocked;

  /// Returns a copy of this [AppContact] with the given fields replaced.
  AppContact copyWith({
    String? userId,
    String? phoneNumber,
    String? displayName,
    Object? photoUrl = _sentinel,
    bool? isBlocked,
  }) {
    return AppContact(
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl == _sentinel ? this.photoUrl : photoUrl as String?,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppContact &&
        other.userId == userId &&
        other.phoneNumber == phoneNumber &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.isBlocked == isBlocked;
  }

  @override
  int get hashCode =>
      Object.hash(userId, phoneNumber, displayName, photoUrl, isBlocked);

  @override
  String toString() =>
      'AppContact('
      'userId: $userId, '
      'displayName: $displayName, '
      'phoneNumber: $phoneNumber, '
      'isBlocked: $isBlocked'
      ')';
}

const Object _sentinel = Object();
