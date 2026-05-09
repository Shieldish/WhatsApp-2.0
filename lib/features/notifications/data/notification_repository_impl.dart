import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/notifications/data/fcm_handler.dart';
import 'package:whatsapp2_0/features/notifications/domain/notification_repository.dart';

/// Firestore-backed implementation of [NotificationRepository].
///
/// Manages FCM tokens, notification display via [FcmHandler], conversation
/// muting, and Do Not Disturb mode.
///
/// Requirements: 11.1–11.6
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required FlutterSecureStorage secureStorage,
    FcmHandler? fcmHandler,
  }) : _firestore = firestore,
       _messaging = messaging,
       _localNotifications = localNotifications,
       _secureStorage = secureStorage,
       _fcmHandler =
           fcmHandler ??
           FcmHandler(
             messaging: messaging,
             localNotifications: localNotifications,
             secureStorage: secureStorage,
           );

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  // ignore: unused_field
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FlutterSecureStorage _secureStorage;
  final FcmHandler _fcmHandler;

  static const String _dndKey = 'dnd_enabled';
  bool _dndEnabled = false;

  @override
  Future<Result<void, AppError>> initialize() async {
    return _fcmHandler.initialize();
  }

  @override
  Future<Result<void, AppError>> registerFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        return Ok(null);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': 'mobile',
            'createdAt': FieldValue.serverTimestamp(),
          });

      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'Failed to register FCM token: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> unregisterFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        return Ok(null);
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete();

      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'Failed to unregister FCM token: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> muteConversation({
    required String conversationId,
    required MuteDuration duration,
  }) async {
    try {
      DateTime mutedUntil;
      switch (duration) {
        case MuteDuration.hours8:
          mutedUntil = DateTime.now().add(const Duration(hours: 8));
        case MuteDuration.week1:
          mutedUntil = DateTime.now().add(const Duration(days: 7));
        case MuteDuration.always:
          mutedUntil = DateTime(2099, 12, 31);
      }

      await _firestore.collection('conversations').doc(conversationId).update({
        'mutedUntil': Timestamp.fromDate(mutedUntil),
      });

      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'Failed to mute conversation: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> unmuteConversation(
    String conversationId,
  ) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'mutedUntil': FieldValue.delete(),
      });

      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'Failed to unmute conversation: $e'));
    }
  }

  @override
  Future<void> dismissNotification(String conversationId) async {
    await _fcmHandler.dismissNotification(conversationId);
  }

  @override
  Future<Result<void, AppError>> setDoNotDisturb(bool enabled) async {
    try {
      _dndEnabled = enabled;
      await _secureStorage.write(key: _dndKey, value: enabled.toString());
      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'Failed to set DND: $e'));
    }
  }

  @override
  bool get isDoNotDisturbEnabled => _dndEnabled;

  @override
  Stream<NotificationAction> get notificationActions =>
      _fcmHandler.notificationActions;
}
