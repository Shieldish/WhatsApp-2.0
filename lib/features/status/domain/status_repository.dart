import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/status/domain/entities/status_item.dart';

/// Abstract interface for status (stories) operations.
///
/// Statuses are ephemeral — they expire 24 hours after posting. The repository
/// handles creation, deletion, viewing, and feed retrieval.
abstract class StatusRepository {
  /// Posts a new status item.
  ///
  /// Writes to `/status/{userId}/items/{statusId}` with [expiresAt] set to
  /// [postedAt] + 24h. Returns the created [StatusItem] on success.
  Future<Result<StatusItem, AppError>> postStatus({
    required String userId,
    String? mediaUrl,
    String? text,
    String? backgroundColor,
    List<String>? privacyList,
  });

  /// Deletes the status with the given [statusId] for the current user.
  ///
  /// Only the owner may delete a status. This removes the document from
  /// Firestore immediately.
  Future<Result<void, AppError>> deleteStatus(String statusId);

  /// Records that [viewerId] has viewed [statusId] at the current time.
  ///
  /// Writes the viewer's userId and timestamp to the `viewers` map on the
  /// status document in Firestore.
  Future<Result<void, AppError>> recordView({
    required String statusId,
    required String userId,
    required String viewerId,
  });

  /// Returns a stream of active (non-expired) status items for the given
  /// [userId].
  ///
  /// Expired items are filtered out client-side by checking [expiresAt]
  /// against the current time.
  Stream<List<StatusItem>> watchStatuses(String userId);

  /// Returns a stream of all active statuses from the user's contacts.
  ///
  /// Each list represents the current set of non-expired statuses visible
  /// to the user. The list is updated reactively when new statuses are
  /// posted, expire, or are deleted.
  Stream<List<StatusItem>> watchContactStatuses(String currentUserId);

  /// Fetches a single [StatusItem] by its composite key.
  Future<Result<StatusItem, AppError>> getStatus({
    required String userId,
    required String statusId,
  });
}