import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/contacts/domain/entities/app_contact.dart';
import 'package:whatsapp2_0/features/contacts/presentation/providers/contact_providers.dart';
import 'package:whatsapp2_0/features/contacts/presentation/screens/manual_contact_entry_screen.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Internal state for the contact list screen.
class _ContactListState {
  const _ContactListState({
    this.contacts = const [],
    this.isLoading = false,
    this.permissionDenied = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  final List<AppContact> contacts;
  final bool isLoading;
  final bool permissionDenied;
  final String? errorMessage;
  final String searchQuery;

  _ContactListState copyWith({
    List<AppContact>? contacts,
    bool? isLoading,
    bool? permissionDenied,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
  }) {
    return _ContactListState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Returns contacts filtered by [searchQuery] (case-insensitive name match).
  List<AppContact> get filteredContacts {
    if (searchQuery.isEmpty) return contacts;
    final q = searchQuery.toLowerCase();
    return contacts
        .where((c) => c.displayName.toLowerCase().contains(q))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class _ContactListNotifier extends Notifier<_ContactListState> {
  @override
  _ContactListState build() {
    // Auto-sync on first build.
    Future.microtask(sync);
    return const _ContactListState();
  }

  /// Triggers a contact sync via [ContactSyncUseCase].
  Future<void> sync() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final useCase = ref.read(contactSyncUseCaseProvider);
    final result = await useCase.sync();

    switch (result) {
      case Ok(:final value):
        state = state.copyWith(
          contacts: value,
          isLoading: false,
          permissionDenied: false,
        );
      case Err(:final error):
        final isPermission = error is PermissionError;
        state = state.copyWith(
          isLoading: false,
          permissionDenied: isPermission,
          errorMessage: isPermission ? null : error.toString(),
        );
    }
  }

  /// Updates the search query.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final _contactListProvider =
    NotifierProvider.autoDispose<_ContactListNotifier, _ContactListState>(
      _ContactListNotifier.new,
    );

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Displays the list of registered contacts discovered from the device
/// address book.
///
/// - Shows a search bar to filter contacts by name.
/// - Auto-syncs on first load via [ContactSyncUseCase].
/// - If permission is denied, shows a banner with options to grant permission
///   or enter a number manually.
/// - Tapping a contact navigates to the chat screen for that contact.
///
/// Requirements: 2.2, 2.3
class ContactListScreen extends ConsumerStatefulWidget {
  const ContactListScreen({super.key});

  @override
  ConsumerState<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends ConsumerState<ContactListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(_contactListProvider.notifier).setSearchQuery(query);
  }

  void _onSync() {
    ref.read(_contactListProvider.notifier).sync();
  }

  void _onContactTap(AppContact contact) {
    // Navigate to the chat screen for this contact.
    // The conversationId for a direct chat is derived from the contact's userId.
    context.push('/chats/${contact.userId}', extra: contact);
  }

  void _onGrantPermission() {
    // Re-trigger sync which will re-request permission.
    ref.read(_contactListProvider.notifier).sync();
  }

  void _onEnterManually() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ManualContactEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_contactListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync contacts',
            onPressed: state.isLoading ? null : _onSync,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Permission denied banner ──────────────────────────────────────
          if (state.permissionDenied)
            _PermissionDeniedBanner(
              onGrantPermission: _onGrantPermission,
              onEnterManually: _onEnterManually,
            ),

          // ── Error banner ──────────────────────────────────────────────────
          if (state.errorMessage != null)
            _ErrorBanner(message: state.errorMessage!),

          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── Contact list ──────────────────────────────────────────────────
          Expanded(child: _buildBody(state, theme)),
        ],
      ),
    );
  }

  Widget _buildBody(_ContactListState state, ThemeData theme) {
    if (state.isLoading && state.contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final contacts = state.filteredContacts;

    if (contacts.isEmpty && !state.permissionDenied) {
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
              state.searchQuery.isNotEmpty
                  ? 'No contacts match "${state.searchQuery}"'
                  : 'No registered contacts found.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (state.searchQuery.isEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _onSync,
                icon: const Icon(Icons.refresh),
                label: const Text('Sync contacts'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _ContactTile(
          contact: contact,
          onTap: () => _onContactTap(contact),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// A single contact row in the list.
class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onTap});

  final AppContact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
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
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        contact.phoneNumber,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Banner shown when address-book permission is denied.
class _PermissionDeniedBanner extends StatelessWidget {
  const _PermissionDeniedBanner({
    required this.onGrantPermission,
    required this.onEnterManually,
  });

  final VoidCallback onGrantPermission;
  final VoidCallback onEnterManually;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.contacts_outlined,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Contacts permission denied.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onGrantPermission,
            child: Text(
              'Grant',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: onEnterManually,
            child: Text(
              'Enter number',
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown when a non-permission error occurs during sync.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
