import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';

/// Enforces the forward-only delivery status state machine:
///
///   `sending → sent → delivered → read`
///
/// The [DeliveryStatus.failed] state is a terminal error state reachable only
/// from [DeliveryStatus.sending].
///
/// Backward transitions and same-state transitions are rejected with a
/// [ValidationError].
class MessageStatusMachine {
  // Private constructor — this class is purely static.
  const MessageStatusMachine._();

  /// The set of valid forward transitions, expressed as
  /// `(current, next)` pairs.
  static const Map<DeliveryStatus, Set<DeliveryStatus>> _validTransitions = {
    DeliveryStatus.sending: {DeliveryStatus.sent, DeliveryStatus.failed},
    DeliveryStatus.sent: {DeliveryStatus.delivered},
    DeliveryStatus.delivered: {DeliveryStatus.read},
    // `read` and `failed` are terminal states — no outgoing transitions.
    DeliveryStatus.read: {},
    DeliveryStatus.failed: {},
  };

  /// Attempts to transition from [current] to [next].
  ///
  /// Returns [Ok] wrapping [next] when the transition is valid.
  /// Returns [Err] wrapping a [ValidationError] when the transition is
  /// backward, same-state, or otherwise invalid.
  static Result<DeliveryStatus, ValidationError> transition(
    DeliveryStatus current,
    DeliveryStatus next,
  ) {
    if (canTransition(current, next)) {
      return Ok(next);
    }
    return Err(
      ValidationError(
        message:
            'Invalid delivery status transition: '
            '${current.name} → ${next.name}. '
            'Only forward transitions are allowed '
            '(sending → sent → delivered → read, or sending → failed).',
      ),
    );
  }

  /// Returns `true` if transitioning from [current] to [next] is valid.
  static bool canTransition(DeliveryStatus current, DeliveryStatus next) {
    return _validTransitions[current]?.contains(next) ?? false;
  }

  /// Returns `true` if [next] is strictly ahead of [current] in the
  /// canonical ordering `sending < sent < delivered < read`.
  ///
  /// Note: [DeliveryStatus.failed] is a side-branch terminal state and is
  /// not considered a "forward" step in the main sequence — this method
  /// returns `false` for any transition involving [failed].
  static bool isForwardTransition(DeliveryStatus current, DeliveryStatus next) {
    const order = [
      DeliveryStatus.sending,
      DeliveryStatus.sent,
      DeliveryStatus.delivered,
      DeliveryStatus.read,
    ];

    final currentIndex = order.indexOf(current);
    final nextIndex = order.indexOf(next);

    // Either status is not in the main sequence (e.g. `failed`).
    if (currentIndex == -1 || nextIndex == -1) return false;

    return nextIndex > currentIndex;
  }
}
