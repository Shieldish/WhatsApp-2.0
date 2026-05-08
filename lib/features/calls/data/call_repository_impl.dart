import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/calls/data/call_signaling_service.dart';
import 'package:whatsapp2_0/features/calls/domain/call_repository.dart';
import 'package:whatsapp2_0/features/calls/domain/entities/call.dart';

/// Firestore-backed implementation of [CallRepository].
///
/// Uses [CallSignalingService] for WebRTC signaling over Firestore.
/// Media streams are handled by `flutter_webrtc` (not implemented in this
/// version — the repository focuses on signaling and call lifecycle).
///
/// Requirements: 8.1–8.9
class CallRepositoryImpl implements CallRepository {
  CallRepositoryImpl({
    required FirebaseFirestore firestore,
    CallSignalingService? signalingService,
  })  : _signalingService = signalingService ??
            CallSignalingService(firestore: firestore),
        _firestore = firestore;

  final FirebaseFirestore _firestore;
  final CallSignalingService _signalingService;

  @override
  Future<Result<Call, AppError>> initiateCall({
    required String callerId,
    required List<String> calleeIds,
    required CallType type,
  }) async {
    final callIdResult = await _signalingService.createCallDocument(
      callerId: callerId,
      calleeIds: calleeIds,
      type: type,
    );

    return callIdResult.fold(
      onOk: (callId) {
        final call = Call(
          id: callId,
          callerId: callerId,
          calleeIds: calleeIds,
          type: type,
          state: CallState.ringing,
        );
        return Ok(call);
      },
      onErr: (error) => Err(error),
    );
  }

  @override
  Future<Result<Call, AppError>> answerCall(String callId) async {
    final stateResult = await _signalingService.updateCallState(
      callId: callId,
      state: CallState.active,
    );

    return stateResult.fold(
      onOk: (_) async {
        final doc = await _firestore
            .collection('calls')
            .doc(callId)
            .get();
        if (!doc.exists) {
          return Err(StorageError(message: 'Call not found'));
        }
        final data = doc.data()!;
        return Ok(Call(
          id: callId,
          callerId: data['callerId'] as String,
          calleeIds: List<String>.from(data['calleeIds'] as List),
          type: data['type'] == 'video' ? CallType.video : CallType.voice,
          state: CallState.active,
          startedAt: DateTime.now(),
        ));
      },
      onErr: (error) => Err(error),
    );
  }

  @override
  Future<Result<void, AppError>> endCall(String callId) async {
    return _signalingService.updateCallState(
      callId: callId,
      state: CallState.ended,
    );
  }

  @override
  Stream<CallState> watchCallState(String callId) {
    return _firestore
        .collection('calls')
        .doc(callId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return CallState.ended;
      final data = snapshot.data()!;
      final stateStr = data['state'] as String? ?? 'ended';
      return CallState.values.firstWhere(
        (s) => s.name == stateStr,
        orElse: () => CallState.ended,
      );
    });
  }

  @override
  Future<Result<void, AppError>> toggleMute(bool muted) async {
    // In production, this would use flutter_webrtc to mute the local audio track.
    return Ok(null);
  }

  @override
  Future<Result<void, AppError>> toggleCamera(bool enabled) async {
    // In production, this would use flutter_webrtc to enable/disable the local
    // video track.
    return Ok(null);
  }

  @override
  Future<Result<void, AppError>> switchCamera() async {
    // In production, this would use flutter_webrtc to switch the camera.
    return Ok(null);
  }

  @override
  Future<Result<void, AppError>> writeCallSummary({
    required String conversationId,
    required CallType type,
    required Duration duration,
  }) async {
    try {
      // Write a system message to the conversation
      final typeStr = type == CallType.voice ? 'voice call' : 'video call';
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds.remainder(60);
      final durationStr = minutes > 0
          ? '${minutes}m ${seconds}s'
          : '${seconds}s';

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': '',
        'ciphertext': '',
        'plaintextCache': '$typeStr ($durationStr)',
        'type': 'system',
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      return Ok(null);
    } catch (e) {
      return Err(UnknownError(message: 'Failed to write call summary: $e'));
    }
  }
}