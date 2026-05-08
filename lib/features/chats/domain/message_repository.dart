import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/send_message_params.dart';

/// Abstract interface for message persistence and delivery operations.
///
/// Implementations back this interface with Drift (local) and Firestore
/// (remote) to provide an offline-first messaging experience.
///
/// Requirements: 4.1, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9
abstract class MessageRepository {
  /// Sends a new message.
  ///
  /// The implementation:
  /// 1. Inserts the message locally with `status=sending`.
  /// 2. Encrypts the plaintext using [EncryptionService].
  /// 3. Writes the encrypted message to Firestore.
  /// 4. Updates the local status to `sent`.
  ///
  /// On any failure, the local status is updated to `failed` so the offline
  /// queue can retry later.
  ///
  /// Requirements: 4.1, 4.6
  Future<Result<Message, AppError>> sendMessage(SendMessageParams params);

  /// Returns a reactive stream of messages for [conversationId], ordered by
  /// [sentAt] ascending (oldest first).
  ///
  /// Backed by a Drift reactive query so the stream emits whenever the
  /// underlying data changes.
  ///
  /// Requirements: 4.1
  Stream<List<Message>> watchMessages(String conversationId);

  /// Deletes a message from the local Drift database only.
  ///
  /// The message remains visible to other participants.
  ///
  /// Requirements: 4.7
  Future<Result<void, AppError>> deleteMessageForMe(String messageId);

  /// Deletes a message for all participants.
  ///
  /// Only allowed within 60 minutes of [sentAt]. Writes
  /// `deletedForEveryone=true` to Firestore and replaces the local
  /// [plaintextCache] with "This message was deleted".
  ///
  /// Returns [Err(ValidationError)] if the 60-minute window has passed.
  ///
  /// Requirements: 4.7, 4.9
  Future<Result<void, AppError>> deleteMessageForEveryone(
    String messageId,
    DateTime sentAt,
  );

  /// Marks all messages in [conversationId] as read.
  ///
  /// Writes `readAt` timestamps to Firestore for all unread messages and
  /// resets the unread count in Drift.
  ///
  /// Requirements: 4.4, 4.5
  Future<Result<void, AppError>> markAsRead(String conversationId);

  /// Starts a Firestore snapshot listener for messages in [conversationId].
  ///
  /// The listener updates `deliveredAt` and `readAt` in Drift whenever the
  /// remote document changes.
  ///
  /// Requirements: 4.3, 4.4, 4.5
  Future<Result<void, AppError>> startDeliveryReceiptListener(
    String conversationId,
  );

  /// Cancels the Firestore snapshot listener for [conversationId].
  Future<void> stopDeliveryReceiptListener(String conversationId);
}
