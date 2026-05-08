import 'package:whatsapp2_0/core/result.dart';

/// Duration options for muting a conversation.
enum MuteDuration {
  hours8,
  week1,
  always,
}

/// Represents an action taken by the user on a notification.
class NotificationAction {
  const NotificationAction({
    required this.conversationId,
    required this.action,
  });

  final String conversationId;
  final String action; // 'open', 'reply', 'dismiss'
}

/// Abstract interface for push notification operations.
///
/// Handles FCM token registration, incoming notification processing,
/// local notification display, conversation muting, and Do Not Disturb.
///
/// Requirements: 11.1–11.6
abstract class NotificationRepository {
  /// Initializes the notification service.
  ///
  /// Requests notification permissions, registers for FCM, and sets up
  /// the foreground/background message handlers.
  Future<Result<void, AppError>> initialize();

  /// Registers the FCM token for the current device.
  ///
  /// The token is stored in Firestore at `/users/{userId}/fcmTokens/{tokenId}`.
  Future<Result<void, AppError>> registerFcmToken(String userId);

  /// Unregisters the FCM token when the user signs out.
  Future<Result<void, AppError>> unregisterFcmToken(String userId);

  /// Mutes the given [conversationId] for the specified [duration].
  ///
  /// Stores `mutedUntil` in the `ConversationsTable` and in the Firestore
  /// conversation document. The [FcmHandler] checks this before showing
  /// a notification.
  Future<Result<void, AppError>> muteConversation({
    required String conversationId,
    required MuteDuration duration,
  });

  /// Unmutes the given [conversationId].
  Future<Result<void, AppError>> unmuteConversation(String conversationId);

  /// Dismisses the local notification for [conversationId].
  ///
  /// Called when [MessageRepository.markAsRead] is invoked to cancel
  /// the corresponding notification.
  Future<void> dismissNotification(String conversationId);

  /// Sets the Do Not Disturb mode.
  ///
  /// When DND is active, all notifications except calls from starred
  /// contacts are suppressed.
  Future<Result<void, AppError>> setDoNotDisturb(bool enabled);

  /// Returns the current Do Not Disturb state.
  bool get isDoNotDisturbEnabled;

  /// Stream of notification actions triggered by the user.
  Stream<NotificationAction> get notificationActions;
}