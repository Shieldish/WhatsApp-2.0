import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/send_message_params.dart';
import 'package:whatsapp2_0/features/chats/presentation/providers/chat_providers.dart';
import 'package:whatsapp2_0/features/chats/presentation/screens/group_info_screen.dart';
import 'package:whatsapp2_0/features/chats/presentation/widgets/message_bubble.dart';
import 'package:whatsapp2_0/features/media/domain/location_message_builder.dart';
import 'package:whatsapp2_0/features/media/domain/media_compressor.dart';
import 'package:whatsapp2_0/features/media/presentation/providers/media_providers.dart';

/// The chat screen — supports both one-to-one and group conversations.
///
/// Features:
/// - App bar with contact/group name and a placeholder presence indicator.
/// - [ListView.builder] of [MessageBubble] widgets, auto-scrolling to the
///   bottom when new messages arrive.
/// - Text input bar at the bottom with an emoji placeholder button and a
///   send button.
/// - Calls [MessageRepository.markAsRead] when the screen opens.
/// - Starts a Firestore delivery receipt listener on init and stops it on
///   dispose.
/// - For group conversations with [messagingRestricted=true], shows a banner
///   and disables the input bar for non-admin members.
///
/// Requirements: 4.1, 4.2, 4.7, 4.8, 5.4, 5.5
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.contactName,
    this.recipientId,
    this.conversation,
  });

  /// The conversation to display.
  final String conversationId;

  /// Display name shown in the app bar (optional; falls back to conversationId).
  final String? contactName;

  /// The recipient's user ID used for encryption when sending messages.
  /// Falls back to [conversationId] if not provided.
  final String? recipientId;

  /// Optional pre-loaded [Conversation] entity carrying group metadata
  /// (adminIds, messagingRestricted). When provided, the screen uses this
  /// to determine whether the current user can send messages.
  final Conversation? conversation;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  /// The message being replied to (for quoting).
  Message? _quotedMessage;

  /// True once the conversation doc is confirmed to exist in Firestore.
  bool _conversationReady = false;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _recipientId => widget.recipientId ?? '';

  /// Returns true when the current user is restricted from sending messages.
  ///
  /// This is the case when:
  /// - The conversation is a group.
  /// - `messagingRestricted` is true.
  /// - The current user is NOT in `adminIds`.
  bool get _isMessagingRestricted {
    final conv = widget.conversation;
    if (conv == null) return false;
    if (conv.type != ConversationType.group) return false;
    if (!conv.messagingRestricted) return false;
    return !(conv.adminIds?.contains(_currentUserId) ?? false);
  }

  bool get _isGroupConversation =>
      widget.conversation?.type == ConversationType.group;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _ensureConversationExists();
    if (mounted) setState(() => _conversationReady = true);

    final repo = ref.read(messageRepositoryProvider);
    await repo.markAsRead(widget.conversationId);
    await repo.startDeliveryReceiptListener(widget.conversationId);
  }

  /// Creates the Firestore conversation document with participantIds if it
  /// doesn't exist yet. Required so Firestore security rules allow reads/writes.
  Future<void> _ensureConversationExists() async {
    final myUid = _currentUserId;
    final otherUid = _recipientId;
    if (myUid.isEmpty || otherUid.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId);

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'participantIds': [myUid, otherUid],
        'type': 'direct',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();

    // Stop the delivery receipt listener.
    ref
        .read(messageRepositoryProvider)
        .stopDeliveryReceiptListener(widget.conversationId);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );

    // Auto-scroll to bottom when new messages arrive.
    ref.listen(messagesStreamProvider(widget.conversationId), (_, next) {
      next.whenData((_) => _scrollToBottom());
    });

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp chat background
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _isGroupConversation ? _openGroupInfo : null,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  _isGroupConversation ? Icons.group : Icons.person,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contactName ?? widget.conversationId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Presence placeholder — wired in Task 16.5
                    Text(
                      _isGroupConversation
                          ? '${widget.conversation?.participantIds.length ?? 0} participants'
                          : 'tap here for contact info',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Video call',
            onPressed: () {}, // wired in Task 19
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Voice call',
            onPressed: () {}, // wired in Task 19
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (_) {},
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'search', child: Text('Search')),
              PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
              PopupMenuItem(value: 'wallpaper', child: Text('Wallpaper')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Admins-only messaging restriction banner
          if (_isMessagingRestricted) _AdminOnlyBanner(),

          // Message list
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessageList(messages),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load messages: $e',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),

          // Quoted message bar (shown when replying)
          if (_quotedMessage != null)
            _QuotedMessageBar(
              message: _quotedMessage!,
              onDismiss: () => setState(() => _quotedMessage = null),
            ),

          // Input bar — disabled for non-admin members in restricted groups
          if (!_isMessagingRestricted)
            _InputBar(
              controller: _textController,
              focusNode: _focusNode,
              onSend: _sendMessage,
              onAttach: _showAttachmentSheet,
            ),
        ],
      ),
    );
  }

  void _openGroupInfo() {
    final conv = widget.conversation;
    if (conv == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupInfoScreen(conversation: conv),
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages) {
    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nSay hello! 👋',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          currentUserId: _currentUserId,
          onReply: () => setState(() => _quotedMessage = message),
          onDeleteForMe: () => _deleteForMe(message),
          onDeleteForEveryone: () => _deleteForEveryone(message),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    if (!_conversationReady) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    final quoted = _quotedMessage;
    setState(() => _quotedMessage = null);

    final params = SendMessageParams(
      conversationId: widget.conversationId,
      recipientId: _recipientId,
      plaintext: text,
      quotedMessageId: quoted?.id,
    );

    final repo = ref.read(messageRepositoryProvider);
    final result = await repo.sendMessage(params);

    if (!mounted) return;

    if (result is Err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${result.errorOrNull}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteForMe(Message message) async {
    final repo = ref.read(messageRepositoryProvider);
    final result = await repo.deleteMessageForMe(message.id);

    if (!mounted) return;

    if (result is Err) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete message')));
    }
  }

  Future<void> _deleteForEveryone(Message message) async {
    final repo = ref.read(messageRepositoryProvider);
    final result = await repo.deleteMessageForEveryone(
      message.id,
      message.sentAt,
    );

    if (!mounted) return;

    if (result is Err) {
      final error = result.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ValidationError
                ? error.message
                : 'Failed to delete message for everyone',
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Media attachment (Task 13.8)
  // ---------------------------------------------------------------------------

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image / Video'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImageOrVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Voice Note'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showVoiceNoteRecorder();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Location'),
              onTap: () {
                Navigator.of(ctx).pop();
                _sendLocation();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageOrVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickMedia();
    if (picked == null || !mounted) return;

    final file = File(picked.path);
    final isVideo = picked.mimeType?.startsWith('video') ?? false;

    // Compress image if needed.
    final toUpload = isVideo
        ? file
        : await MediaCompressor.compressImageIfNeeded(file);

    await _uploadAndSendMedia(
      toUpload,
      isVideo ? 'video' : 'image',
      isVideo ? MessageType.video : MessageType.image,
    );
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty || !mounted) return;

    final path = result.files.first.path;
    if (path == null) return;

    await _uploadAndSendMedia(File(path), 'document', MessageType.document);
  }

  Future<void> _uploadAndSendMedia(
    File file,
    String mediaType,
    MessageType messageType,
  ) async {
    final mediaRepo = ref.read(mediaRepositoryProvider);
    final uploadResult = await mediaRepo.uploadMedia(
      file,
      mediaType,
      widget.conversationId,
    );

    if (!mounted) return;

    switch (uploadResult) {
      case Ok(:final value):
        final params = SendMessageParams(
          conversationId: widget.conversationId,
          recipientId: _recipientId,
          plaintext: '[${messageType.name}]',
          type: messageType,
          mediaUrl: value,
          mediaType: _toMediaType(messageType),
        );
        await ref.read(messageRepositoryProvider).sendMessage(params);
      case Err(:final error):
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Upload failed: $error')));
        }
    }
  }

  void _showVoiceNoteRecorder() {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      builder: (ctx) => _VoiceNoteRecorder(
        onSend: (File audioFile) async {
          Navigator.of(ctx).pop();
          await _uploadAndSendMedia(audioFile, 'audio', MessageType.audio);
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _sendLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final payload = LocationMessageBuilder.buildLocationPayload(
        position.latitude,
        position.longitude,
      );

      final params = SendMessageParams(
        conversationId: widget.conversationId,
        recipientId: _recipientId,
        plaintext:
            '📍 ${LocationMessageBuilder.formatCoordinates(position.latitude, position.longitude)}',
        type: MessageType.location,
        mediaUrl: payload['mapPreviewUrl'] as String?,
      );

      if (!mounted) return;
      await ref.read(messageRepositoryProvider).sendMessage(params);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    }
  }

  static MediaType? _toMediaType(MessageType type) {
    return switch (type) {
      MessageType.image => MediaType.image,
      MessageType.video => MediaType.video,
      MessageType.audio => MediaType.audio,
      MessageType.document => MediaType.document,
      _ => null,
    };
  }
}

// ---------------------------------------------------------------------------
// Admin-only messaging restriction banner
// ---------------------------------------------------------------------------

/// Banner shown at the top of the message list when the group has messaging
/// restricted to admins only and the current user is not an admin.
class _AdminOnlyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Only admins can send messages',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Emoji placeholder button
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: Colors.black54,
              onPressed: () {},
            ),

            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    // Attachment button
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      color: Colors.black54,
                      onPressed: onAttach,
                      tooltip: 'Attach',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Send / mic button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: hasText
                      ? FloatingActionButton.small(
                          key: const ValueKey('send'),
                          onPressed: onSend,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          child: const Icon(Icons.send),
                        )
                      : FloatingActionButton.small(
                          key: const ValueKey('mic'),
                          onPressed: onAttach,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          child: const Icon(Icons.mic),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quoted message bar (shown above input when replying)
// ---------------------------------------------------------------------------

class _QuotedMessageBar extends StatelessWidget {
  const _QuotedMessageBar({required this.message, required this.onDismiss});

  final Message message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message.deletedForEveryone
        ? 'This message was deleted'
        : (message.plaintext ?? '');

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: message.deletedForEveryone
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Voice note recorder (Task 13.8)
// ---------------------------------------------------------------------------

/// A bottom-sheet widget that records a voice note up to 2 minutes.
///
/// Shows a timer and stop/cancel buttons. Calls [onSend] with the recorded
/// file when the user taps "Send", or [onCancel] to discard.
///
/// Requirements: 6.9
class _VoiceNoteRecorder extends StatefulWidget {
  const _VoiceNoteRecorder({required this.onSend, required this.onCancel});

  final void Function(File audioFile) onSend;
  final VoidCallback onCancel;

  @override
  State<_VoiceNoteRecorder> createState() => _VoiceNoteRecorderState();
}

class _VoiceNoteRecorderState extends State<_VoiceNoteRecorder> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;
  int _elapsedSeconds = 0;
  Timer? _timer;

  static const int _maxSeconds = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      widget.onCancel();
      return;
    }

    final dir = Directory.systemTemp;
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordedPath = path;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _maxSeconds) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
  }

  Future<void> _sendRecording() async {
    if (_isRecording) await _stopRecording();
    final path = _recordedPath;
    if (path == null) {
      widget.onCancel();
      return;
    }
    widget.onSend(File(path));
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_off,
              size: 48,
              color: _isRecording ? theme.colorScheme.error : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _formatTime(_elapsedSeconds),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isRecording ? 'Recording…' : 'Recording stopped',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Cancel'),
                ),
                if (_isRecording)
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                  ),
                ElevatedButton.icon(
                  onPressed: _recordedPath != null ? _sendRecording : null,
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
