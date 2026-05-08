import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/features/status/domain/entities/status_item.dart';
import 'package:whatsapp2_0/features/status/presentation/providers/status_providers.dart';

/// Provider for fetching a single status item.
final statusItemProvider = FutureProvider.family<StatusItem, StatusParams>((
  ref,
  params,
) async {
  final repository = ref.watch(statusRepositoryProvider);
  final result = await repository.getStatus(
    userId: params.userId,
    statusId: params.statusId,
  );
  return result.fold(
    onOk: (status) => status,
    onErr: (error) => throw error,
  );
});

/// Parameters for fetching a status.
class StatusParams {
  const StatusParams({required this.userId, required this.statusId});

  final String userId;
  final String statusId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusParams &&
          userId == other.userId &&
          statusId == other.statusId;

  @override
  int get hashCode => Object.hash(userId, statusId);
}

/// Full-screen status viewer with a progress bar at the top, the status
/// content (text or media preview) in the centre, and a viewer list at the
/// bottom when the user taps to see who viewed the status.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4
class StatusViewerScreen extends ConsumerStatefulWidget {
  const StatusViewerScreen({
    super.key,
    required this.userId,
    required this.statusId,
  });

  final String userId;
  final String statusId;

  @override
  ConsumerState<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends ConsumerState<StatusViewerScreen> {
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // Auto-close the viewer after 10 seconds (simulating story duration).
    _autoCloseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) context.pop();
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(
      statusItemProvider(StatusParams(
        userId: widget.userId,
        statusId: widget.statusId,
      )),
    );

    return statusAsync.when(
      data: (status) => _buildViewer(context, status),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _buildError(context, error.toString()),
    );
  }

  Widget _buildViewer(BuildContext context, StatusItem status) {
    // Record the view when the screen opens
    ref.read(recordStatusViewProvider(RecordViewParams(
      statusId: widget.statusId,
      userId: widget.userId,
      viewerId: 'current_user', // In production, use actual user ID
    )));

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          // Toggle viewer details or dismiss
        },
        onLongPress: () {
          // Show options (delete, share, etc.)
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background / Text Display ────────────────────────────
            _buildStatusContent(status),

            // ── Top bar: progress, close, more ────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  children: [
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: 1.0, // Placeholder
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User info and controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              status.userId.isNotEmpty
                                  ? status.userId[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status.userId, // In production, use display name
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              // TODO: Show more options
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => context.pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom: viewer count / send message ──────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Viewer count
                      if (status.viewers.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _showViewersDialog(context, status);
                          },
                          child: Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${status.viewers.length}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      // Reply / send message
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to chat with this user
                          context.pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.message_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(StatusItem status) {
    if (status.text != null && status.mediaUrl == null) {
      // Text-only status
      return Container(
        color: _parseColor(status.backgroundColor ?? '#128C7E'),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              status.text!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (status.mediaUrl != null) {
      // Media status — placeholder for image/video display
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Media: ${status.mediaUrl}',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              if (status.text != null) ...[
                const SizedBox(height: 16),
                Text(
                  status.text!,
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'Status not available',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  void _showViewersDialog(BuildContext context, StatusItem status) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Viewed by ${status.viewers.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(height: 1),
              if (status.viewers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No one has viewed this status yet'),
                  ),
                )
              else
                ...status.viewers.entries.map((entry) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        entry.key.isNotEmpty
                            ? entry.key[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(entry.key),
                    subtitle: Text(
                      'Viewed at ${entry.value.hour}:${entry.value.minute.toString().padLeft(2, '0')}',
                    ),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}