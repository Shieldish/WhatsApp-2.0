import 'package:whatsapp2_0/core/result.dart';

/// Abstract interface for managing the current user's block list.
///
/// Blocked users cannot appear in the contact list and cannot send messages
/// to the blocking user.
///
/// Requirements: 2.5
abstract class BlockListRepository {
  /// Blocks [targetUserId] for [currentUserId].
  ///
  /// Writes to Firestore `/users/{currentUserId}/blockedUsers/{targetUserId}`
  /// with a `blockedAt` timestamp.
  ///
  /// Returns [Ok(null)] on success, or [Err(AppError)] on failure.
  Future<Result<void, AppError>> blockUser(
    String currentUserId,
    String targetUserId,
  );

  /// Unblocks [targetUserId] for [currentUserId].
  ///
  /// Deletes the document at
  /// `/users/{currentUserId}/blockedUsers/{targetUserId}`.
  ///
  /// Returns [Ok(null)] on success, or [Err(AppError)] on failure.
  Future<Result<void, AppError>> unblockUser(
    String currentUserId,
    String targetUserId,
  );

  /// Returns `true` if [currentUserId] has blocked [targetUserId].
  ///
  /// Checks whether the document at
  /// `/users/{currentUserId}/blockedUsers/{targetUserId}` exists.
  Future<bool> isBlocked(String currentUserId, String targetUserId);

  /// Streams the list of user IDs blocked by [currentUserId].
  ///
  /// Emits a new list whenever the blocked-users sub-collection changes.
  Stream<List<String>> watchBlockedUsers(String currentUserId);
}
