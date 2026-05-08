import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/core/validators/phone_number_validator.dart';
import 'package:whatsapp2_0/features/auth/domain/auth_repository.dart';
import 'package:whatsapp2_0/features/auth/domain/entities/session.dart';

/// Orchestrates the phone-number OTP verification flow.
///
/// Steps:
/// 1. Validate the phone number in E.164 format.
/// 2. Send an OTP via [AuthRepository.sendOtp].
/// 3. Verify the OTP via [AuthRepository.verifyOtp].
/// 4. Return the resulting [Session] (token persistence is handled by the
///    [AuthRepository] implementation).
///
/// Requirements: 1.1, 1.2, 1.4
class PhoneVerificationUseCase {
  const PhoneVerificationUseCase({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  /// Validates [phone] and, if valid, dispatches an OTP to that number.
  ///
  /// Returns [Ok(null)] when the OTP has been sent successfully.
  /// Returns [Err(ValidationError)] if [phone] is not a valid E.164 number.
  /// Returns [Err(AuthError)] or [Err(NetworkError)] if the OTP dispatch fails.
  Future<Result<void, AppError>> sendOtp(String phone) async {
    final validationResult = PhoneNumberValidator.validate(phone);
    if (validationResult.isErr) {
      return Err(validationResult.errorOrNull!);
    }

    return _authRepository.sendOtp(phone);
  }

  /// Validates [otp] format and, if valid, verifies it with the backend.
  ///
  /// A valid OTP is exactly 6 decimal digits (regex `^\d{6}$`).
  ///
  /// Returns [Ok(session)] on successful verification.
  /// Returns [Err(ValidationError)] if [otp] is not exactly 6 digits.
  /// Returns [Err(AuthError)] if the OTP is incorrect or expired.
  Future<Result<Session, AppError>> verifyOtp(String otp) async {
    if (!_otpRegex.hasMatch(otp)) {
      return Err(
        const ValidationError(
          message: 'OTP must be exactly 6 digits (e.g. 123456).',
        ),
      );
    }

    return _authRepository.verifyOtp(otp);
  }

  static final RegExp _otpRegex = RegExp(r'^\d{6}$');
}
