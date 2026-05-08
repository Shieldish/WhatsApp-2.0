import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for configuring privacy settings: last seen, profile photo,
/// status bio, and read receipts.
///
/// Requirements: 12.2
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Last Seen ──────────────────────────────────────────
          _buildPrivacyOption(
            context,
            title: 'Last seen & online',
            subtitle: 'Who can see your last seen and online status',
            currentValue: 'My Contacts',
            onChanged: () {},
          ),
          const Divider(),

          // ── Profile Photo ──────────────────────────────────────
          _buildPrivacyOption(
            context,
            title: 'Profile photo',
            subtitle: 'Who can see your profile photo',
            currentValue: 'Everyone',
            onChanged: () {},
          ),
          const Divider(),

          // ── Status ─────────────────────────────────────────────
          _buildPrivacyOption(
            context,
            title: 'Status',
            subtitle: 'Who can see your status updates',
            currentValue: 'My Contacts',
            onChanged: () {},
          ),
          const Divider(),

          // ── Read Receipts ──────────────────────────────────────
          SwitchListTile(
            title: const Text('Read receipts'),
            subtitle: const Text(
              'If turned off, you won\'t send or receive read receipts',
            ),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),

          // ── Group invite ───────────────────────────────────────
          _buildPrivacyOption(
            context,
            title: 'Groups',
            subtitle: 'Who can add you to groups',
            currentValue: 'Everyone',
            onChanged: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String currentValue,
    required VoidCallback onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentValue,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onChanged,
    );
  }
}