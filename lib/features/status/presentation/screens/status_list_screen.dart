import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';
import 'package:whatsapp2_0/features/status/domain/entities/status_item.dart';
import 'package:whatsapp2_0/features/status/presentation/providers/status_providers.dart';

/// Displays the current user's own statuses and a list of contacts' statuses
/// in a scrollable feed, similar to WhatsApp's Status tab.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4
class StatusListScreen extends ConsumerWidget {
  const StatusListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder: In a real app, get the current user's ID from SessionManager.
    const currentUserId = 'current_user';

    final myStatusesAsync = ref.watch(statusListProvider(currentUserId));
    final contactStatusesAsync = ref.watch(contactStatusesProvider(currentUserId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Camera',
            onPressed: () => context.push(AppRoutes.statusCreator),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle privacy settings, status privacy, etc.
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'privacy', child: Text('Status privacy')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Trigger manual refresh
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // ── My Status ──────────────────────────────────────────────
            _buildMyStatusSection(context, ref, myStatusesAsync, currentUserId),
            const Divider(height: 1),

            // ── Recent Updates ─────────────────────────────────────────
            _buildRecentUpdatesSection(context, ref, contactStatusesAsync),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'camera',
            onPressed: () => context.push(AppRoutes.statusCreator),
            child: const Icon(Icons.camera_alt, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'text',
            onPressed: () => context.push(AppRoutes.statusCreator),
            child: const Icon(Icons.edit_note, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildMyStatusSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<StatusListState> myStatusesAsync,
    String currentUserId,
  ) {
    return myStatusesAsync.when(
      data: (state) {
        if (state.myStatuses.isEmpty) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('My status'),
            subtitle: const Text('Tap to add status update'),
            onTap: () => context.push(AppRoutes.statusCreator),
          );
        }

        final latest = state.myStatuses.first;
        final expiryChecker = ref.read(statusExpiryCheckerProvider);
        final remaining = expiryChecker.remainingTime(
          postedAt: latest.postedAt,
          queryTime: DateTime.now(),
        );

        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.person),
              ),
              // Online indicator ring
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          title: const Text('My status'),
          subtitle: Text(remaining.isNegative
              ? 'Expired'
              : 'Expires in ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.myStatuses.length > 1)
                Text(
                  '${state.myStatuses.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  // TODO: Handle delete, share
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  const PopupMenuItem(value: 'share', child: Text('Share')),
                ],
              ),
            ],
          ),
          onTap: () {
            context.push(
              '${AppRoutes.statusViewer.replaceFirst(':userId', currentUserId).replaceFirst(':statusId', latest.id)}',
            );
          },
        );
      },
      loading: () => const ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('My status'),
      ),
      error: (error, _) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.error_outline)),
        title: const Text('My status'),
        subtitle: Text(error.toString()),
      ),
    );
  }

  Widget _buildRecentUpdatesSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<StatusItem>> contactStatusesAsync,
  ) {
    return contactStatusesAsync.when(
      data: (statuses) {
        if (statuses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent updates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact status updates will appear here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Recent updates',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            ...statuses.map((status) => _buildContactStatusTile(
              context,
              ref,
              status,
            )),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContactStatusTile(
    BuildContext context,
    WidgetRef ref,
    StatusItem status,
  ) {
    final expiryChecker = ref.read(statusExpiryCheckerProvider);
    final remaining = expiryChecker.remainingTime(
      postedAt: status.postedAt,
      queryTime: DateTime.now(),
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          status.userId.isNotEmpty
              ? status.userId[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(status.userId), // In production, use contact display name
      subtitle: Text(
        status.text ??
            (status.mediaUrl != null ? 'Photo/Video' : 'Status update'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatDuration(remaining),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      onTap: () {
        context.push(
          '${AppRoutes.statusViewer.replaceFirst(':userId', status.userId).replaceFirst(':statusId', status.id)}',
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) return 'Expired';
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }
}