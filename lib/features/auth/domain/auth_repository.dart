import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/auth/domain/entities/session.dart';

/// Abstract interface for authentication operations.
///
/// Implementations back this interface with Firebase Auth and
/// [flutter_secure_storage] for token persistence.
abstract class AuthRepository {
  /// Sends an OTP to the given [phoneE164] number via Firebase Auth.
  ///
  /// Returns [Ok(null)] when the SMS has been dispatched (codeSent callback
  /// fires). Returns [Err(AuthError)] if the request fails (e.g. invalid
  /// number, network error, or Firebase quota exceeded).
  Future<Result<void, AppError>> sendOtp(String phoneE164);

  /// Verifies the [otp] code entered by the user.
  ///
  /// Uses the [verificationId] stored in memory from the preceding [sendOtp]
  /// call to create a [PhoneAuthCredential] and sign in with Firebase Auth.
  ///
  /// On success, stores the Firebase ID token, user ID, and phone number in
  /// [flutter_secure_storage] and returns [Ok(session)].
  /// Returns [Err(AuthError)] on failure.
  Future<Result<Session, AppError>> verifyOtp(String otp);

  /// Signs the current user out of Firebase Auth and clears all auth keys
  /// from [flutter_secure_storage].
  ///
  /// Always returns [Ok(null)].
  Future<Result<void, AppError>> logout();

  /// A stream that emits the current [Session] whenever the Firebase Auth
  /// state changes, or `null` when the user is signed out.
  Stream<Session?> get sessionStream;
}
