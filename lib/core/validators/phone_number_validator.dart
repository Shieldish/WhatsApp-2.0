import 'package:whatsapp2_0/core/result.dart';

/// Validates phone numbers in E.164 format.
///
/// E.164 format: `+` followed by a country code (1–3 digits, starting with
/// a non-zero digit) and a subscriber number, with the total digit count
/// (excluding the leading `+`) between 7 and 15.
///
/// Regex used: `^\+[1-9]\d{6,14}$`
/// - Starts with `+`
/// - First digit is 1–9 (no leading zero in country code)
/// - Followed by 6–14 more digits
/// - Total digits after `+`: 7–15 (covers the shortest valid E.164 numbers)
class PhoneNumberValidator {
  PhoneNumberValidator._();

  static final RegExp _e164Regex = RegExp(r'^\+[1-9]\d{6,14}$');

  /// Validates [phone] against the E.164 format.
  ///
  /// Returns [Ok] containing the phone number string on success, or [Err]
  /// containing a [ValidationError] with a descriptive message on failure.
  static Result<String, ValidationError> validate(String phone) {
    if (phone.isEmpty) {
      return Err(
        const ValidationError(message: 'Phone number must not be empty.'),
      );
    }

    if (!_e164Regex.hasMatch(phone)) {
      return Err(
        const ValidationError(
          message:
              'Phone number must be in E.164 format: '
              'a "+" followed by 7–15 digits (e.g. +14155552671).',
        ),
      );
    }

    return Ok(phone);
  }

  /// Returns `true` if [phone] is a valid E.164 phone number.
  static bool isValid(String phone) => validate(phone).isOk;
}
