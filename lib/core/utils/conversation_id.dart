/// Returns a deterministic conversationId for a direct chat between two users.
/// Both users will always compute the same ID regardless of who initiates.
String directConversationId(String uidA, String uidB) {
  final sorted = [uidA, uidB]..sort();
  return '${sorted[0]}_${sorted[1]}';
}
