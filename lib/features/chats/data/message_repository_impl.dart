import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:whatsapp2_0/core/encryption/encryption_service.dart';
import 'package:whatsapp2_0/core/local_database/app_database.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/data/local/daos/conversation_dao.dart';
import 'package:whatsapp2_0/features/chats/data/local/daos/message_dao.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/send_message_params.dart';
import 'package:whatsapp2_0/features/chats/domain/message_repository.dart';

/// Concrete implementation of [MessageRepository] backed by Drift (local) and
/// Firestore (remote).
///
/// ## Send flow
/// 1. Generate a UUID-like message ID.
/// 2. INSERT into Drift with `status=sending`.
/// 3. Encrypt plaintext via [EncryptionService.encryptMessage].
/// 4. Write encrypted document to Firestore.
/// 5. UPDATE Drift status to `sent`.
/// On any failure, status is set to `failed`.
///
/// ## Delivery receipts
/// A Firestore snapshot listener on `/conversations/{id}/messages` updates
/// `deliveredAt` and `readAt` in Drift whenever the remote document changes.
///
/// Requirements: 4.1, 4.3, 4.4, 4.5, 4.6, 4.7, 4.9
class MessageRepositoryImpl implements MessageRepository {
  MessageRepositoryImpl({
    required MessageDao messageDao,
    required ConversationDao conversationDao,
    required EncryptionService encryptionService,
    required String currentUserId,
    FirebaseFirestore? firestore,
  }) : _messageDao = messageDao,
       _conversationDao = conversationDao,
       _encryptionService = encryptionService,
       _currentUserId = currentUserId,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final MessageDao _messageDao;
  final ConversationDao _conversationDao;
  final EncryptionService _encryptionService;
  final String _currentUserId;
  final FirebaseFirestore _firestore;

  /// Active Firestore listeners keyed by conversationId.
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _listeners = {};

  // ---------------------------------------------------------------------------
  // sendMessage
  // ---------------------------------------------------------------------------

  @override
  Future<Result<Message, AppError>> sendMessage(
    SendMessageParams params,
  ) async {
    final messageId = _generateMessageId();
    final now = DateTime.now();

    // Build the initial domain entity.
    final message = Message(
      id: messageId,
      conversationId: params.conversationId,
      senderId: _currentUserId,
      plaintext: params.plaintext,
      mediaUrl: params.mediaUrl,
      mediaType: params.mediaType,
      type: params.type,
      sentAt: now,
      status: DeliveryStatus.sending,
      deletedForEveryone: false,
      quotedMessageId: params.quotedMessageId,
    );

    // 1. INSERT into Drift with status=sending.
    try {
      await _messageDao.insertMessage(
        MessagesTableCompanion(
          id: Value(messageId),
          conversationId: Value(params.conversationId),
          senderId: Value(_currentUserId),
          ciphertext: Value(Uint8List(0)), // placeholder until encrypted
          plaintextCache: Value(params.plaintext),
          type: Value(_messageTypeToString(params.type)),
          sentAt: Value(now.millisecondsSinceEpoch),
          status: Value('sending'),
          deletedForEveryone: const Value(false),
          quotedMessageId: Value(params.quotedMessageId),
          mediaLocalPath: Value(params.mediaUrl),
        ),
      );
    } catch (e) {
      return Err(StorageError(message: 'Failed to save message locally: $e'));
    }

    // 2. Encrypt the plaintext.
    final encryptResult = await _encryptionService.encryptMessage(
      params.recipientId,
      params.plaintext,
    );

    if (encryptResult.isErr) {
      await _messageDao.updateMessageStatus(messageId, 'failed');
      return Err(encryptResult.errorOrNull!);
    }

    final ciphertext = encryptResult.valueOrNull!;

    // 3. Write to Firestore.
    try {
      await _firestore
          .collection('conversations')
          .doc(params.conversationId)
          .collection('messages')
          .doc(messageId)
          .set({
            'senderId': _currentUserId,
            'ciphertext': ciphertext,
            'type': _messageTypeToString(params.type),
            'sentAt': Timestamp.fromDate(now),
            'deliveredAt': null,
            'readAt': null,
            'deletedForEveryone': false,
            'quotedMessageId': params.quotedMessageId,
            'mediaUrl': params.mediaUrl,
            'mediaType': params.mediaType != null
                ? _mediaTypeToString(params.mediaType!)
                : null,
          });
    } catch (e) {
      await _messageDao.updateMessageStatus(messageId, 'failed');
      return Err(NetworkError(message: 'Failed to send message to server: $e'));
    }

    // 4. Update Drift status to sent.
    try {
      await _messageDao.updateMessageStatus(messageId, 'sent');

      // Also update the conversation's last message preview.
      await _conversationDao.updateLastMessage(
        params.conversationId,
        params.plaintext,
        now.millisecondsSinceEpoch,
      );
    } catch (e) {
      // Non-fatal — message was delivered, just local state update failed.
    }

    return Ok(message.copyWith(status: DeliveryStatus.sent));
  }

