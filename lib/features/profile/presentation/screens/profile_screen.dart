import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/core/router/app_router.dart';

/// Displays the user's profile information and provides access to
/// privacy settings, two-step verification, and account settings.
///
/// Requirements: 12.1
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile header ──────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Name',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Hey there! I am using WhatsApp',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Settings list ───────────────────────────────────────
          _buildSettingsTile(
            context,
            icon: Icons.key,
            title: 'Security',
            subtitle: 'Security code verification',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Last seen, profile photo, status',
            onTap: () => context.push(AppRoutes.privacySettings),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Two-step verification',
            subtitle: 'Protect your account with a PIN',
            onTap: () => context.push(AppRoutes.twoStepVerification),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.settings_outlined,
            title: 'Account',
            subtitle: 'Delete my account, change number',
            onTap: () => context.push(AppRoutes.accountSettings),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help',
            subtitle: 'FAQ, contact us, privacy policy',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}