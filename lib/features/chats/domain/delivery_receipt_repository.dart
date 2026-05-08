import 'package:flutter/foundation.dart';
import 'package:whatsapp2_0/core/result.dart';

/// Aggregated delivery receipt counts for a single group message.
///
/// Requirements: 5.7
@immutable
class GroupDeliveryReceipt {
  const GroupDeliveryReceipt({
    required this.messageId,
    required this.deliveredCount,
    required this.readCount,
    required this.totalParticipants,
  });

  final String messageId;
  final int deliveredCount;
  final int readCount;
  final int totalParticipants;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupDeliveryReceipt &&
        other.messageId == messageId &&
        other.deliveredCount == deliveredCount &&
        other.readCount == readCount &&
        other.totalParticipants == totalParticipants;
  }

  @override
  int get hashCode =>
      Object.hash(messageId, deliveredCount, readCount, totalParticipants);

  @override
  String toString() =>
      'GroupDeliveryReceipt('
      'messageId: $messageId, '
      'delivered: $deliveredCount/$totalParticipants, '
      'read: $readCount/$totalParticipants'
      ')';
}

/// Abstract interface for reading per-message group delivery receipts.
///
/// Requirements: 5.7
abstract class DeliveryReceiptRepository {
  Future<Result<GroupDeliveryReceipt, AppError>> getGroupDeliveryReceipt(
    String messageId,
    String groupId,
  );

  Stream<GroupDeliveryReceipt> watchGroupDeliveryReceipt(
    String messageId,
    String groupId,
  );
}
