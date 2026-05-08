/// Utility that determines whether a status item is still visible based on
/// its [postedAt] timestamp and the current query time.
///
/// Statuses are visible for exactly 24 hours from their posting time.
/// After 24 hours, they MUST NOT be visible to any viewer.
///
/// ## Property 4: Status expiry
///
/// *For any* status item, it SHALL NOT be visible to any viewer after exactly
/// 24 hours have elapsed since its `postedAt` timestamp.
///
/// **Validates: Requirements 7.1, 7.5**
class StatusExpiryChecker {
  /// The duration after which a status expires.
  static const Duration expiryDuration = Duration(hours: 24);

  /// Returns `true` if the status posted at [postedAt] is still visible
  /// at [queryTime].
  ///
  /// A status is considered visible if [queryTime] is strictly less than
  /// [postedAt] + 24 hours.
  bool isVisible({
    required DateTime postedAt,
    required DateTime queryTime,
  }) {
    final expiresAt = postedAt.add(expiryDuration);
    return queryTime.isBefore(expiresAt);
  }

  /// Returns the expiry timestamp for a status posted at [postedAt].
  DateTime expiryTime(DateTime postedAt) {
    return postedAt.add(expiryDuration);
  }

  /// Returns the remaining duration before a status posted at [postedAt]
  /// expires, measured from [queryTime].
  ///
  /// Returns [Duration.zero] if the status has already expired.
  Duration remainingTime({
    required DateTime postedAt,
    required DateTime queryTime,
  }) {
    final expiresAt = postedAt.add(expiryDuration);
    final remaining = expiresAt.difference(queryTime);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}