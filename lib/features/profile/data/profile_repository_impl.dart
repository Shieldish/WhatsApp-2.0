import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/profile/domain/profile_repository.dart';

/// Firestore-backed implementation of [ProfileRepository].
///
/// Profile data is stored at `/users/{userId}`. Two-step verification PIN
/// is stored in `flutter_secure_storage`.
///
/// Requirements: 12.1–12.7
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FlutterSecureStorage secureStorage,
  })  : _firestore = firestore,
        _secureStorage = secureStorage;

  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;

  static const String _twoStepPinKey = 'two_step_pin';
  static const String _usersCollection = 'users';

  @override
  Future<Result<Map<String, dynamic>, AppError>> getProfile(
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!doc.exists) {
        return Err(StorageError(message: 'Profile not found'));
      }
      return Ok(doc.data()!);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to get profile: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'displayName': displayName,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to update display name: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> updateProfilePhoto({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'photoUrl': photoUrl,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to update photo: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> updateStatusBio({
    required String userId,
    required String bio,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'statusBio': bio,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to update bio: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> updatePrivacySetting({
    required String userId,
    required String field,
    required PrivacyVisibility visibility,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'privacySettings.$field': visibility.name,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to update privacy: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  @override
  Future<Result<void, AppError>> enableTwoStepVerification(String pin) async {
    try {
      await _secureStorage.write(key: _twoStepPinKey, value: pin);
      return Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to enable 2-step: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> disableTwoStepVerification() async {
    try {
      await _secureStorage.delete(key: _twoStepPinKey);
      return Ok(null);
    } catch (e) {
      return Err(StorageError(message: 'Failed to disable 2-step: $e'));
    }
  }

  @override
  Future<Result<bool, AppError>> verifyTwoStepPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _twoStepPinKey);
      return Ok(storedPin == pin);
    } catch (e) {
      return Err(StorageError(message: 'Failed to verify PIN: $e'));
    }
  }

  @override
  Future<Result<String, AppError>> exportChatHistory(
    String conversationId,
  ) async {
    // In production, query all messages from Drift and format as text.
    // Returns the file path of the exported file.
    return Err(StorageError(message: 'Export not yet implemented'));
  }

  @override
  Future<Result<void, AppError>> deleteAccount(String userId) async {
    try {
      // In production, call a Cloud Function that schedules deletion.
      await _firestore.collection(_usersCollection).doc(userId).delete();
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to delete account: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }
}