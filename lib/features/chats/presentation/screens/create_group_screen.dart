import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/chats/presentation/providers/chat_providers.dart';
import 'package:whatsapp2_0/features/contacts/domain/entities/app_contact.dart';
import 'package:whatsapp2_0/features/contacts/presentation/providers/contact_providers.dart';

/// Screen for creating a new group conversation.
///
/// - Displays a multi-select list of the current user's contacts.
/// - Provides a text field for the group name.
/// - Calls [GroupRepository.createGroup] on confirmation.
/// - Navigates to the new group's [ChatScreen] on success.
///
/// Requirements: 5.1, 5.2
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _selectedIds = <String>{};
  bool _isCreating = false;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _toggleContact(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name.')),
      );
      return;
    }

    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one participant.'),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final repo = ref.read(groupRepositoryProvider);
    final result = await repo.createGroup(
      name: name,
      participantIds: _selectedIds.toList(),
      creatorId: _currentUserId,
    );

    if (!mounted) return;
    setState(() => _isCreating = false);

    switch (result) {
      case Ok(:final value):
        // Navigate to the new group's chat screen.
        context.pushReplacement(
          '/chats/${value.id}',
          extra: <String, String?>{'contactName': value.groupName},
        );
      case Err(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_isCreating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _selectedIds.isNotEmpty ? _createGroup : null,
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Group name input ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _groupNameController,
              maxLength: 100,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Group name',
                hintText: 'Enter group name',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ── Selected count ─────────────────────────────────────────────────
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_selectedIds.length} participant${_selectedIds.length == 1 ? '' : 's'} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

          // ── Contact list ───────────────────────────────────────────────────
          Expanded(
            child: contactsAsync.when(
              data: (contacts) => _buildContactList(contacts, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load contacts: $e',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(List<AppContact> contacts, ThemeData theme) {
    // Exclude the current user from the selectable list.
    final selectable = contacts
        .where((c) => c.userId != _currentUserId)
        .toList();

    if (selectable.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No contacts available.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: selectable.length,
      itemBuilder: (context, index) {
        final contact = selectable[index];
        final isSelected = _selectedIds.contains(contact.userId);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) => _toggleContact(contact.userId),
          secondary: CircleAvatar(
            radius: 22,
            backgroundImage: contact.photoUrl != null
                ? NetworkImage(contact.photoUrl!)
                : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: contact.photoUrl == null
                ? Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          title: Text(
            contact.displayName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            contact.phoneNumber,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.trailing,
        );
      },
    );
  }
}
