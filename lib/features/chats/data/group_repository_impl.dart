import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/domain/group_repository.dart';

/// Concrete Firestore-backed implementation of [GroupRepository].
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.8
class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<Conversation, AppError>> createGroup({
    required String name,
    required List<String> participantIds,
    required String creatorId,
    String? iconUrl,
  }) async {
    final allParticipants = [
      creatorId,
      ...participantIds.where((id) => id != creatorId),
    ];

    if (allParticipants.length < 2) {
      return Err(
        ValidationError(message: 'A group must have at least 2 participants.'),
      );
    }
    if (allParticipants.length > 1024) {
      return Err(
        ValidationError(
          message: 'A group cannot have more than 1,024 participants.',
        ),
      );
    }

    final groupId = _generateId();
    final now = DateTime.now();

    try {
      final groupRef = _firestore.collection('conversations').doc(groupId);
      final batch = _firestore.batch();

      batch.set(groupRef, {
        'type': 'group',
        'participantIds': allParticipants,
        'adminIds': [creatorId],
        'groupName': name,
        'groupIconUrl': iconUrl,
        'messagingRestricted': false,
        'lastMessagePreview': 'Group created',
        'lastMessageAt': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
      });

      final msgRef = groupRef.collection('messages').doc(_generateId());
      batch.set(msgRef, _systemMessage('Group created', creatorId, now));

      await batch.commit();
    } catch (e) {
      return Err(NetworkError(message: 'Failed to create group: $e'));
    }

    return Ok(
      Conversation(
        id: groupId,
        type: ConversationType.group,
        participantIds: allParticipants,
        lastMessagePreview: 'Group created',
        lastMessageAt: now,
        unreadCount: 0,
        isArchived: false,
        groupName: name,
        groupIconUrl: iconUrl,
        adminIds: [creatorId],
        messagingRestricted: false,
      ),
    );
  }

  @override
  Future<Result<void, AppError>> addParticipant(
    String groupId,
    String userId,
    String adminId,
  ) async {
    final adminCheck = await _verifyAdmin(groupId, adminId);
    if (adminCheck != null) return Err(adminCheck);

    try {
      final groupRef = _firestore.collection('conversations').doc(groupId);
      final batch = _firestore.batch();
      batch.update(groupRef, {
        'participantIds': FieldValue.arrayUnion([userId]),
      });
      batch.set(
        groupRef.collection('messages').doc(_generateId()),
        _systemMessage('$adminId added $userId', adminId, DateTime.now()),
      );
      await batch.commit();
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(message: 'Failed to add participant: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> removeParticipant(
    String groupId,
    String userId,
    String adminId,
  ) async {
    final adminCheck = await _verifyAdmin(groupId, adminId);
    if (adminCheck != null) return Err(adminCheck);

    try {
      final groupRef = _firestore.collection('conversations').doc(groupId);
      final batch = _firestore.batch();
      batch.update(groupRef, {
        'participantIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });
      batch.set(
        groupRef.collection('messages').doc(_generateId()),
        _systemMessage('$adminId removed $userId', adminId, DateTime.now()),
      );
      await batch.commit();
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(message: 'Failed to remove participant: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> updateGroupMetadata(
    String groupId, {
    String? name,
    String? iconUrl,
  }) async {
    if (name == null && iconUrl == null) return const Ok(null);

    try {
      final groupRef = _firestore.collection('conversations').doc(groupId);
      final batch = _firestore.batch();

      final updates = <String, dynamic>{};
      if (name != null) updates['groupName'] = name;
      if (iconUrl != null) updates['groupIconUrl'] = iconUrl;
      batch.update(groupRef, updates);

      final systemText = name != null && iconUrl != null
          ? 'Group name changed to $name and icon updated'
          : name != null
          ? 'Group name changed to $name'
          : 'Group icon updated';

      batch.set(
        groupRef.collection('messages').doc(_generateId()),
        _systemMessage(systemText, 'system', DateTime.now()),
      );
      await batch.commit();
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(message: 'Failed to update group metadata: $e'));
    }
  }

  @override
  Future<Result<void, AppError>> restrictMessaging(
    String groupId,
    bool restricted,
    String adminId,
  ) async {
    final adminCheck = await _verifyAdmin(groupId, adminId);
    if (adminCheck != null) return Err(adminCheck);

    try {
      final groupRef = _firestore.collection('conversations').doc(groupId);
      final batch = _firestore.batch();
      batch.update(groupRef, {'messagingRestricted': restricted});
      final systemText = restricted
          ? 'Only admins can send messages'
          : 'All participants can send messages';
      batch.set(
        groupRef.collection('messages').doc(_generateId()),
        _systemMessage(systemText, adminId, DateTime.now()),
      );
      await batch.commit();
      return const Ok(null);
    } catch (e) {
      return Err(
        NetworkError(message: 'Failed to update messaging restriction: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppError>> leaveGroup(
    String groupId,
    String userId,
  ) async {
    try {
      final groupRef = _firestore.collection('conversations').doc(groupId);
      final batch = _firestore.batch();
      batch.update(groupRef, {
        'participantIds': FieldValue.arrayRemove([userId]),
        'adminIds': FieldValue.arrayRemove([userId]),
      });
      batch.set(
        groupRef.collection('messages').doc(_generateId()),
        _systemMessage('$userId left', userId, DateTime.now()),
      );
      await batch.commit();
      return const Ok(null);
    } catch (e) {
      return Err(NetworkError(message: 'Failed to leave group: $e'));
    }
  }

  @override
  Future<Result<List<String>, AppError>> getParticipantPage(
    String groupId, {
    String? afterUserId,
    int limit = 50,
  }) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(groupId)
          .get();

      if (!doc.exists) {
        return Err(ValidationError(message: 'Group not found: $groupId'));
      }

      final allParticipants = List<String>.from(
        doc.data()?['participantIds'] as List? ?? [],
      );

      int startIndex = 0;
      if (afterUserId != null) {
        final idx = allParticipants.indexOf(afterUserId);
        if (idx != -1) startIndex = idx + 1;
      }

      return Ok(allParticipants.skip(startIndex).take(limit).toList());
    } catch (e) {
      return Err(NetworkError(message: 'Failed to fetch participant page: $e'));
    }
  }

  Future<AppError?> _verifyAdmin(String groupId, String adminId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(groupId)
          .get();
      if (!doc.exists) {
        return ValidationError(message: 'Group not found: $groupId');
      }
      final adminIds = List<String>.from(
        doc.data()?['adminIds'] as List? ?? [],
      );
      if (!adminIds.contains(adminId)) {
        return ValidationError(
          message: 'User $adminId is not an admin of group $groupId.',
        );
      }
      return null;
    } catch (e) {
      return NetworkError(message: 'Failed to verify admin status: $e');
    }
  }

  Map<String, dynamic> _systemMessage(
    String text,
    String senderId,
    DateTime now,
  ) {
    return {
      'senderId': senderId,
      'plaintext': text,
      'type': 'system',
      'sentAt': Timestamp.fromDate(now),
      'deliveredAt': null,
      'readAt': null,
      'deletedForEveryone': false,
    };
  }

  static String _generateId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return '${ts}_$rand';
  }
}
