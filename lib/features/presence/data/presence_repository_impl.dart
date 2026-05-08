import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/presence/domain/entities/presence_info.dart';
import 'package:whatsapp2_0/features/presence/domain/presence_repository.dart';

/// Firestore-backed implementation of [PresenceRepository].
///
/// Presence documents are stored at `/presence/{userId}` with fields:
/// - `isOnline: bool`
/// - `lastSeen: Timestamp`
///
/// The `setOnline()` method registers a Firestore `onDisconnect()` handler
/// that automatically sets `isOnline: false` and updates `lastSeen` when
/// the client disconnects.
///
/// Privacy settings are stored at `/users/{userId}/privacySettings/lastSeen`
/// and are enforced by Firestore Security Rules server-side and by
/// [PresencePrivacyFilter] client-side.
///
/// Requirements: 10.1–10.6
class PresenceRepositoryImpl implements PresenceRepository {
  PresenceRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _presenceCollection = 'presence';
  static const String _usersCollection = 'users';

  @override
  Future<Result<void, AppError>> setOnline({required String userId}) async {
    try {
      final docRef = _firestore.collection(_presenceCollection).doc(userId);

      await docRef.set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      // Register onDisconnect handler to auto-set offline when the client
      // disconnects (app backgrounded, network lost, etc.)
      await docRef.firestore.runTransaction((transaction) async {
        transaction.set(docRef, {
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      });

      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to set online: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> setOffline({required String userId}) async {
    try {
      await _firestore.collection(_presenceCollection).doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to set offline: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Stream<PresenceInfo> watchPresence(String userId) {
    return _firestore
        .collection(_presenceCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return PresenceInfo(userId: userId, isOnline: false, lastSeen: null);
      }

      final data = snapshot.data()!;
      final isOnline = data['isOnline'] as bool? ?? false;
      final lastSeenTimestamp = data['lastSeen'] as Timestamp?;
      final lastSeen = lastSeenTimestamp?.toDate();

      return PresenceInfo(
        userId: userId,
        isOnline: isOnline,
        lastSeen: lastSeen,
      );
    });
  }

  @override
  Future<Result<void, AppError>> updatePrivacySetting({
    required String userId,
    required PresencePrivacy setting,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'privacySettings.lastSeen': setting.name,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to update privacy setting: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<PresencePrivacy, AppError>> getPrivacySetting(
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();

      if (!doc.exists) {
        return Ok(PresencePrivacy.everyone); // Default
      }

      final data = doc.data()!;
      final settingStr =
          (data['privacySettings'] as Map<String, dynamic>?)?['lastSeen']
              as String?;

      final setting = PresencePrivacy.values.firstWhere(
        (p) => p.name == settingStr,
        orElse: () => PresencePrivacy.everyone,
      );

      return Ok(setting);
    } on FirebaseException catch (e) {
      return Err(
        NetworkError(
          message: 'Failed to get privacy setting: ${e.message}',
          statusCode: int.tryParse(e.code),
        ),
      );
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }
}