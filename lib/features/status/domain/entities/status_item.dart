import 'package:flutter/foundation.dart';

/// An immutable domain entity representing a single status update (story) item.
///
/// Status items are visible to the owner's contacts (or a custom privacy list)
/// for exactly 24 hours from [postedAt]. After that they are removed from all
/// viewers' feeds.
@immutable
class StatusItem {
  const StatusItem({
    required this.id,
    required this.userId,
    this.mediaUrl,
    this.text,
    this.backgroundColor,
    required this.postedAt,
    required this.expiresAt,
    required this.viewers,
    this.privacyList,
  });

  /// Unique identifier for this status item.
  final String id;

  /// User ID of the person who posted this status.
  final String userId;

  /// Remote URL of the media file (image or video) attached to this status.
  ///
  /// Null for text-only statuses.
  final String? mediaUrl;

  /// Text content of the status (up to 700 characters).
  ///
  /// Null for media-only statuses.
  final String? text;

  /// Background color for text statuses, expressed as a CSS hex string
  /// (e.g. `"#128C7E"`). Null when a media file is present.
  final String? backgroundColor;

  /// UTC timestamp when this status was posted.
  final DateTime postedAt;

  /// UTC timestamp when this status expires ([postedAt] + 24 hours).
  final DateTime expiresAt;

  /// Map of viewer user IDs to the UTC timestamp at which they viewed the status.
  final Map<String, DateTime> viewers;

  /// Optional list of user IDs allowed to see this status.
  ///
  /// When non-null, only users on this list can view the status regardless of
  /// whether they are contacts. When null, all contacts can view it.
  final List<String>? privacyList;

  /// Returns a copy of this [StatusItem] with the given fields replaced.
  StatusItem copyWith({
    String? id,
    String? userId,
    Object? mediaUrl = _sentinel,
    Object? text = _sentinel,
    Object? backgroundColor = _sentinel,
    DateTime? postedAt,
    DateTime? expiresAt,
    Map<String, DateTime>? viewers,
    Object? privacyList = _sentinel,
  }) {
    return StatusItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaUrl: mediaUrl == _sentinel ? this.mediaUrl : mediaUrl as String?,
      text: text == _sentinel ? this.text : text as String?,
      backgroundColor: backgroundColor == _sentinel
          ? this.backgroundColor
          : backgroundColor as String?,
      postedAt: postedAt ?? this.postedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewers: viewers ?? this.viewers,
      privacyList: privacyList == _sentinel
          ? this.privacyList
          : privacyList as List<String>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StatusItem) return false;

    // Compare viewers map
    if (viewers.length != other.viewers.length) return false;
    for (final entry in viewers.entries) {
      if (other.viewers[entry.key] != entry.value) return false;
    }

    // Compare privacyList
    final myList = privacyList;
    final otherList = other.privacyList;
    if (myList == null && otherList != null) return false;
    if (myList != null && otherList == null) return false;
    if (myList != null && otherList != null) {
      if (myList.length != otherList.length) return false;
      for (var i = 0; i < myList.length; i++) {
        if (myList[i] != otherList[i]) return false;
      }
    }

    return other.id == id &&
        other.userId == userId &&
        other.mediaUrl == mediaUrl &&
        other.text == text &&
        other.backgroundColor == backgroundColor &&
        other.postedAt == postedAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    mediaUrl,
    text,
    backgroundColor,
    postedAt,
    expiresAt,
    Object.hashAll(viewers.entries.map((e) => Object.hash(e.key, e.value))),
    privacyList == null ? null : Object.hashAll(privacyList!),
  );

  @override
  String toString() =>
      'StatusItem('
      'id: $id, '
      'userId: $userId, '
      'postedAt: $postedAt, '
      'expiresAt: $expiresAt, '
      'viewers: ${viewers.length}'
      ')';
}

const Object _sentinel = Object();
