import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../../features/chats/data/local/daos/message_dao.dart';
import '../local_database/app_database.dart';
import 'signal_protocol_store.dart';

/// Watches Firestore for key bundle changes on contacts and injects a
/// "Security code changed" system message into the local conversation when
/// a contact's identity key changes.
///
/// ## Behaviour
///
/// For each watched contact, a Firestore snapshot listener monitors the
/// `/users/{contactId}` document. When the `publicKeyBundle.identityKey`
/// field changes relative to the trusted identity key stored in
/// [DriftSignalProtocolStore], this notifier:
///
/// 1. Injects a [MessageType.system] message with text "Security code changed"
///    into the local conversation via [MessageDao].
/// 2. Updates the trusted identity key in [DriftSignalProtocolStore] via
///    [saveIdentity] so subsequent messages are trusted.
///
/// ## First contact
///
/// If no trusted identity key exists yet for a contact (first contact), no
/// notification is injected — the key is simply stored as trusted.
class KeyChangeNotifier {
  KeyChangeNotifier({
    required DriftSignalProtocolStore store,
    required MessageDao messageDao,
    FirebaseFirestore? firestore,
  }) : _store = store,
       _messageDao = messageDao,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final DriftSignalProtocolStore _store;
  final MessageDao _messageDao;
  final FirebaseFirestore _firestore;

  /// Active Firestore listeners keyed by contactId.
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
  _subscriptions = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Starts listening for key bundle changes for [contactId].
  ///
  /// When a key change is detected, a "Security code changed" system message
  /// is injected into the conversation identified by [conversationId].
  ///
  /// Calling this method again for the same [contactId] replaces the existing
  /// listener.
  void watchContact(String contactId, String conversationId) {
    _subscriptions[contactId]?.cancel();

    final docRef = _firestore.collection('users').doc(contactId);

    final subscription = docRef.snapshots().listen(
      (snapshot) => _onSnapshot(snapshot, contactId, conversationId),
      onError: (Object error) {
        // Silently ignore listener errors — key-change detection is
        // best-effort and should not crash the app.
      },
    );

    _subscriptions[contactId] = subscription;
  }

  /// Stops listening for key bundle changes for [contactId].
  void stopWatching(String contactId) {
    _subscriptions.remove(contactId)?.cancel();
  }

  /// Cancels all active listeners and releases resources.
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _onSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    String contactId,
    String conversationId,
  ) async {
    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null) return;

    final bundleData = data['publicKeyBundle'];
    if (bundleData == null) return;

    final bundleMap = bundleData as Map<String, dynamic>;
    final identityKeyBase64 = bundleMap['identityKey'] as String?;
    if (identityKeyBase64 == null) return;

    IdentityKey incomingIdentityKey;
    try {
      final identityKeyBytes = base64.decode(identityKeyBase64);
      incomingIdentityKey = IdentityKey.fromBytes(
        Uint8List.fromList(identityKeyBytes),
        0,
      );
    } on Exception {
      return;
    }

    final address = SignalProtocolAddress(contactId, 1);
    final storedIdentityKey = await _store.getIdentity(address);

    if (storedIdentityKey == null) {
      // First contact — store the key as trusted without injecting a
      // notification (no prior key to compare against).
      await _store.saveIdentity(address, incomingIdentityKey);
      return;
    }

    if (storedIdentityKey == incomingIdentityKey) {
      return;
    }

    // Key has changed — inject a system message and update the trusted key.
    await _injectKeyChangeMessage(conversationId);
    await _store.saveIdentity(address, incomingIdentityKey);
  }

  /// Inserts a "Security code changed" system message into the local
  /// conversation identified by [conversationId].
  Future<void> _injectKeyChangeMessage(String conversationId) async {
    final id = _generateMessageId();
    final now = DateTime.now();

    await _messageDao.insertMessage(
      MessagesTableCompanion.insert(
        id: id,
        conversationId: conversationId,
        senderId: 'system',
        ciphertext: Uint8List(0),
        type: 'system',
        sentAt: now.millisecondsSinceEpoch,
        deletedForEveryone: const Value(false),
        status: 'read',
        plaintextCache: const Value('Security code changed'),
      ),
    );
  }

  /// Generates a unique message ID using the current timestamp and a random
  /// suffix (avoids a `uuid` package dependency).
  String _generateMessageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure().nextInt(0xFFFFFF);
    return 'sys_${timestamp}_${random.toRadixString(16)}';
  }
}
