import 'package:flutter/foundation.dart';

/// An immutable domain entity representing the online/offline presence state
/// of a user.
@immutable
class PresenceInfo {
  const PresenceInfo({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
  });

  /// The unique user ID whose presence this record describes.
  final String userId;

  /// Whether the user is currently online (app foregrounded with connectivity).
  final bool isOnline;

  /// UTC timestamp of the last time the user was seen online.
  ///
  /// Null when [isOnline] is true (the user is currently online) or when the
  /// user's privacy setting prevents sharing last-seen information.
  final DateTime? lastSeen;

  /// Returns a copy of this [PresenceInfo] with the given fields replaced.
  PresenceInfo copyWith({
    String? userId,
    bool? isOnline,
    Object? lastSeen = _sentinel,
  }) {
    return PresenceInfo(
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen == _sentinel ? this.lastSeen : lastSeen as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresenceInfo &&
        other.userId == userId &&
        other.isOnline == isOnline &&
        other.lastSeen == lastSeen;
  }

  @override
  int get hashCode => Object.hash(userId, isOnline, lastSeen);

  @override
  String toString() =>
      'PresenceInfo('
      'userId: $userId, '
      'isOnline: $isOnline, '
      'lastSeen: $lastSeen'
      ')';
}

const Object _sentinel = Object();
