import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';

/// Abstract interface for group chat management.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.8
abstract class GroupRepository {
  Future<Result<Conversation, AppError>> createGroup({
    required String name,
    required List<String> participantIds,
    required String creatorId,
    String? iconUrl,
  });

  Future<Result<void, AppError>> addParticipant(
    String groupId,
    String userId,
    String adminId,
  );

  Future<Result<void, AppError>> removeParticipant(
    String groupId,
    String userId,
    String adminId,
  );

  Future<Result<void, AppError>> updateGroupMetadata(
    String groupId, {
    String? name,
    String? iconUrl,
  });

  Future<Result<void, AppError>> restrictMessaging(
    String groupId,
    bool restricted,
    String adminId,
  );

  Future<Result<void, AppError>> leaveGroup(String groupId, String userId);

  Future<Result<List<String>, AppError>> getParticipantPage(
    String groupId, {
    String? afterUserId,
    int limit = 50,
  });
}
