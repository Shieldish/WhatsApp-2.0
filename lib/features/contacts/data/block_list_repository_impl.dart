import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/contacts/domain/block_list_repository.dart';

/// Firestore-backed implementation of [BlockListRepository].
///
/// Block data is stored at:
///   `/users/{currentUserId}/blockedUsers/{targetUserId}`
///
/// Firestore Security Rules (configured separately) enforce that blocked users
/// cannot write messages to the blocking user's conversation.
///
/// Requirements: 2.5
class BlockListRepositoryImpl implements BlockListRepository {
  BlockListRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the reference to the blocked-users sub-collection for [userId].
  CollectionReference<Map<String, dynamic>> _blockedUsersRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('blockedUsers');
  }

  // ---------------------------------------------------------------------------
  // BlockListRepository
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> blockUser(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      await _blockedUsersRef(
        currentUserId,
      ).doc(targetUserId).set({'blockedAt': FieldValue.serverTimestamp()});
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: e.message ?? 'Failed to block user.',
          statusCode: null,
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: 'Failed to block user.', cause: e));
    }
  }

  @override
  Future<Result<void, AppError>> unblockUser(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      await _blockedUsersRef(currentUserId).doc(targetUserId).delete();
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: e.message ?? 'Failed to unblock user.',
          statusCode: null,
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: 'Failed to unblock user.', cause: e));
    }
  }

  @override
  Future<bool> isBlocked(String currentUserId, String targetUserId) async {
    try {
      final doc = await _blockedUsersRef(currentUserId).doc(targetUserId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<List<String>> watchBlockedUsers(String currentUserId) {
    return _blockedUsersRef(currentUserId).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
    );
  }
}
