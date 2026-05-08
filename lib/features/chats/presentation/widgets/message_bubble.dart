import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';
import 'package:whatsapp2_0/features/chats/presentation/providers/chat_providers.dart';

/// A single chat message bubble.
///
/// - Sent messages are right-aligned with a green background.
/// - Received messages are left-aligned with a white/surface background.
/// - Deleted messages show "This message was deleted" in italic.
/// - Delivery receipt icons are shown for sent messages:
///   - ✓  (grey)  = sent
///   - ✓✓ (grey)  = delivered
///   - ✓✓ (blue)  = read
/// - If [message.quotedMessageId] is set, a quoted message preview is shown
///   above the text.
/// - Long-press opens a bottom sheet with: Reply, Copy, Delete for me,
///   Delete for everyone (only within 60 minutes of sending).
///
/// Requirements: 4.2, 4.3, 4.4, 4.5, 4.7, 4.8, 4.9
class MessageBubble extends ConsumerWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.onReply,
    this.onDeleteForMe,
    this.onDeleteForEveryone,
  });

  final Message message;
  final String currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;

  bool get _isSentByMe => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSent = _isSentByMe;

    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showContextMenu(context, ref),
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isSent ? 64 : 8,
            right: isSent ? 8 : 64,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSent
                ? const Color(0xFFDCF8C6) // WhatsApp green
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isSent ? 12 : 0),
              bottomRight: Radius.circular(isSent ? 0 : 12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quoted message preview
              if (message.quotedMessageId != null)
                _QuotedMessagePreview(
                  quotedMessageId: message.quotedMessageId!,
                  conversationId: message.conversationId,
                ),

              // Message content
              _MessageContent(message: message),

              // Timestamp + delivery receipt row
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.sentAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  if (isSent) ...[
                    const SizedBox(width: 4),
                    _DeliveryReceiptIcon(status: message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref) {
    final canDeleteForEveryone =
        _isSentByMe &&
        DateTime.now().difference(message.sentAt) <=
            const Duration(minutes: 60);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.of(ctx).pop();
                onReply?.call();
              },
            ),

            // Copy (only for non-deleted text messages)
            if (!message.deletedForEveryone &&
                message.type == MessageType.text &&
                message.plaintext != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Clipboard.setData(ClipboardData(text: message.plaintext!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

            // Delete for me
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for me'),
              onTap: () {
                Navigator.of(ctx).pop();
                onDeleteForMe?.call();
              },
            ),

            // Delete for everyone (only within 60 min window for sent messages)
            if (canDeleteForEveryone)
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Delete for everyone'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDeleteForEveryone?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// Message content
// ---------------------------------------------------------------------------

class _MessageContent extends StatelessWidget {
  const _MessageContent({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (message.deletedForEveryone) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'This message was deleted',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Text(
      message.plaintext ?? '',
      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery receipt icon
// ---------------------------------------------------------------------------

class _DeliveryReceiptIcon extends StatelessWidget {
  const _DeliveryReceiptIcon({required this.status});

  final DeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      DeliveryStatus.sending => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
      DeliveryStatus.sent => const Icon(
        Icons.check,
        size: 14,
        color: Colors.black54,
      ),
      DeliveryStatus.delivered => const Icon(
        Icons.done_all,
        size: 14,
        color: Colors.black54,
      ),
      DeliveryStatus.read => const Icon(
        Icons.done_all,
        size: 14,
        color: Color(0xFF4FC3F7), // blue
      ),
      DeliveryStatus.failed => const Icon(
        Icons.error_outline,
        size: 14,
        color: Colors.red,
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Quoted message preview
// ---------------------------------------------------------------------------

class _QuotedMessagePreview extends ConsumerWidget {
  const _QuotedMessagePreview({
    required this.quotedMessageId,
    required this.conversationId,
  });

  final String quotedMessageId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(messagesStreamProvider(conversationId));

    return messagesAsync.when(
      data: (messages) {
        final quoted = messages
            .where((m) => m.id == quotedMessageId)
            .firstOrNull;
        if (quoted == null) return const SizedBox.shrink();

        return _QuotedContent(message: quoted);
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _QuotedContent extends StatelessWidget {
  const _QuotedContent({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message.deletedForEveryone
        ? 'This message was deleted'
        : (message.plaintext ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.black87,
          fontStyle: message.deletedForEveryone
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    );
  }
}
