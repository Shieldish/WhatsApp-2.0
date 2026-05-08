import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks consecutive OTP failures and enforces a 1-hour lockout after 3
/// consecutive failures.
///
/// Lockout state is persisted in [flutter_secure_storage] so it survives app
/// restarts.
///
/// Storage keys:
/// - `'otp_lockout_until'`  — ISO 8601 string of the lockout expiry time.
/// - `'otp_failure_count'`  — current consecutive failure count as a string.
///
/// Requirements: 1.5
class OtpLockoutTimer {
  OtpLockoutTimer({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _lockoutUntilKey = 'otp_lockout_until';
  static const String _failureCountKey = 'otp_failure_count';
  static const int _maxFailures = 3;
  static const Duration _lockoutDuration = Duration(hours: 1);

  final FlutterSecureStorage _storage;

  int _failureCount = 0;
  DateTime? _lockoutUntil;

  /// Countdown stream controller — emits remaining lockout duration every
  /// second while locked; emits [Duration.zero] when the lockout expires.
  final StreamController<Duration> _countdownController =
      StreamController<Duration>.broadcast();

  Timer? _countdownTimer;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Loads persisted lockout state from secure storage.
  ///
  /// Must be called once on app start before using any other method.
  Future<void> initialize() async {
    final countStr = await _storage.read(key: _failureCountKey);
    _failureCount = int.tryParse(countStr ?? '') ?? 0;

    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    if (lockoutStr != null) {
      final parsed = DateTime.tryParse(lockoutStr);
      if (parsed != null && parsed.isAfter(DateTime.now())) {
        _lockoutUntil = parsed;
        _startCountdown();
      } else {
        // Lockout has already expired — clear stale storage.
        await _clearLockoutStorage();
      }
    }
  }

  /// Records a single OTP failure.
  ///
  /// If the failure count reaches [_maxFailures] (3), a 1-hour lockout is
  /// started and the state is persisted to secure storage.
  Future<void> recordFailure() async {
    if (isLocked) return; // Already locked; ignore additional failures.

    _failureCount++;
    await _storage.write(
      key: _failureCountKey,
      value: _failureCount.toString(),
    );

    if (_failureCount >= _maxFailures) {
      _lockoutUntil = DateTime.now().add(_lockoutDuration);
      await _storage.write(
        key: _lockoutUntilKey,
        value: _lockoutUntil!.toIso8601String(),
      );
      _startCountdown();
    }
  }

  /// Returns `true` if the account is currently locked out.
  bool get isLocked {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isBefore(_lockoutUntil!)) return true;
    // Lockout has expired — clean up in-memory state.
    _lockoutUntil = null;
    return false;
  }

  /// Returns the remaining lockout duration, or [Duration.zero] if not locked.
  Duration get remainingLockoutDuration {
    if (!isLocked) return Duration.zero;
    final remaining = _lockoutUntil!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// A broadcast stream that emits the remaining lockout [Duration] every
  /// second while locked, and emits [Duration.zero] when the lockout expires.
  Stream<Duration> get countdownStream => _countdownController.stream;

  /// Resets the failure count and clears any active lockout.
  ///
  /// Should be called after a successful OTP verification.
  Future<void> reset() async {
    _failureCount = 0;
    _lockoutUntil = null;
    _stopCountdown();
    await _clearLockoutStorage();
  }

  /// Releases resources held by this timer.
  ///
  /// Call this when the object is no longer needed (e.g. in a provider's
  /// dispose callback).
  void dispose() {
    _stopCountdown();
    _countdownController.close();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _startCountdown() {
    _stopCountdown(); // Cancel any existing timer first.

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = remainingLockoutDuration;
      _countdownController.add(remaining);

      if (remaining == Duration.zero) {
        _stopCountdown();
        // Clear persisted lockout state once it expires.
        _clearLockoutStorage();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> _clearLockoutStorage() async {
    await Future.wait([
      _storage.delete(key: _lockoutUntilKey),
      _storage.delete(key: _failureCountKey),
    ]);
  }
}
