import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/presentation/providers/chat_providers.dart';

/// The main chat list screen showing all non-archived conversations.
///
/// Features:
/// - [ListView] of conversation tiles sorted by [lastMessageAt] descending.
/// - Unread badge count on each tile.
/// - Swipe right (start-to-end) to archive a conversation.
/// - Swipe left (end-to-start) or long-press to delete with confirmation.
/// - FAB to navigate to [ContactListScreen] to start a new chat.
/// - Search icon in the app bar navigates to [SearchScreen].
///
/// Requirements: 3.1, 3.2, 3.3, 3.4, 3.5
class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('WhatsApp'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push(AppRoutes.search),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'archived') {
                _showArchivedChats(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'archived', child: Text('Archived')),
            ],
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) => _buildList(context, ref, conversations),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load chats: $e',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.contactList),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        tooltip: 'New chat',
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Conversation> conversations,
  ) {
    if (conversations.isEmpty) {
      return const _EmptyState();
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72, endIndent: 0),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _ConversationTile(
          conversation: conversation,
          onArchive: () => _archiveConversation(context, ref, conversation),
          onDelete: () => _confirmDelete(context, ref, conversation),
          onTap: () => context.push('/chats/${conversation.id}'),
        );
      },
    );
  }

  Future<void> _archiveConversation(
    BuildContext context,
    WidgetRef ref,
    Conversation conversation,
  ) async {
    final repo = ref.read(conversationRepositoryProvider);
    final result = await repo.archiveConversation(conversation.id);

    if (!context.mounted) return;

    if (result is Err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to archive chat')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chat archived'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await ref
                  .read(conversationRepositoryProvider)
                  .unarchiveConversation(conversation.id);
            },
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Conversation conversation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'This will permanently delete all messages in this chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repo = ref.read(conversationRepositoryProvider);
    final result = await repo.deleteConversation(conversation.id);

    if (!context.mounted) return;

    if (result is Err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete chat')));
    }
  }

  void _showArchivedChats(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _ArchivedChatsScreen()),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation tile
// ---------------------------------------------------------------------------

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  final Conversation conversation;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(conversation.id),
      // Swipe right → archive
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.green.shade600,
        icon: Icons.archive,
        label: 'Archive',
      ),
      // Swipe left → delete
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: Colors.red.shade600,
        icon: Icons.delete,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onArchive();
          return false; // handled manually; don't remove from list
        } else {
          onDelete();
          return false; // handled manually with confirmation dialog
        }
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _Avatar(conversation: conversation),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayName(conversation),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Timestamp(conversation: conversation),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessagePreview ?? '',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          _UnreadBadge(count: conversation.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(Conversation c) {
    if (c.type == ConversationType.group && c.groupName != null) {
      return c.groupName!;
    }
    // For direct chats the name comes from the contact list (later tasks).
    return c.id;
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGroup = conversation.type == ConversationType.group;
    final iconUrl = conversation.groupIconUrl;

    return CircleAvatar(
      radius: 26,
      backgroundImage: iconUrl != null ? NetworkImage(iconUrl) : null,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: iconUrl == null
          ? Icon(
              isGroup ? Icons.group : Icons.person,
              color: theme.colorScheme.onPrimaryContainer,
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Timestamp
// ---------------------------------------------------------------------------

class _Timestamp extends StatelessWidget {
  const _Timestamp({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final ts = conversation.lastMessageAt;
    if (ts == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(ts.year, ts.month, ts.day);

    String label;
    if (msgDay == today) {
      // Today: show time
      final h = ts.hour.toString().padLeft(2, '0');
      final m = ts.minute.toString().padLeft(2, '0');
      label = '$h:$m';
    } else if (today.difference(msgDay).inDays == 1) {
      label = 'Yesterday';
    } else {
      // Older: show date
      label =
          '${ts.day.toString().padLeft(2, '0')}/'
          '${ts.month.toString().padLeft(2, '0')}/'
          '${ts.year}';
    }

    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unread badge
// ---------------------------------------------------------------------------

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipe background
// ---------------------------------------------------------------------------

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 72,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the chat button to start a conversation.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Archived chats screen
// ---------------------------------------------------------------------------

class _ArchivedChatsScreen extends ConsumerWidget {
  const _ArchivedChatsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedConversationsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: archivedAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Text(
                'No archived chats',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/chats/${conversation.id}');
                },
                onArchive: () async {
                  final repo = ref.read(conversationRepositoryProvider);
                  await repo.unarchiveConversation(conversation.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat unarchived')),
                    );
                  }
                },
                onDelete: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete chat?'),
                      content: const Text(
                        'This will permanently delete all messages in this chat.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(ctx).colorScheme.error,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true || !context.mounted) return;
                  await ref
                      .read(conversationRepositoryProvider)
                      .deleteConversation(conversation.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
