import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/core/encryption/providers/encryption_providers.dart';
import 'package:whatsapp2_0/core/local_database/app_database.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/data/conversation_repository_impl.dart';
import 'package:whatsapp2_0/features/chats/data/delivery_receipt_repository_impl.dart';
import 'package:whatsapp2_0/features/chats/data/group_repository_impl.dart';
import 'package:whatsapp2_0/features/chats/data/message_repository_impl.dart';
import 'package:whatsapp2_0/features/chats/domain/conversation_repository.dart';
import 'package:whatsapp2_0/features/chats/domain/delivery_receipt_repository.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/search_result.dart';
import 'package:whatsapp2_0/features/chats/domain/group_repository.dart';
import 'package:whatsapp2_0/features/chats/domain/message_repository.dart';

// ---------------------------------------------------------------------------
// Database provider
// ---------------------------------------------------------------------------

/// Provides the singleton [AppDatabase] instance.
///
/// Kept as a simple [Provider] so it can be overridden in tests with an
/// in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

/// Provides the [ConversationRepository] implementation backed by Drift.
///
/// Requirements: 3.1, 3.2, 3.4, 3.5, 3.6
final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ConversationRepositoryImpl(
    conversationDao: db.conversationDao,
    messageDao: db.messageDao,
  );
});

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

/// Emits the list of non-archived conversations sorted by most-recent-first.
///
/// Requirements: 3.1, 3.2
final conversationsStreamProvider = StreamProvider<List<Conversation>>((ref) {
  return ref.watch(conversationRepositoryProvider).watchConversations();
});

/// Emits the list of archived conversations sorted by most-recent-first.
///
/// Requirements: 3.4
final archivedConversationsStreamProvider = StreamProvider<List<Conversation>>((
  ref,
) {
  return ref.watch(conversationRepositoryProvider).watchArchivedConversations();
});

// ---------------------------------------------------------------------------
// Search provider
// ---------------------------------------------------------------------------

/// Executes a full-text search for [query] and returns matching [SearchResult]
/// items.
///
/// Returns an empty list when [query] is blank.
///
/// Requirements: 3.6
final searchProvider = FutureProvider.family<List<SearchResult>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return const [];

  final repo = ref.watch(conversationRepositoryProvider);
  final result = await repo.search(query);

  return switch (result) {
    Ok(:final value) => value,
    Err() => const [],
  };
});

// ---------------------------------------------------------------------------
// Message repository provider
// ---------------------------------------------------------------------------

/// Provides the [MessageRepository] implementation backed by Drift and
/// Firestore.
///
/// Requirements: 4.1, 4.3, 4.4, 4.5, 4.6, 4.7, 4.9
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final encryptionService = ref.watch(encryptionServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  final currentUserId = currentUser?.uid ?? '';

  return MessageRepositoryImpl(
    messageDao: db.messageDao,
    conversationDao: db.conversationDao,
    encryptionService: encryptionService,
    currentUserId: currentUserId,
  );
});

// ---------------------------------------------------------------------------
// Messages stream provider
// ---------------------------------------------------------------------------

/// Emits the ordered list of messages for [conversationId] whenever the
/// underlying data changes.
///
/// Requirements: 4.1
final messagesStreamProvider = StreamProvider.family<List<Message>, String>((
  ref,
  conversationId,
) {
  return ref.watch(messageRepositoryProvider).watchMessages(conversationId);
});

// ---------------------------------------------------------------------------
// Group repository provider
// ---------------------------------------------------------------------------

/// Provides the [GroupRepository] implementation backed by Firestore.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.8
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl();
});

// ---------------------------------------------------------------------------
// Delivery receipt repository provider
// ---------------------------------------------------------------------------

/// Provides the [DeliveryReceiptRepository] implementation backed by Firestore.
///
/// Requirements: 5.7
final deliveryReceiptRepositoryProvider = Provider<DeliveryReceiptRepository>((
  ref,
) {
  return DeliveryReceiptRepositoryImpl();
});
