import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/presentation/providers/chat_providers.dart';

/// Screen displaying group information and admin controls.
///
/// Features:
/// - Group name, icon, and participant count.
/// - Paginated participant list (50 at a time via "Load more" button).
/// - Admin controls: add participant, remove participant, restrict messaging.
/// - "Leave group" button for all members.
///
/// Requirements: 5.1, 5.2, 5.4, 5.5, 5.8
class GroupInfoScreen extends ConsumerStatefulWidget {
  const GroupInfoScreen({super.key, required this.conversation});

  /// The group conversation whose info is being displayed.
  final Conversation conversation;

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  /// Participant IDs loaded so far (paginated).
  final List<String> _loadedParticipants = [];

  /// Whether there are more participants to load.
  bool _hasMore = true;

  /// Whether a page load is in progress.
  bool _isLoadingMore = false;

  /// Whether an admin action is in progress.
  bool _isActioning = false;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool get _isAdmin =>
      widget.conversation.adminIds?.contains(_currentUserId) ?? false;

  @override
  void initState() {
    super.initState();
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    _loadedParticipants.clear();
    _hasMore = true;
    await _loadNextPage();
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final repo = ref.read(groupRepositoryProvider);
    final afterUserId = _loadedParticipants.isNotEmpty
        ? _loadedParticipants.last
        : null;

    final result = await repo.getParticipantPage(
      widget.conversation.id,
      afterUserId: afterUserId,
      limit: 50,
    );

    if (!mounted) return;

    setState(() {
      _isLoadingMore = false;
      switch (result) {
        case Ok(:final value):
          _loadedParticipants.addAll(value);
          _hasMore = value.length == 50;
        case Err():
          _hasMore = false;
      }
    });
  }

  Future<void> _removeParticipant(String userId) async {
    setState(() => _isActioning = true);

    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.removeParticipant(
      widget.conversation.id,
      userId,
      _currentUserId,
    );

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove participant: ${result.errorOrNull}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      setState(() => _loadedParticipants.remove(userId));
    }
  }

  Future<void> _toggleMessagingRestriction() async {
    final restricted = widget.conversation.messagingRestricted;
    setState(() => _isActioning = true);

    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.restrictMessaging(
      widget.conversation.id,
      !restricted,
      _currentUserId,
    );

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update messaging restriction: ${result.errorOrNull}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _leaveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text(
          'Are you sure you want to leave "${widget.conversation.groupName ?? 'this group'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActioning = true);

    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.leaveGroup(
      widget.conversation.id,
      _currentUserId,
    );

    if (!mounted) return;
    setState(() => _isActioning = false);

    if (result is Ok) {
      // Navigate back to the chat list.
      context.go('/chats');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group: ${result.errorOrNull}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conv = widget.conversation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isActioning
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ── Group header ─────────────────────────────────────────────
                _GroupHeader(conversation: conv),

                const Divider(),

                // ── Admin controls ───────────────────────────────────────────
                if (_isAdmin) ...[
                  _SectionHeader(title: 'Admin Controls'),
                  SwitchListTile(
                    title: const Text('Only admins can send messages'),
                    subtitle: const Text(
                      'When enabled, only admins can send messages to this group.',
                    ),
                    value: conv.messagingRestricted,
                    onChanged: (_) => _toggleMessagingRestriction(),
                    activeThumbColor: theme.colorScheme.primary,
                  ),
                  const Divider(),
                ],

                // ── Participants ─────────────────────────────────────────────
                _SectionHeader(
                  title:
                      '${conv.participantIds.length} Participant${conv.participantIds.length == 1 ? '' : 's'}',
                ),

                ..._loadedParticipants.map(
                  (userId) => _ParticipantTile(
                    userId: userId,
                    isAdmin: conv.adminIds?.contains(userId) ?? false,
                    isCurrentUser: userId == _currentUserId,
                    canRemove: _isAdmin && userId != _currentUserId,
                    onRemove: () => _removeParticipant(userId),
                  ),
                ),

                // Load more button (shown when group > 256 participants).
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _isLoadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : OutlinedButton(
                            onPressed: _loadNextPage,
                            child: const Text('Load more participants'),
                          ),
                  ),

                const Divider(),

                // ── Leave group ──────────────────────────────────────────────
                ListTile(
                  leading: Icon(
                    Icons.exit_to_app,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Leave Group',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: _leaveGroup,
                ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Displays the group avatar, name, and participant count at the top.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.conversation});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          // Group icon
          CircleAvatar(
            radius: 48,
            backgroundImage: conversation.groupIconUrl != null
                ? NetworkImage(conversation.groupIconUrl!)
                : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: conversation.groupIconUrl == null
                ? Icon(
                    Icons.group,
                    size: 48,
                    color: theme.colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // Group name
          Text(
            conversation.groupName ?? 'Group',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Participant count
          Text(
            'Group · ${conversation.participantIds.length} participants',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A section header label.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A single participant row in the list.
class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.userId,
    required this.isAdmin,
    required this.isCurrentUser,
    required this.canRemove,
    required this.onRemove,
  });

  final String userId;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = isCurrentUser ? 'You' : userId;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: isAdmin
          ? Text(
              'Admin',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          : null,
      trailing: canRemove
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Theme.of(context).colorScheme.error,
              tooltip: 'Remove participant',
              onPressed: onRemove,
            )
          : null,
    );
  }
}
