import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/calls/domain/entities/call.dart';

/// Abstract interface for voice/video call operations.
///
/// Uses Firestore as the signaling channel (offer/answer/ICE candidates)
/// and `flutter_webrtc` for the peer-to-peer media connection.
///
/// Requirements: 8.1–8.9
abstract class CallRepository {
  /// Initiates a new call to [calleeIds].
  ///
  /// Writes the offer SDP to `/calls/{callId}` in Firestore and notifies
  /// the callee via FCM. Returns the created [Call] on success.
  Future<Result<Call, AppError>> initiateCall({
    required String callerId,
    required List<String> calleeIds,
    required CallType type,
  });

  /// Answers an incoming call identified by [callId].
  ///
  /// Writes the answer SDP to Firestore, completing the signaling handshake.
  Future<Result<Call, AppError>> answerCall(String callId);

  /// Ends an active or ringing call.
  ///
  /// Writes the end-of-call state to Firestore and records the duration.
  Future<Result<void, AppError>> endCall(String callId);

  /// Returns a stream of [CallState] updates for the given [callId].
  Stream<CallState> watchCallState(String callId);

  /// Toggles the microphone mute state.
  Future<Result<void, AppError>> toggleMute(bool muted);

  /// Toggles the camera on/off during a video call.
  Future<Result<void, AppError>> toggleCamera(bool enabled);

  /// Switches between front and rear cameras.
  Future<Result<void, AppError>> switchCamera();

  /// Writes a call-summary system message to the conversation after a call ends.
  Future<Result<void, AppError>> writeCallSummary({
    required String conversationId,
    required CallType type,
    required Duration duration,
  });
}