  // ---------------------------------------------------------------------------
  // watchMessages
  // ---------------------------------------------------------------------------

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _messageDao
        .watchMessages(conversationId)
        .map((rows) => rows.map(_mapRow).toList());
  }

  // ---------------------------------------------------------------------------
  // deleteMessageForMe
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> deleteMessageForMe(String messageId) async {
    try {
      await _messageDao.deleteMessage(messageId);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to delete message: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // deleteMessageForEveryone
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> deleteMessageForEveryone(
    String messageId,
    DateTime sentAt,
  ) async {
    // Check the 60-minute window.
    final elapsed = DateTime.now().difference(sentAt);
    if (elapsed > const Duration(minutes: 60)) {
      return Err(
        ValidationError(
          message:
              'Cannot delete for everyone: more than 60 minutes have passed since the message was sent.',
        ),
      );
    }

    // Fetch the message to get the conversationId.
    final row = await _messageDao.getMessageById(messageId);
    if (row == null) {
      return Err(StorageError(message: 'Message not found: $messageId'));
    }

    // Write deletedForEveryone=true to Firestore.
    try {
      await _firestore
          .collection('conversations')
          .doc(row.conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'deletedForEveryone': true});
    } catch (e) {
      return Err(
        NetworkError(message: 'Failed to delete message on server: $e'),
      );
    }

    // Update local Drift record.
    try {
      await _messageDao.updateMessage(
        MessagesTableCompanion(
          id: Value(messageId),
          plaintextCache: const Value('This message was deleted'),
          deletedForEveryone: const Value(true),
        ),
      );
      return const Ok(null);
    } catch (e) {
      return Err(
        StorageError(message: 'Failed to update local message state: $e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // markAsRead
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> markAsRead(String conversationId) async {
    final now = DateTime.now();

    // Write readAt to Firestore for all messages not sent by the current user.
    try {
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _currentUserId)
          .where('readAt', isNull: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'readAt': Timestamp.fromDate(now)});
      }
      await batch.commit();
    } catch (e) {
      // Non-fatal — continue to reset local unread count.
    }

    // Reset unread count in Drift.
    try {
      await _conversationDao.resetUnreadCount(conversationId);
      return const Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to reset unread count: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // startDeliveryReceiptListener
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> startDeliveryReceiptListener(
    String conversationId,
  ) async {
    // Cancel any existing listener for this conversation.
    await stopDeliveryReceiptListener(conversationId);

    try {
      final subscription = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .snapshots()
          .listen((snapshot) async {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.modified ||
                  change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data == null) continue;

                final messageId = change.doc.id;

                // Extract timestamps.
                final deliveredAtTs = data['deliveredAt'] as Timestamp?;
                final readAtTs = data['readAt'] as Timestamp?;
                final deletedForEveryone =
                    data['deletedForEveryone'] as bool? ?? false;

                // Update delivery timestamps in Drift.
                await _messageDao.updateDeliveryTimestamps(
                  id: messageId,
                  deliveredAt: deliveredAtTs?.millisecondsSinceEpoch,
                  readAt: readAtTs?.millisecondsSinceEpoch,
                );

                // Handle delete-for-everyone updates from remote.
                if (deletedForEveryone) {
                  final row = await _messageDao.getMessageById(messageId);
                  if (row != null &&
                      row.plaintextCache != 'This message was deleted') {
                    await _messageDao.updateMessage(
                      MessagesTableCompanion(
                        id: Value(messageId),
                        plaintextCache: const Value('This message was deleted'),
                        deletedForEveryone: const Value(true),
                      ),
                    );
                  }
                }

                // Update delivery status based on timestamps.
                if (readAtTs != null) {
                  await _messageDao.updateMessageStatus(messageId, 'read');
                } else if (deliveredAtTs != null) {
                  await _messageDao.updateMessageStatus(messageId, 'delivered');
                }
              }
            }
          });

      _listeners[conversationId] = subscription;
      return const Ok(null);
    } catch (e) {
      return Err(
        NetworkError(message: 'Failed to start delivery receipt listener: $e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // stopDeliveryReceiptListener
  // ---------------------------------------------------------------------------

  @override
  Future<void> stopDeliveryReceiptListener(String conversationId) async {
    final subscription = _listeners.remove(conversationId);
    await subscription?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  /// Maps a [MessagesTableData] row to a [Message] domain entity.
  static Message _mapRow(MessagesTableData row) {
    return Message(
      id: row.id,
      conversationId: row.conversationId,
      senderId: row.senderId,
      plaintext: row.plaintextCache,
      mediaUrl: row.mediaLocalPath,
      mediaType: null, // not stored separately in current schema
      type: _parseMessageType(row.type),
      sentAt: DateTime.fromMillisecondsSinceEpoch(row.sentAt),
      deliveredAt: row.deliveredAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deliveredAt!)
          : null,
      readAt: row.readAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.readAt!)
          : null,
      status: _parseDeliveryStatus(row.status),
      deletedForEveryone: row.deletedForEveryone,
      quotedMessageId: row.quotedMessageId,
    );
  }

  static MessageType _parseMessageType(String type) {
    return switch (type) {
      'image' => MessageType.image,
      'video' => MessageType.video,
      'audio' => MessageType.audio,
      'document' => MessageType.document,
      'location' => MessageType.location,
      'system' => MessageType.system,
      _ => MessageType.text,
    };
  }

  static String _messageTypeToString(MessageType type) {
    return switch (type) {
      MessageType.image => 'image',
      MessageType.video => 'video',
      MessageType.audio => 'audio',
      MessageType.document => 'document',
      MessageType.location => 'location',
      MessageType.system => 'system',
      MessageType.text => 'text',
    };
  }

  static String _mediaTypeToString(MediaType type) {
    return switch (type) {
      MediaType.image => 'image',
      MediaType.video => 'video',
      MediaType.audio => 'audio',
      MediaType.document => 'document',
    };
  }

  static DeliveryStatus _parseDeliveryStatus(String status) {
    return switch (status) {
      'sent' => DeliveryStatus.sent,
      'delivered' => DeliveryStatus.delivered,
      'read' => DeliveryStatus.read,
      'failed' => DeliveryStatus.failed,
      _ => DeliveryStatus.sending,
    };
  }

  /// Generates a unique message ID using the current timestamp and a random
  /// suffix.
  static String _generateMessageId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${ts}_$rand';
  }
}
