import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:whatsapp2_0/core/result.dart';

/// Requests a voice-call OTP for the given phone number by invoking the
/// `requestVoiceOtp` Firebase Cloud Function.
///
/// This is the fallback path when SMS delivery has not arrived within 60 s.
///
/// Requirements: 1.3
class RequestVoiceOtpUseCase {
  const RequestVoiceOtpUseCase({FirebaseFunctions? functions})
    : _functions = functions;

  final FirebaseFunctions? _functions;

  FirebaseFunctions get _firebaseFunctions =>
      _functions ?? FirebaseFunctions.instance;

  /// Calls the `requestVoiceOtp` Cloud Function with [phoneE164].
  ///
  /// Returns [Ok(null)] when the function acknowledges the request.
  /// Returns [Err(NetworkError)] if the call fails (network issue, function
  /// error, or timeout).
  Future<Result<void, AppError>> call(String phoneE164) async {
    try {
      final callable = _firebaseFunctions.httpsCallable('requestVoiceOtp');
      await callable.call<void>({'phoneNumber': phoneE164});
      return const Ok(null);
    } on FirebaseFunctionsException catch (e) {
      return Err(
        NetworkError(
          message: e.message ?? 'Voice OTP request failed.',
          statusCode: null,
        ),
      );
    } catch (e) {
      return Err(NetworkError(message: 'Voice OTP request failed: $e'));
    }
  }
}
