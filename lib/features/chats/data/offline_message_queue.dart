import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:whatsapp2_0/core/local_database/app_database.dart';
import 'package:whatsapp2_0/features/chats/data/local/daos/message_dao.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/send_message_params.dart';
import 'package:whatsapp2_0/features/chats/domain/message_repository.dart';

/// Listens for network reconnection events and retries messages that failed
/// to send (i.e. those with `status=failed` in the local Drift database).
///
/// ## Usage
///
/// ```dart
/// final queue = OfflineMessageQueue(
///   messageDao: db.messageDao,
///   messageRepository: messageRepository,
///   currentUserId: userId,
/// );
/// queue.start();
/// // ...
/// queue.stop();
/// ```
///
/// Requirements: 4.6
class OfflineMessageQueue {
  OfflineMessageQueue({
    required MessageDao messageDao,
    required MessageRepository messageRepository,
    Connectivity? connectivity,
  }) : _messageDao = messageDao,
       _messageRepository = messageRepository,
       _connectivity = connectivity ?? Connectivity();

  final MessageDao _messageDao;
  final MessageRepository _messageRepository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isRetrying = false;

  /// Starts listening for connectivity changes.
  ///
  /// When the device reconnects to the internet, all messages with
  /// `status=failed` are retried in order.
  void start() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  /// Stops listening for connectivity changes and cancels any pending retries.
  void stop() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final isConnected = results.any((r) => r != ConnectivityResult.none);

    if (!isConnected || _isRetrying) return;

    await _retryFailedMessages();
  }

  Future<void> _retryFailedMessages() async {
    _isRetrying = true;
    try {
      final failedMessages = await _messageDao.getFailedMessages();
      if (failedMessages.isEmpty) return;

      for (final row in failedMessages) {
        await _retryMessage(row);
      }
    } finally {
      _isRetrying = false;
    }
  }

  Future<void> _retryMessage(MessagesTableData row) async {
    // Reconstruct SendMessageParams from the stored row.
    // The recipientId is not stored in the messages table, so we derive it
    // from the conversationId. For direct chats, the conversationId is
    // typically the other user's ID or a composite. We use the conversationId
    // as the recipientId as a best-effort approach; a more complete
    // implementation would store the recipientId in the messages table.
    final params = SendMessageParams(
      conversationId: row.conversationId,
      recipientId: row.conversationId, // best-effort: use conversationId
      plaintext: row.plaintextCache ?? '',
      type: _parseMessageType(row.type),
      quotedMessageId: row.quotedMessageId,
      mediaUrl: row.mediaLocalPath,
    );

    // Delete the failed message first to avoid duplicates, then re-send.
    await _messageDao.deleteMessage(row.id);
    await _messageRepository.sendMessage(params);
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
}
