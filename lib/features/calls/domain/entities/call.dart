import 'package:flutter/foundation.dart';

/// Whether a call carries audio only or audio and video.
enum CallType { voice, video }

/// The lifecycle state of a call.
enum CallState {
  /// The callee's device is ringing; the call has not yet been answered.
  ringing,

  /// The call has been answered and media streams are active.
  active,

  /// The call has ended normally (either party hung up).
  ended,

  /// The callee did not answer within the timeout window.
  missed,
}

/// An immutable domain entity representing a voice or video call.
@immutable
class Call {
  const Call({
    required this.id,
    required this.callerId,
    required this.calleeIds,
    required this.type,
    required this.state,
    this.startedAt,
    this.endedAt,
  });

  /// Unique identifier for this call session.
  final String id;

  /// User ID of the participant who initiated the call.
  final String callerId;

  /// User IDs of all call recipients (one for 1-to-1, multiple for group calls).
  final List<String> calleeIds;

  /// Whether this is a voice or video call.
  final CallType type;

  /// Current lifecycle state of the call.
  final CallState state;

  /// UTC timestamp when the call was answered and became active.
  final DateTime? startedAt;

  /// UTC timestamp when the call ended (normally or due to timeout).
  final DateTime? endedAt;

  /// Returns a copy of this [Call] with the given fields replaced.
  Call copyWith({
    String? id,
    String? callerId,
    List<String>? calleeIds,
    CallType? type,
    CallState? state,
    Object? startedAt = _sentinel,
    Object? endedAt = _sentinel,
  }) {
    return Call(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      calleeIds: calleeIds ?? this.calleeIds,
      type: type ?? this.type,
      state: state ?? this.state,
      startedAt: startedAt == _sentinel
          ? this.startedAt
          : startedAt as DateTime?,
      endedAt: endedAt == _sentinel ? this.endedAt : endedAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Call) return false;
    if (calleeIds.length != other.calleeIds.length) return false;
    for (var i = 0; i < calleeIds.length; i++) {
      if (calleeIds[i] != other.calleeIds[i]) return false;
    }
    return other.id == id &&
        other.callerId == callerId &&
        other.type == type &&
        other.state == state &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    callerId,
    Object.hashAll(calleeIds),
    type,
    state,
    startedAt,
    endedAt,
  );

  @override
  String toString() =>
      'Call('
      'id: $id, '
      'callerId: $callerId, '
      'type: $type, '
      'state: $state'
      ')';
}

const Object _sentinel = Object();
