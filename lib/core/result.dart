/// Uniform error-handling type used across all features.
///
/// Every repository and use-case method returns [Result<T, AppError>] so that
/// callers can pattern-match on success/failure without relying on exceptions.
///
/// Usage:
/// ```dart
/// final result = await authRepository.sendOtp(phone);
/// switch (result) {
///   case Ok(:final value):  // handle success
///   case Err(:final error): // handle failure
/// }
/// ```
library;

// ---------------------------------------------------------------------------
// AppError — sealed hierarchy of all domain-level errors
// ---------------------------------------------------------------------------

/// Base sealed class for all application errors.
sealed class AppError {
  const AppError();
}

/// A network-level error (timeout, no connectivity, HTTP error).
final class NetworkError extends AppError {
  const NetworkError({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NetworkError($statusCode): $message';
}

/// An authentication error (invalid OTP, session expired, etc.).
final class AuthError extends AppError {
  const AuthError({required this.message});

  final String message;

  @override
  String toString() => 'AuthError: $message';
}

/// A validation error (invalid phone number, display name too long, etc.).
final class ValidationError extends AppError {
  const ValidationError({required this.message});

  final String message;

  @override
  String toString() => 'ValidationError: $message';
}

/// An encryption/decryption error (session mismatch, key not found, etc.).
final class EncryptionError extends AppError {
  const EncryptionError({required this.message});

  final String message;

  @override
  String toString() => 'EncryptionError: $message';
}

/// A storage error (Drift DB failure, secure storage failure, etc.).
final class StorageError extends AppError {
  const StorageError({required this.message});

  final String message;

  @override
  String toString() => 'StorageError: $message';
}

/// A media error (compression failure, upload/download failure, etc.).
final class MediaError extends AppError {
  const MediaError({required this.message});

  final String message;

  @override
  String toString() => 'MediaError: $message';
}

/// A permission error (address-book denied, camera denied, etc.).
final class PermissionError extends AppError {
  const PermissionError({required this.message});

  final String message;

  @override
  String toString() => 'PermissionError: $message';
}

/// A generic/unexpected error that does not fit any other category.
final class UnknownError extends AppError {
  const UnknownError({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'UnknownError: $message${cause != null ? ' (cause: $cause)' : ''}';
}

// ---------------------------------------------------------------------------
// Result<T, E> — sealed success/failure wrapper
// ---------------------------------------------------------------------------

/// A discriminated union representing either a successful [Ok] value or a
/// failed [Err] value.
///
/// Inspired by Rust's `Result<T, E>` and the `fpdart` `Either` type, but
/// intentionally kept as a simple sealed class so it can be used without
/// importing `fpdart` in every file.
sealed class Result<T, E extends AppError> {
  const Result();

  /// Returns `true` if this is an [Ok] result.
  bool get isOk => this is Ok<T, E>;

  /// Returns `true` if this is an [Err] result.
  bool get isErr => this is Err<T, E>;

  /// Returns the success value, or `null` if this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok(:final value) => value,
        Err() => null,
      };

  /// Returns the error, or `null` if this is an [Ok].
  E? get errorOrNull => switch (this) {
        Ok() => null,
        Err(:final error) => error,
      };

  /// Transforms the success value with [f], leaving errors unchanged.
  Result<U, E> map<U>(U Function(T value) f) => switch (this) {
        Ok(:final value) => Ok(f(value)),
        Err(:final error) => Err(error),
      };

  /// Chains another [Result]-returning operation on the success value.
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) f) => switch (this) {
        Ok(:final value) => f(value),
        Err(:final error) => Err(error),
      };

  /// Returns [value] if [Ok], otherwise returns [defaultValue].
  T getOrElse(T defaultValue) => switch (this) {
        Ok(:final value) => value,
        Err() => defaultValue,
      };

  /// Folds both branches into a single value.
  U fold<U>({
    required U Function(T value) onOk,
    required U Function(E error) onErr,
  }) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };
}

/// The success variant of [Result].
final class Ok<T, E extends AppError> extends Result<T, E> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

/// The failure variant of [Result].
final class Err<T, E extends AppError> extends Result<T, E> {
  const Err(this.error);

  final E error;

  @override
  String toString() => 'Err($error)';
}

// ---------------------------------------------------------------------------
// Convenience constructors
// ---------------------------------------------------------------------------

/// Shorthand for creating an [Ok] result.
Result<T, E> ok<T, E extends AppError>(T value) => Ok(value);

/// Shorthand for creating an [Err] result.
Result<T, E> err<T, E extends AppError>(E error) => Err(error);
