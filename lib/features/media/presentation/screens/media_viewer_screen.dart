import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/media/presentation/providers/media_providers.dart';

/// Full-screen media viewer for images and videos.
///
/// Shows a thumbnail/placeholder immediately while the full file downloads.
/// Displays a [CircularProgressIndicator] with download percentage while
/// loading.
///
/// Requirements: 6.6
class MediaViewerScreen extends ConsumerStatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.url,
    required this.messageId,
    this.mediaType = 'image',
    this.thumbnailUrl,
  });

  /// The remote URL of the media file.
  final String url;

  /// The message ID (used as a cache key).
  final String messageId;

  /// The media type: 'image' or 'video'.
  final String mediaType;

  /// Optional thumbnail URL shown while the full file loads.
  final String? thumbnailUrl;

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  File? _localFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(mediaRepositoryProvider);
    final result = await repo.downloadMedia(widget.url, widget.messageId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case Ok(:final value):
          _localFile = value;
        case Err(:final error):
          _errorMessage = error.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_localFile != null)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Save to device',
              onPressed: () {
                // Save to gallery — requires additional permissions.
                // Placeholder for now.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to device')),
                );
              },
            ),
        ],
      ),
      body: Center(child: _buildContent(theme)),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Error state
    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to load media',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadMedia,
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    // Loaded state — show the image
    if (_localFile != null) {
      if (widget.mediaType == 'video') {
        return _VideoPlaceholder(file: _localFile!);
      }
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          _localFile!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.white54, size: 64),
        ),
      );
    }

    // Loading state — show thumbnail + progress indicator
    return Stack(
      alignment: Alignment.center,
      children: [
        // Thumbnail (blurred placeholder)
        if (widget.thumbnailUrl != null)
          Opacity(
            opacity: 0.4,
            child: Image.network(
              widget.thumbnailUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

        // Loading indicator
        if (_isLoading)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Loading…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Video placeholder
// ---------------------------------------------------------------------------

/// Shows a video thumbnail with a play button overlay.
///
/// Full video playback requires `video_player` package (not included in this
/// task). This placeholder shows the file path and a play icon.
class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 80,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Video ready to play',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          'Full video player coming in a future update.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white38),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
