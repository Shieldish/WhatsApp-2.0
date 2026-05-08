import 'package:whatsapp2_0/core/result.dart';

/// Privacy visibility options for profile fields.
enum PrivacyVisibility {
  everyone,
  myContacts,
  nobody,
}

/// Abstract interface for profile and privacy settings operations.
///
/// Manages display name, profile photo, status bio, privacy settings,
/// two-step verification, chat export, and account deletion.
///
/// Requirements: 12.1–12.7
abstract class ProfileRepository {
  /// Reads the profile for the given [userId] from Firestore `/users/{userId}`.
  Future<Result<Map<String, dynamic>, AppError>> getProfile(String userId);

  /// Updates the display name for the current user.
  Future<Result<void, AppError>> updateDisplayName({
    required String userId,
    required String displayName,
  });

  /// Updates the profile photo URL.
  Future<Result<void, AppError>> updateProfilePhoto({
    required String userId,
    required String photoUrl,
  });

  /// Updates the status bio.
  Future<Result<void, AppError>> updateStatusBio({
    required String userId,
    required String bio,
  });

  /// Updates the privacy visibility for a specific profile field.
  Future<Result<void, AppError>> updatePrivacySetting({
    required String userId,
    required String field, // 'profilePhoto', 'statusBio', 'lastSeen'
    required PrivacyVisibility visibility,
  });

  /// Enables two-step verification with a 6-digit PIN.
  Future<Result<void, AppError>> enableTwoStepVerification(String pin);

  /// Disables two-step verification.
  Future<Result<void, AppError>> disableTwoStepVerification();

  /// Verifies the two-step PIN during re-registration.
  Future<Result<bool, AppError>> verifyTwoStepPin(String pin);

  /// Exports the chat history for the given [conversationId] as a text file.
  Future<Result<String, AppError>> exportChatHistory(String conversationId);

  /// Deletes the user account and schedules data removal.
  ///
  /// Calls a Cloud Function that removes all user data within 30 days.
  Future<Result<void, AppError>> deleteAccount(String userId);
}