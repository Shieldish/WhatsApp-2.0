import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/auth/domain/auth_repository.dart';
import 'package:whatsapp2_0/features/auth/domain/entities/session.dart';

/// Secure storage keys used to persist session data across app restarts.
const _kAuthToken = 'auth_token';
const _kAuthUserId = 'auth_user_id';
const _kAuthPhone = 'auth_phone';

/// Concrete implementation of [AuthRepository] backed by Firebase Auth and
/// [FlutterSecureStorage].
///
/// OTP flow:
/// 1. [sendOtp] calls [FirebaseAuth.verifyPhoneNumber] and stores the
///    [verificationId] in memory via the `codeSent` callback.
/// 2. [verifyOtp] creates a [PhoneAuthCredential] from the stored
///    [verificationId] + the user-supplied OTP, signs in, retrieves the
///    Firebase ID token, persists it in secure storage, and returns a
///    [Session].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FlutterSecureStorage? secureStorage,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _storage = secureStorage ?? const FlutterSecureStorage();

  final FirebaseAuth _auth;
  final FlutterSecureStorage _storage;

  /// Holds the verification ID returned by Firebase between [sendOtp] and
  /// [verifyOtp] calls. Stored in memory only — never persisted.
  String? _verificationId;

  // ---------------------------------------------------------------------------
  // sendOtp
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> sendOtp(String phoneE164) async {
    final completer = Completer<Result<void, AppError>>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(const Ok(null));
          }
        },
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            await _persistSession(userCredential, phoneE164);
            if (!completer.isCompleted) {
              completer.complete(const Ok(null));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(Err(AuthError(message: e.toString())));
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.complete(
              Err(
                AuthError(message: e.message ?? 'Phone verification failed.'),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(const Ok(null));
          }
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        return Err(AuthError(message: e.toString()));
      }
    }

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // verifyOtp
  // ---------------------------------------------------------------------------

  @override
  Future<Result<Session, AppError>> verifyOtp(String otp) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      return const Err(
        AuthError(
          message:
              'No pending verification. Call sendOtp() before verifyOtp().',
        ),
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final session = await _persistSession(userCredential, null);
      return Ok(session);
    } on FirebaseAuthException catch (e) {
      return Err(AuthError(message: e.message ?? 'OTP verification failed.'));
    } catch (e) {
      return Err(AuthError(message: e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // logout
  // ---------------------------------------------------------------------------

  @override
  Future<Result<void, AppError>> logout() async {
    try {
      await _auth.signOut();
      await _clearStoredSession();
      return const Ok(null);
    } catch (e) {
      await _clearStoredSession();
      return const Ok(null);
    }
  }

  // ---------------------------------------------------------------------------
  // sessionStream
  // ---------------------------------------------------------------------------

  @override
  Stream<Session?> get sessionStream {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user == null) return null;

      String? token = await _storage.read(key: _kAuthToken);
      if (token == null || token.isEmpty) {
        token = await user.getIdToken();
      }

      final storedPhone = await _storage.read(key: _kAuthPhone);
      final phone = storedPhone ?? user.phoneNumber ?? '';

      return Session(
        userId: user.uid,
        phoneNumber: phone,
        token: token ?? '',
        createdAt: DateTime.now(),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<Session> _persistSession(
    UserCredential userCredential,
    String? phoneHint,
  ) async {
    final user = userCredential.user!;
    final token = await user.getIdToken() ?? '';
    final phone = user.phoneNumber ?? phoneHint ?? '';

    await Future.wait([
      _storage.write(key: _kAuthToken, value: token),
      _storage.write(key: _kAuthUserId, value: user.uid),
      _storage.write(key: _kAuthPhone, value: phone),
    ]);

    return Session(
      userId: user.uid,
      phoneNumber: phone,
      token: token,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _clearStoredSession() async {
    await Future.wait([
      _storage.delete(key: _kAuthToken),
      _storage.delete(key: _kAuthUserId),
      _storage.delete(key: _kAuthPhone),
    ]);
  }
}
