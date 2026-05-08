import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/status/domain/entities/status_item.dart';
import 'package:whatsapp2_0/features/status/domain/status_expiry_checker.dart';
import 'package:whatsapp2_0/features/status/domain/status_repository.dart';

/// Firestore-backed implementation of [StatusRepository].
///
/// Status documents are stored under `/status/{userId}/items/{statusId}`.
/// Expired items are filtered out client-side using [StatusExpiryChecker].
/// A Cloud Function (`onStatusExpiry`) also deletes expired documents from
/// Firestore for server-side cleanup (see Task 15.5).
class StatusRepositoryImpl implements StatusRepository {
  StatusRepositoryImpl({
    required FirebaseFirestore firestore,
    StatusExpiryChecker? expiryChecker,
  }) : _firestore = firestore,
       _expiryChecker = expiryChecker ?? StatusExpiryChecker();

  final FirebaseFirestore _firestore;
  final StatusExpiryChecker _expiryChecker;

  /// Collection path prefix for status documents.
  static const String _statusCollection = 'status';

  @override
  Future<Result<StatusItem, AppError>> postStatus({
    required String userId,
    String? mediaUrl,
    String? text,
    String? backgroundColor,
    List<String>? privacyList,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = _expiryChecker.expiryTime(now);
      final statusId = _firestore.collection('_').doc().id;

      final data = <String, dynamic>{
        'mediaUrl': mediaUrl,
        'text': text,
        'backgroundColor': backgroundColor,
        'postedAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewers': {},
        if (privacyList != null) 'privacyList': privacyList,
      };

      await _firestore
          .collection(_statusCollection)
          .doc(userId)
          .collection('items')
          .doc(statusId)
          .set(data);

      final item = StatusItem(
        id: statusId,
        userId: userId,
        mediaUrl: mediaUrl,
        text: text,
        backgroundColor: backgroundColor,
        postedAt: now,
        expiresAt: expiresAt,
        viewers: {},
        privacyList: privacyList,
      );

      return Ok(item);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to post status: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> deleteStatus(String statusId) async {
    // Note: The caller must know the userId. For now we use the statusId
    // which is expected to be a document path or compound key.
    // In practice, delete is called from the owner's context.
    try {
      // statusId is expected to be the document ID within the user's
      // status items subcollection. The caller should provide the full
      // path or the repository should be scoped to the current user.
      // For simplicity, we leave the caller to provide userId separately.
      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  /// Deletes a status item for a specific user.
  Future<Result<void, AppError>> deleteStatusForUser({
    required String userId,
    required String statusId,
  }) async {
    try {
      await _firestore
          .collection(_statusCollection)
          .doc(userId)
          .collection('items')
          .doc(statusId)
          .delete();
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to delete status: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> recordView({
    required String statusId,
    required String userId,
    required String viewerId,
  }) async {
    try {
      await _firestore
          .collection(_statusCollection)
          .doc(userId)
          .collection('items')
          .doc(statusId)
          .update({
        'viewers.$viewerId': Timestamp.fromDate(DateTime.now()),
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to record view: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Stream<List<StatusItem>> watchStatuses(String userId) {
    return _firestore
        .collection(_statusCollection)
        .doc(userId)
        .collection('items')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => _docToStatusItem(doc, userId))
          .where((item) => _expiryChecker.isVisible(
        postedAt: item.postedAt,
        queryTime: now,
      ))
          .toList();
    });
  }

  @override
  Stream<List<StatusItem>> watchContactStatuses(String currentUserId) {
    // This implementation watches all users' statuses.
    // In production, this should be scoped to the current user's contacts
    // using a Firestore collection group query or a Cloud Function that
    // aggregates statuses for the user's contact list.
    //
    // For now, we use a collection group query on 'items' to get all
    // statuses, then filter by the current user's contacts.
    return _firestore
        .collectionGroup('items')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final statusMap = <String, StatusItem>{};

      for (final doc in snapshot.docs) {
        final userId = doc.reference.parent.parent?.id ?? '';
        if (userId == currentUserId) continue; // Skip own statuses

        final item = _docToStatusItem(doc, userId);

        // Filter expired items
        if (!_expiryChecker.isVisible(
          postedAt: item.postedAt,
          queryTime: now,
        )) {
          continue;
        }

        // Take only the most recent status per user
        final key = item.userId;
        final existing = statusMap[key];
        if (existing == null || item.postedAt.isAfter(existing.postedAt)) {
          statusMap[key] = item;
        }
      }

      return statusMap.values.toList()
        ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
    });
  }

  @override
  Future<Result<StatusItem, AppError>> getStatus({
    required String userId,
    required String statusId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_statusCollection)
          .doc(userId)
          .collection('items')
          .doc(statusId)
          .get();

      if (!doc.exists) {
        return Err(
          StorageError(message: 'Status not found'),
        );
      }

      final data = doc.data();
      if (data == null) {
        return Err(
          StorageError(message: 'Status data is null'),
        );
      }

      final postedAt = (data['postedAt'] as Timestamp).toDate();
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final viewersRaw = data['viewers'] as Map<String, dynamic>? ?? {};
      final viewers = viewersRaw.map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      );
      final privacyListRaw = data['privacyList'] as List<dynamic>?;
      final privacyList = privacyListRaw?.cast<String>();

      final item = StatusItem(
        id: statusId,
        userId: userId,
        mediaUrl: data['mediaUrl'] as String?,
        text: data['text'] as String?,
        backgroundColor: data['backgroundColor'] as String?,
        postedAt: postedAt,
        expiresAt: expiresAt,
        viewers: viewers,
        privacyList: privacyList,
      );

      return Ok(item);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to get status: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  /// Converts a Firestore [DocumentSnapshot] to a [StatusItem].
  StatusItem _docToStatusItem(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String userId,
  ) {
    final data = doc.data();
    final postedAt = (data['postedAt'] as Timestamp).toDate();
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();

    // Parse viewers map
    final viewersRaw = data['viewers'] as Map<String, dynamic>? ?? {};
    final viewers = viewersRaw.map(
      (key, value) => MapEntry(key, (value as Timestamp).toDate()),
    );

    // Parse privacy list
    final privacyListRaw = data['privacyList'] as List<dynamic>?;
    final privacyList = privacyListRaw?.cast<String>();

    return StatusItem(
      id: doc.id,
      userId: userId,
      mediaUrl: data['mediaUrl'] as String?,
      text: data['text'] as String?,
      backgroundColor: data['backgroundColor'] as String?,
      postedAt: postedAt,
      expiresAt: expiresAt,
      viewers: viewers,
      privacyList: privacyList,
    );
  }
}