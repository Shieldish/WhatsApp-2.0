import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/search_result.dart';

/// Abstract interface for the conversation repository.
///
/// Provides reactive streams for the chat list and archived chats, as well as
/// mutation operations (archive, unarchive, delete) and full-text search over
/// messages.
///
/// Requirements: 3.1, 3.2, 3.4, 3.5, 3.6
abstract class ConversationRepository {
  /// Emits the list of non-archived conversations sorted by [lastMessageAt]
  /// descending (most recent first) whenever the underlying data changes.
  ///
  /// Requirements: 3.1, 3.2
  Stream<List<Conversation>> watchConversations();

  /// Emits the list of archived conversations sorted by [lastMessageAt]
  /// descending whenever the underlying data changes.
  ///
  /// Requirements: 3.4
  Stream<List<Conversation>> watchArchivedConversations();

  /// Archives the conversation with the given [id].
  ///
  /// Returns [Ok] on success or [Err] with a [StorageError] on failure.
  ///
  /// Requirements: 3.4
  Future<Result<void, AppError>> archiveConversation(String id);

  /// Unarchives the conversation with the given [id].
  ///
  /// Returns [Ok] on success or [Err] with a [StorageError] on failure.
  ///
  /// Requirements: 3.4
  Future<Result<void, AppError>> unarchiveConversation(String id);

  /// Deletes the conversation with the given [id] and all its messages.
  ///
  /// Returns [Ok] on success or [Err] with a [StorageError] on failure.
  ///
  /// Requirements: 3.5
  Future<Result<void, AppError>> deleteConversation(String id);

  /// Searches conversations and messages by [query] using FTS5 full-text
  /// search.
  ///
  /// Returns a list of [SearchResult] items sorted by relevance / recency.
  /// Returns an empty list when [query] is blank.
  ///
  /// Requirements: 3.6
  Future<Result<List<SearchResult>, AppError>> search(String query);
}
