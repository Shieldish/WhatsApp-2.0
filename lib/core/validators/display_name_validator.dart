import 'package:whatsapp2_0/core/result.dart';

/// Validates display names per Requirements 1.7 and 12.1.
///
/// Rules:
/// - Must be between 1 and 25 characters (inclusive).
/// - Must not be whitespace-only (i.e. `trim()` must not be empty).
class DisplayNameValidator {
  DisplayNameValidator._();

  static const int _maxLength = 25;

  /// Validates [name] against the display name rules.
  ///
  /// Returns [Ok] containing the name string on success, or [Err] containing
  /// a [ValidationError] with a descriptive message on failure.
  static Result<String, ValidationError> validate(String name) {
    if (name.isEmpty || name.trim().isEmpty) {
      return Err(
        const ValidationError(
          message: 'Display name must not be empty or whitespace-only.',
        ),
      );
    }

    if (name.length > _maxLength) {
      return Err(
        ValidationError(
          message:
              'Display name must be at most $_maxLength characters long '
              '(got ${name.length}).',
        ),
      );
    }

    return Ok(name);
  }

  /// Returns `true` if [name] is a valid display name.
  static bool isValid(String name) => validate(name).isOk;
}
