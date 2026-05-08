import 'package:flutter/foundation.dart';

/// A single result returned by the full-text search over conversations and
/// messages.
///
/// Each result is tied to a specific message that matched the search query.
/// The [snippet] contains the matched text excerpt (may include surrounding
/// context words).
@immutable
class SearchResult {
  const SearchResult({
    required this.conversationId,
    this.conversationName,
    required this.messageId,
    required this.snippet,
    required this.sentAt,
  });

  /// The ID of the conversation that contains the matching message.
  final String conversationId;

  /// Display name of the conversation (group name or contact name).
  /// May be null when the name is not stored locally.
  final String? conversationName;

  /// The ID of the message that matched the search query.
  final String messageId;

  /// A short excerpt of the matched message text, suitable for display in
  /// search results.
  final String snippet;

  /// UTC timestamp when the matching message was sent.
  final DateTime sentAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.conversationId == conversationId &&
        other.conversationName == conversationName &&
        other.messageId == messageId &&
        other.snippet == snippet &&
        other.sentAt == sentAt;
  }

  @override
  int get hashCode =>
      Object.hash(conversationId, conversationName, messageId, snippet, sentAt);

  @override
  String toString() =>
      'SearchResult('
      'conversationId: $conversationId, '
      'messageId: $messageId, '
      'snippet: $snippet, '
      'sentAt: $sentAt'
      ')';
}
