import 'package:flutter/foundation.dart';

/// Whether a conversation is a direct (one-to-one) or group chat.
enum ConversationType { direct, group }

/// An immutable domain entity representing a chat conversation thread.
///
/// Covers both one-to-one ([ConversationType.direct]) and group
/// ([ConversationType.group]) conversations. Group-specific fields
/// ([groupName], [groupIconUrl], [adminIds], [messagingRestricted]) are
/// non-null only when [type] is [ConversationType.group].
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
    required this.isArchived,
    this.mutedUntil,
    this.groupName,
    this.groupIconUrl,
    this.adminIds,
    required this.messagingRestricted,
  });

  final String id;

  /// Whether this is a direct or group conversation.
  final ConversationType type;

  /// Ordered list of user IDs participating in this conversation.
  final List<String> participantIds;

  /// Short preview of the last message (may be encrypted on the server;
  /// stored decrypted locally for display purposes).
  final String? lastMessagePreview;

  /// UTC timestamp of the most recent message in this conversation.
  final DateTime? lastMessageAt;

  /// Number of messages the current user has not yet read.
  final int unreadCount;

  /// Whether this conversation has been archived by the current user.
  final bool isArchived;

  /// If non-null, notifications for this conversation are muted until this time.
  final DateTime? mutedUntil;

  // ── Group-specific fields ──────────────────────────────────────────────────

  /// Display name of the group (null for direct conversations).
  final String? groupName;

  /// Remote URL of the group icon image (null for direct conversations).
  final String? groupIconUrl;

  /// User IDs of group admins (null for direct conversations).
  final List<String>? adminIds;

  /// When true, only admins may send messages to this group.
  final bool messagingRestricted;

  /// Returns a copy of this [Conversation] with the given fields replaced.
  Conversation copyWith({
    String? id,
    ConversationType? type,
    List<String>? participantIds,
    Object? lastMessagePreview = _sentinel,
    Object? lastMessageAt = _sentinel,
    int? unreadCount,
    bool? isArchived,
    Object? mutedUntil = _sentinel,
    Object? groupName = _sentinel,
    Object? groupIconUrl = _sentinel,
    Object? adminIds = _sentinel,
    bool? messagingRestricted,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      lastMessagePreview: lastMessagePreview == _sentinel
          ? this.lastMessagePreview
          : lastMessagePreview as String?,
      lastMessageAt: lastMessageAt == _sentinel
          ? this.lastMessageAt
          : lastMessageAt as DateTime?,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      mutedUntil: mutedUntil == _sentinel
          ? this.mutedUntil
          : mutedUntil as DateTime?,
      groupName: groupName == _sentinel ? this.groupName : groupName as String?,
      groupIconUrl: groupIconUrl == _sentinel
          ? this.groupIconUrl
          : groupIconUrl as String?,
      adminIds: adminIds == _sentinel
          ? this.adminIds
          : adminIds as List<String>?,
      messagingRestricted: messagingRestricted ?? this.messagingRestricted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Conversation) return false;
    if (participantIds.length != other.participantIds.length) return false;
    for (var i = 0; i < participantIds.length; i++) {
      if (participantIds[i] != other.participantIds[i]) return false;
    }
    final myAdminIds = adminIds;
    final otherAdminIds = other.adminIds;
    if (myAdminIds == null && otherAdminIds != null) return false;
    if (myAdminIds != null && otherAdminIds == null) return false;
    if (myAdminIds != null && otherAdminIds != null) {
      if (myAdminIds.length != otherAdminIds.length) return false;
      for (var i = 0; i < myAdminIds.length; i++) {
        if (myAdminIds[i] != otherAdminIds[i]) return false;
      }
    }
    return other.id == id &&
        other.type == type &&
        other.lastMessagePreview == lastMessagePreview &&
        other.lastMessageAt == lastMessageAt &&
        other.unreadCount == unreadCount &&
        other.isArchived == isArchived &&
        other.mutedUntil == mutedUntil &&
        other.groupName == groupName &&
        other.groupIconUrl == groupIconUrl &&
        other.messagingRestricted == messagingRestricted;
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    Object.hashAll(participantIds),
    lastMessagePreview,
    lastMessageAt,
    unreadCount,
    isArchived,
    mutedUntil,
    groupName,
    groupIconUrl,
    adminIds == null ? null : Object.hashAll(adminIds!),
    messagingRestricted,
  );

  @override
  String toString() =>
      'Conversation('
      'id: $id, '
      'type: $type, '
      'participantIds: $participantIds, '
      'unreadCount: $unreadCount, '
      'isArchived: $isArchived'
      ')';
}

const Object _sentinel = Object();
