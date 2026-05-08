import 'package:flutter/foundation.dart';

/// The type of content a message carries.
enum MessageType { text, image, video, audio, document, location, system }

/// The MIME category of an attached media file.
enum MediaType { image, video, audio, document }

/// The delivery lifecycle state of a message.
///
/// Valid transitions: sending → sent → delivered → read
/// The [failed] state is a terminal error state reachable from [sending].
enum DeliveryStatus { sending, sent, delivered, read, failed }

/// An immutable domain entity representing a single chat message.
@immutable
class Message {
  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.plaintext,
    this.mediaUrl,
    this.mediaType,
    required this.type,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    required this.status,
    required this.deletedForEveryone,
    this.quotedMessageId,
  });

  final String id;
  final String conversationId;
  final String senderId;

  /// Decrypted message text; null until the message has been decrypted locally.
  final String? plaintext;

  /// Remote URL of the attached media file, if any.
  final String? mediaUrl;

  /// MIME category of the attached media file.
  final MediaType? mediaType;

  /// Structural type of the message (text, image, system event, etc.).
  final MessageType type;

  /// UTC timestamp when the message was sent by the sender.
  final DateTime sentAt;

  /// UTC timestamp when the message was delivered to the recipient's device.
  final DateTime? deliveredAt;

  /// UTC timestamp when the recipient opened the conversation and read the message.
  final DateTime? readAt;

  /// Current delivery lifecycle state.
  final DeliveryStatus status;

  /// Whether the sender has deleted this message for all participants.
  final bool deletedForEveryone;

  /// ID of the message being quoted/replied to, if any.
  final String? quotedMessageId;

  /// Returns a copy of this [Message] with the given fields replaced.
  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    Object? plaintext = _sentinel,
    Object? mediaUrl = _sentinel,
    Object? mediaType = _sentinel,
    MessageType? type,
    DateTime? sentAt,
    Object? deliveredAt = _sentinel,
    Object? readAt = _sentinel,
    DeliveryStatus? status,
    bool? deletedForEveryone,
    Object? quotedMessageId = _sentinel,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      plaintext: plaintext == _sentinel ? this.plaintext : plaintext as String?,
      mediaUrl: mediaUrl == _sentinel ? this.mediaUrl : mediaUrl as String?,
      mediaType: mediaType == _sentinel
          ? this.mediaType
          : mediaType as MediaType?,
      type: type ?? this.type,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt == _sentinel
          ? this.deliveredAt
          : deliveredAt as DateTime?,
      readAt: readAt == _sentinel ? this.readAt : readAt as DateTime?,
      status: status ?? this.status,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      quotedMessageId: quotedMessageId == _sentinel
          ? this.quotedMessageId
          : quotedMessageId as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.conversationId == conversationId &&
        other.senderId == senderId &&
        other.plaintext == plaintext &&
        other.mediaUrl == mediaUrl &&
        other.mediaType == mediaType &&
        other.type == type &&
        other.sentAt == sentAt &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt &&
        other.status == status &&
        other.deletedForEveryone == deletedForEveryone &&
        other.quotedMessageId == quotedMessageId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    senderId,
    plaintext,
    mediaUrl,
    mediaType,
    type,
    sentAt,
    deliveredAt,
    readAt,
    status,
    deletedForEveryone,
    quotedMessageId,
  );

  @override
  String toString() =>
      'Message('
      'id: $id, '
      'conversationId: $conversationId, '
      'senderId: $senderId, '
      'type: $type, '
      'status: $status, '
      'sentAt: $sentAt'
      ')';
}

// Sentinel object used to distinguish "not provided" from explicit null in copyWith.
const Object _sentinel = Object();
