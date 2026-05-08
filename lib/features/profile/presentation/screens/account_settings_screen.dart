import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for account-related settings: delete account, change number,
/// and export chat history.
///
/// Requirements: 12.6, 12.7
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAccountTile(
            context,
            icon: Icons.person_remove_outlined,
            title: 'Delete my account',
            subtitle: 'Permanently delete your account and all data',
            color: Colors.red,
            onTap: () => _confirmDeleteAccount(context),
          ),
          const Divider(),
          _buildAccountTile(
            context,
            icon: Icons.phone_android,
            title: 'Change number',
            subtitle: 'Move your account to a new phone number',
            onTap: () {},
          ),
          const Divider(),
          _buildAccountTile(
            context,
            icon: Icons.download_outlined,
            title: 'Export chat history',
            subtitle: 'Save your conversations to a file',
            onTap: () {},
          ),
          const Divider(),
          _buildAccountTile(
            context,
            icon: Icons.info_outline,
            title: 'Request account info',
            subtitle: 'Download your account information',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account, all messages, '
          'media, and profile data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion scheduled. All data will be removed '
                    'within 30 days.',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}