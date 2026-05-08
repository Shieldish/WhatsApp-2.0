import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/features/auth/data/auth_repository_impl.dart';
import 'package:whatsapp2_0/features/auth/domain/auth_repository.dart';
import 'package:whatsapp2_0/features/auth/domain/otp_lockout_timer.dart';
import 'package:whatsapp2_0/features/auth/domain/session_manager.dart';
import 'package:whatsapp2_0/features/auth/domain/use_cases/phone_verification_use_case.dart';
import 'package:whatsapp2_0/features/auth/domain/use_cases/request_voice_otp_use_case.dart';

/// Provides the [AuthRepository] implementation backed by Firebase Auth.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provides the [PhoneVerificationUseCase] wired to [authRepositoryProvider].
final phoneVerificationUseCaseProvider = Provider<PhoneVerificationUseCase>((
  ref,
) {
  final repo = ref.watch(authRepositoryProvider);
  return PhoneVerificationUseCase(authRepository: repo);
});

/// Provides the [OtpLockoutTimer] as a long-lived object.
final otpLockoutTimerProvider = Provider<OtpLockoutTimer>((ref) {
  final timer = OtpLockoutTimer();
  ref.onDispose(timer.dispose);
  return timer;
});

/// Provides the [SessionManager] wired to [authRepositoryProvider].
final sessionManagerProvider = Provider<SessionManager>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return SessionManager(authRepository: repo);
});

/// Provides the [RequestVoiceOtpUseCase] for the voice-call OTP fallback.
///
/// Requirements: 1.3
final requestVoiceOtpUseCaseProvider = Provider<RequestVoiceOtpUseCase>((ref) {
  return const RequestVoiceOtpUseCase();
});
