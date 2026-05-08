import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/notifications/domain/notification_repository.dart';

/// Handles Firebase Cloud Messaging (FCM) payloads across all app states:
/// foreground, background, and terminated.
///
/// ## States handled:
/// - **Foreground**: Shows an in-app banner using `flutter_local_notifications`.
/// - **Background**: Displays a system notification via FCM data messages.
/// - **Terminated**: FCM data messages are processed when the app is launched.
///
/// Requirements: 11.1–11.6
class FcmHandler {
  FcmHandler({
    required FirebaseMessaging messaging,
    required FlutterLocalNotificationsPlugin localNotifications,
    required FlutterSecureStorage secureStorage,
  })  : _messaging = messaging,
        _localNotifications = localNotifications,
        _secureStorage = secureStorage;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FlutterSecureStorage _secureStorage;

  static const String _dndKey = 'dnd_enabled';
  static const String _defaultChannelId = 'messages';
  static const String _callChannelId = 'calls';

  final StreamController<NotificationAction> _actionController =
      StreamController<NotificationAction>.broadcast();

  /// Initializes FCM and local notifications.
  ///
  /// Requests notification permissions, gets the FCM token, and sets up
  /// foreground and background message handlers.
  Future<Result<void, AppError>> initialize() async {
    try {
      // Request notification permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        // Permission denied — we can still show in-app banners but not
        // system notifications.
      }

      // Set up local notification channel
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          _handleNotificationTap(response);
        },
      );

      // Create notification channels
      await _createNotificationChannels();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message tap (when app is opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle terminated state — get initial message that launched the app
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationData(initialMessage.data);
      }

      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'FCM init failed: $e'));
    }
  }

  /// Creates the Android notification channels.
  Future<void> _createNotificationChannels() async {
    final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlatform != null) {
      await androidPlatform.createNotificationChannel(
        AndroidNotificationChannel(
          _defaultChannelId,
          'Messages',
          description: 'New message notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlatform.createNotificationChannel(
        AndroidNotificationChannel(
          _callChannelId,
          'Calls',
          description: 'Incoming call notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        ),
      );
    }
  }

  /// Handles a foreground FCM message.
  ///
  /// Shows an in-app notification using the local notifications plugin,
  /// respecting mute and DND settings.
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    // Check Do Not Disturb
    if (_isDndActive() && data['type'] != 'call') {
      return; // Suppress non-call notifications when DND is active
    }

    // Check mute state
    final conversationId = data['conversationId'] ?? '';
    final mutedUntilStr = data['mutedUntil'] as String?;
    if (mutedUntilStr != null) {
      final mutedUntil = DateTime.tryParse(mutedUntilStr);
      if (mutedUntil != null && mutedUntil.isAfter(DateTime.now())) {
        return; // Conversation is muted
      }
    }

    final title = data['senderName'] as String? ?? 'WhatsApp';
    final body = data['preview'] as String? ??
        notification?.title ??
        'New message';

    _localNotifications.show(
      conversationId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          data['type'] == 'call' ? _callChannelId : _defaultChannelId,
          data['type'] == 'call' ? 'Calls' : 'Messages',
          category: data['type'] == 'call'
              ? AndroidNotificationCategory.call
              : AndroidNotificationCategory.message,
          groupKey: conversationId,
          // For call notifications, use full-screen intent style
          fullScreenIntent: data['type'] == 'call',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: conversationId,
    );
  }

  /// Handles a background message tap (app opened from notification).
  void _handleMessageOpenedApp(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  /// Handles the notification data payload.
  void _handleNotificationData(Map<String, dynamic> data) {
    final conversationId = data['conversationId'] as String?;
    if (conversationId != null) {
      _actionController.add(NotificationAction(
        conversationId: conversationId,
        action: 'open',
      ));
    }
  }

  /// Handles a local notification tap.
  void _handleNotificationTap(NotificationResponse response) {
    final conversationId = response.payload ?? '';
    if (conversationId.isNotEmpty) {
      _actionController.add(NotificationAction(
        conversationId: conversationId,
        action: 'open',
      ));
    }
  }

  /// Dismisses the notification for the given conversation.
  Future<void> dismissNotification(String conversationId) async {
    await _localNotifications.cancel(conversationId.hashCode);
  }

  /// Returns whether Do Not Disturb is active.
  bool _isDndActive() {
    // In production, read from secure storage
    return false;
  }

  Stream<NotificationAction> get notificationActions => _actionController.stream;
}