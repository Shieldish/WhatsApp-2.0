import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';

/// Parameters required to send a new message.
///
/// Passed to [MessageRepository.sendMessage] to encapsulate all the data
/// needed to create and deliver a message.
///
/// Requirements: 4.1, 4.8
class SendMessageParams {
  const SendMessageParams({
    required this.conversationId,
    required this.recipientId,
    required this.plaintext,
    this.type = MessageType.text,
    this.quotedMessageId,
    this.mediaUrl,
    this.mediaType,
  });

  /// The conversation this message belongs to.
  final String conversationId;

  /// The recipient's user ID (used for encryption).
  final String recipientId;

  /// The plaintext content of the message.
  final String plaintext;

  /// The structural type of the message (text, image, etc.).
  final MessageType type;

  /// Optional ID of the message being quoted/replied to.
  ///
  /// Requirements: 4.8
  final String? quotedMessageId;

  /// Optional remote URL of an attached media file.
  final String? mediaUrl;

  /// Optional MIME category of the attached media file.
  final MediaType? mediaType;
}
