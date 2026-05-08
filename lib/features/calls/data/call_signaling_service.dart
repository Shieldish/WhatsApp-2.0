import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/calls/domain/entities/call.dart';

/// Handles WebRTC signaling over Firestore.
///
/// Writes offer SDP, answer SDP, and ICE candidates to Firestore documents
/// under `/calls/{callId}`. Listens for remote SDP and ICE candidates.
///
/// Requirements: 8.1, 8.2
class CallSignalingService {
  CallSignalingService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const String _callsCollection = 'calls';

  /// Writes the offer SDP for the given [callId].
  Future<Result<void, AppError>> writeOffer({
    required String callId,
    required Map<String, dynamic> offer,
  }) async {
    try {
      await _firestore.collection(_callsCollection).doc(callId).update({
        'offer': offer,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to write offer: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  /// Writes the answer SDP for the given [callId].
  Future<Result<void, AppError>> writeAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) async {
    try {
      await _firestore.collection(_callsCollection).doc(callId).update({
        'answer': answer,
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to write answer: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  /// Adds an ICE candidate to the Firestore call document.
  Future<Result<void, AppError>> addIceCandidate({
    required String callId,
    required Map<String, dynamic> candidate,
  }) async {
    try {
      await _firestore.collection(_callsCollection).doc(callId).update({
        'iceCandidates': FieldValue.arrayUnion([candidate]),
      });
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to add ICE candidate: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  /// Streams the offer SDP from Firestore.
  Stream<Map<String, dynamic>?> watchOffer(String callId) {
    return _firestore
        .collection(_callsCollection)
        .doc(callId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data()!;
      return data['offer'] as Map<String, dynamic>?;
    });
  }

  /// Streams the answer SDP from Firestore.
  Stream<Map<String, dynamic>?> watchAnswer(String callId) {
    return _firestore
        .collection(_callsCollection)
        .doc(callId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data()!;
      return data['answer'] as Map<String, dynamic>?;
    });
  }

  /// Streams ICE candidates from Firestore.
  Stream<List<Map<String, dynamic>>> watchIceCandidates(String callId) {
    return _firestore
        .collection(_callsCollection)
        .doc(callId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return <Map<String, dynamic>>[];
      final data = snapshot.data()!;
      final candidates = data['iceCandidates'] as List<dynamic>? ?? [];
      return candidates.cast<Map<String, dynamic>>();
    });
  }

  /// Creates a new call document in Firestore.
  Future<Result<String, AppError>> createCallDocument({
    required String callerId,
    required List<String> calleeIds,
    required CallType type,
  }) async {
    try {
      final callId = _firestore.collection(_callsCollection).doc().id;

      await _firestore.collection(_callsCollection).doc(callId).set({
        'callerId': callerId,
        'calleeIds': calleeIds,
        'type': type.name,
        'state': 'ringing',
        'startedAt': null,
        'endedAt': null,
        'offer': null,
        'answer': null,
        'iceCandidates': [],
      });

      return Ok(callId);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to create call: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }

  /// Updates the call state.
  Future<Result<void, AppError>> updateCallState({
    required String callId,
    required CallState state,
  }) async {
    try {
      final update = <String, dynamic>{'state': state.name};

      if (state == CallState.active) {
        update['startedAt'] = FieldValue.serverTimestamp();
      } else if (state == CallState.ended || state == CallState.missed) {
        update['endedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_callsCollection).doc(callId).update(update);
      return Ok(null);
    } on FirebaseException catch (e) {
      return Err(NetworkError(
        message: 'Failed to update call state: ${e.message}',
        statusCode: int.tryParse(e.code),
      ));
    } catch (e) {
      return Err(UnknownError(message: e.toString()));
    }
  }
}