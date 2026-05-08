import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/presence/domain/entities/presence_info.dart';

/// Privacy settings for presence (online/last-seen).
enum PresencePrivacy {
  everyone,
  contacts,
  nobody,
}

/// Abstract interface for presence tracking operations.
///
/// Tracks and broadcasts online/offline/last-seen state using Firestore.
/// The `onDisconnect()` handler automatically sets `lastSeen` when the
/// client disconnects.
///
/// Requirements: 10.1–10.6
abstract class PresenceRepository {
  /// Sets the current user's presence to online.
  ///
  /// Writes `isOnline: true` to `/presence/{userId}` and registers a
  /// Firestore `onDisconnect()` handler that sets `isOnline: false` and
  /// updates `lastSeen` when the client disconnects.
  Future<Result<void, AppError>> setOnline({required String userId});

  /// Sets the current user's presence to offline.
  ///
  /// Writes `isOnline: false` and updates `lastSeen` to now.
  Future<Result<void, AppError>> setOffline({required String userId});

  /// Returns a stream of [PresenceInfo] for the given [userId].
  ///
  /// Emits updated values whenever the user's online/lastSeen state changes
  /// in Firestore.
  Stream<PresenceInfo> watchPresence(String userId);

  /// Updates the presence privacy setting for the current user.
  ///
  /// The setting is stored in `/users/{userId}/privacySettings/lastSeen`
  /// and enforced by Firestore Security Rules (server-side) and
  /// [PresencePrivacyFilter] (client-side).
  Future<Result<void, AppError>> updatePrivacySetting({
    required String userId,
    required PresencePrivacy setting,
  });

  /// Returns the current privacy setting for the given [userId].
  Future<Result<PresencePrivacy, AppError>> getPrivacySetting(String userId);
}