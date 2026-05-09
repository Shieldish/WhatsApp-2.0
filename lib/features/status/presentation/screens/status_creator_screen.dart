import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/features/status/presentation/providers/status_providers.dart';

/// Screen for creating a new text status with a background colour.
///
/// The user can enter text (up to 700 characters) and choose a background
/// colour. For media-based statuses (image/video up to 30 s), the user would
/// use the camera/gallery flow — this screen focuses on text status creation.
///
/// Requirements: 7.1, 7.2, 7.3, 7.4
class StatusCreatorScreen extends ConsumerStatefulWidget {
  const StatusCreatorScreen({super.key});

  @override
  ConsumerState<StatusCreatorScreen> createState() =>
      _StatusCreatorScreenState();
}

class _StatusCreatorScreenState extends ConsumerState<StatusCreatorScreen> {
  final _textController = TextEditingController();
  String _backgroundColor = '#128C7E'; // WhatsApp teal default
  bool _isPosting = false;

  /// Predefined background colours for text statuses.
  static const List<String> _backgroundColours = [
    '#128C7E', // WhatsApp teal
    '#075E54', // Dark teal
    '#25D366', // WhatsApp green
    '#34B7F1', // Light blue
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#FF5722', // Deep orange
    '#795548', // Brown
    '#607D8B', // Blue-grey
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parseColor(_backgroundColor),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Status', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _postStatus,
            child: const Text(
              'SEND',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Text input area ──────────────────────────────────────
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    maxLength: 700,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your status',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 24),
                      counterStyle: TextStyle(color: Colors.white38),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),

            // ── Colour picker ────────────────────────────────────────
            Container(
              color: Colors.black26,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Text(
                    'Background',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _backgroundColours.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final colour = _backgroundColours[index];
                        final isSelected = colour == _backgroundColor;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _backgroundColor = colour;
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _parseColor(colour),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : Border.all(color: Colors.white24),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _postStatus() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      // In production, get the actual user ID from SessionManager.
      const currentUserId = 'current_user';

      await ref.read(
        postStatusProvider(
          PostStatusParams(
            userId: currentUserId,
            text: text,
            backgroundColor: _backgroundColor,
          ),
        ).future,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Status posted')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
