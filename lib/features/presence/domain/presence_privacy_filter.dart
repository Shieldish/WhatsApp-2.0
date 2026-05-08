import 'package:whatsapp2_0/features/presence/domain/entities/presence_info.dart';
import 'package:whatsapp2_0/features/presence/domain/presence_repository.dart';

/// Client-side filter that enforces presence privacy settings.
///
/// Even though Firestore Security Rules provide server-side enforcement,
/// this filter ensures the client never displays a last-seen timestamp that
/// the user should not see according to the privacy setting.
///
/// ## Property 11: Privacy setting enforcement for last-seen
///
/// *For any* user with last-seen privacy set to "Nobody", no other user's
/// device SHALL receive that user's last-seen timestamp via the
/// Presence_Service.
///
/// **Validates: Requirements 10.4**
class PresencePrivacyFilter {
  /// Filters the [presenceInfo] according to the [privacySetting] of the
  /// target user and the relationship between [currentUserId] and the
  /// target user.
  ///
  /// Returns a sanitised [PresenceInfo] where:
  /// - If [privacySetting] is [PresencePrivacy.everyone]:
  ///   Returns the presence info unchanged.
  /// - If [privacySetting] is [PresencePrivacy.contacts]:
  ///   Returns the presence info unchanged if [isContact] is true,
  ///   otherwise hides `lastSeen`.
  /// - If [privacySetting] is [PresencePrivacy.nobody]:
  ///   Hides `lastSeen` for all users.
  PresenceInfo apply({
    required PresenceInfo presenceInfo,
    required PresencePrivacy privacySetting,
    required bool isContact,
  }) {
    switch (privacySetting) {
      case PresencePrivacy.everyone:
        return presenceInfo;

      case PresencePrivacy.contacts:
        if (isContact) {
          return presenceInfo;
        }
        return presenceInfo.copyWith(lastSeen: null);

      case PresencePrivacy.nobody:
        return presenceInfo.copyWith(lastSeen: null);
    }
  }

  /// Returns `true` if the [lastSeen] timestamp should be visible to
  /// [currentUserId] given the [privacySetting].
  bool isLastSeenVisible({
    required PresencePrivacy privacySetting,
    required bool isContact,
  }) {
    switch (privacySetting) {
      case PresencePrivacy.everyone:
        return true;
      case PresencePrivacy.contacts:
        return isContact;
      case PresencePrivacy.nobody:
        return false;
    }
  }
}