import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/delivery_receipt_repository.dart';

/// Concrete Firestore-backed implementation of [DeliveryReceiptRepository].
///
/// Reads per-participant receipt documents from the sub-collection:
///   `/conversations/{groupId}/messages/{messageId}/receipts/{userId}`
///
/// Each receipt document has the shape:
/// ```json
/// {
///   "deliveredAt": <Timestamp | null>,
///   "readAt":      <Timestamp | null>
/// }
/// ```
///
/// The implementation aggregates non-null `deliveredAt` and `readAt` values
/// across all participant receipt documents to produce a [GroupDeliveryReceipt].
///
/// Requirements: 5.7
class DeliveryReceiptRepositoryImpl implements DeliveryReceiptRepository {
  DeliveryReceiptRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------------------------------------------------------------------------
  // getGroupDeliveryReceipt
  // ---------------------------------------------------------------------------

  @override
  Future<Result<GroupDeliveryReceipt, AppError>> getGroupDeliveryReceipt(
    String messageId,
    String groupId,
  ) async {
    try {
      // Fetch the group document to get the total participant count.
      final groupDoc = await _firestore
          .collection('conversations')
          .doc(groupId)
          .get();

      final totalParticipants = groupDoc.exists
          ? (List<String>.from(
              groupDoc.data()?['participantIds'] as List? ?? [],
            )).length
          : 0;

      // Fetch all receipt documents for this message.
      final receiptsSnapshot = await _firestore
          .collection('conversations')
          .doc(groupId)
          .collection('messages')
          .doc(messageId)
          .collection('receipts')
          .get();

      int deliveredCount = 0;
      int readCount = 0;

      for (final doc in receiptsSnapshot.docs) {
        final data = doc.data();
        if (data['deliveredAt'] != null) deliveredCount++;
        if (data['readAt'] != null) readCount++;
      }

      return Ok(
        GroupDeliveryReceipt(
          messageId: messageId,
          deliveredCount: deliveredCount,
          readCount: readCount,
          totalParticipants: totalParticipants,
        ),
      );
    } catch (e) {
      return Err(
        NetworkError(message: 'Failed to fetch group delivery receipt: $e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // watchGroupDeliveryReceipt
  // ---------------------------------------------------------------------------

  @override
  Stream<GroupDeliveryReceipt> watchGroupDeliveryReceipt(
    String messageId,
    String groupId,
  ) {
    // Listen to the receipts sub-collection for real-time updates.
    final receiptsStream = _firestore
        .collection('conversations')
        .doc(groupId)
        .collection('messages')
        .doc(messageId)
        .collection('receipts')
        .snapshots();

    return receiptsStream.asyncMap((snapshot) async {
      // Fetch total participant count from the group document.
      int totalParticipants = 0;
      try {
        final groupDoc = await _firestore
            .collection('conversations')
            .doc(groupId)
            .get();
        if (groupDoc.exists) {
          totalParticipants = (List<String>.from(
            groupDoc.data()?['participantIds'] as List? ?? [],
          )).length;
        }
      } catch (_) {
        // Use 0 as fallback if the group doc can't be fetched.
      }

      int deliveredCount = 0;
      int readCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['deliveredAt'] != null) deliveredCount++;
        if (data['readAt'] != null) readCount++;
      }

      return GroupDeliveryReceipt(
        messageId: messageId,
        deliveredCount: deliveredCount,
        readCount: readCount,
        totalParticipants: totalParticipants,
      );
    });
  }
}
