import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/core/encryption/encryption_service.dart';
import 'package:whatsapp2_0/core/encryption/key_manager.dart';
import 'package:whatsapp2_0/core/encryption/signal_encryption_service.dart';
import 'package:whatsapp2_0/core/encryption/signal_protocol_store.dart';
import 'package:whatsapp2_0/features/chats/presentation/providers/chat_providers.dart';

/// Provides the [DriftSignalProtocolStore] backed by the app database.
final signalProtocolStoreProvider = Provider<DriftSignalProtocolStore>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftSignalProtocolStore(database: db);
});

/// Provides the [KeyManager] wired to the Signal Protocol store.
final keyManagerProvider = Provider<KeyManager>((ref) {
  final store = ref.watch(signalProtocolStoreProvider);
  return KeyManager(store: store);
});

/// Provides the [EncryptionService] implementation.
///
/// Uses the current Firebase Auth user ID as the local user ID. Falls back to
/// an empty string if no user is signed in (should not happen in normal usage).
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  final store = ref.watch(signalProtocolStoreProvider);
  final keyManager = ref.watch(keyManagerProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  final localUserId = currentUser?.uid ?? '';

  return SignalEncryptionService(
    keyManager: keyManager,
    store: store,
    localUserId: localUserId,
  );
});
