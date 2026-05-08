import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whatsapp2_0/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:whatsapp2_0/features/auth/presentation/screens/phone_entry_screen.dart';
import 'package:whatsapp2_0/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/conversation.dart';
import 'package:whatsapp2_0/features/chats/presentation/screens/chat_list_screen.dart';
import 'package:whatsapp2_0/features/chats/presentation/screens/chat_screen.dart';
import 'package:whatsapp2_0/features/chats/presentation/screens/create_group_screen.dart';
import 'package:whatsapp2_0/features/chats/presentation/screens/group_info_screen.dart';
import 'package:whatsapp2_0/features/chats/presentation/screens/search_screen.dart';
import 'package:whatsapp2_0/features/contacts/presentation/screens/contact_list_screen.dart';
import 'package:whatsapp2_0/features/media/presentation/screens/media_viewer_screen.dart';

// ---------------------------------------------------------------------------
// Route name constants
// ---------------------------------------------------------------------------

/// Named route constants used throughout the app for type-safe navigation.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String phoneEntry = '/auth/phone';
  static const String otpVerification = '/auth/otp';
  static const String profileSetup = '/auth/profile-setup';
  static const String chatList = '/chats';
  static const String chat = '/chats/:conversationId';
  static const String groupInfo = '/chats/:conversationId/group-info';
  static const String createGroup = '/chats/create-group';
  static const String contactList = '/contacts';
  static const String statusList = '/status';
  static const String statusViewer = '/status/:userId/:statusId';
  static const String statusCreator = '/status/create';
  static const String incomingCall = '/calls/incoming/:callId';
  static const String activeCall = '/calls/active/:callId';
  static const String groupCall = '/calls/group/:callId';
  static const String profile = '/profile';
  static const String privacySettings = '/profile/privacy';
  static const String twoStepVerification = '/profile/two-step';
  static const String accountSettings = '/profile/account';
  static const String securityCode = '/chats/:conversationId/security-code';
  static const String mediaViewer = '/media/:messageId';
  static const String search = '/search';
}

// ---------------------------------------------------------------------------
// Placeholder screens (used until real screens are implemented in later tasks)
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Router configuration
// ---------------------------------------------------------------------------

/// Creates and returns the app's [GoRouter] instance.
///
/// Auth guard logic will be wired in Task 22 once [SessionManager] is
/// implemented. For now all routes are accessible without authentication.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // Splash / root — redirects based on auth state (wired in Task 22)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const _PlaceholderScreen(title: 'Splash'),
      ),

      // ── Auth flow ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.phoneEntry,
        name: 'phoneEntry',
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: AppRoutes.otpVerification,
        name: 'otpVerification',
        builder: (context, state) {
          // The phone number is passed as `extra` from PhoneEntryScreen.
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ── Chats ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chatList,
        name: 'chatList',
        builder: (context, state) => const ChatListScreen(),
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'chat',
            builder: (context, state) {
              final id = state.pathParameters['conversationId']!;
              // Extra may carry a map with contactName, recipientId, and
              // optionally a Conversation entity for group metadata.
              final extra = state.extra as Map<String, dynamic>?;
              return ChatScreen(
                conversationId: id,
                contactName: extra?['contactName'] as String?,
                recipientId: extra?['recipientId'] as String?,
                conversation: extra?['conversation'] as Conversation?,
              );
            },
            routes: [
              GoRoute(
                path: 'group-info',
                name: 'groupInfo',
                builder: (context, state) {
                  // The Conversation entity is passed as extra.
                  final conv = state.extra as Conversation?;
                  if (conv == null) {
                    return const _PlaceholderScreen(title: 'Group Info');
                  }
                  return GroupInfoScreen(conversation: conv);
                },
              ),
              GoRoute(
                path: 'security-code',
                name: 'securityCode',
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Security Code'),
              ),
            ],
          ),
        ],
      ),

      // ── Create Group ───────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),

      // ── Contacts ───────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.contactList,
        name: 'contactList',
        builder: (context, state) => const ContactListScreen(),
      ),

      // ── Status ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.statusList,
        name: 'statusList',
        builder: (context, state) => const _PlaceholderScreen(title: 'Status'),
        routes: [
          GoRoute(
            path: 'create',
            name: 'statusCreator',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Create Status'),
          ),
          GoRoute(
            path: ':userId/:statusId',
            name: 'statusViewer',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              final statusId = state.pathParameters['statusId']!;
              return _PlaceholderScreen(title: 'Status: $userId / $statusId');
            },
          ),
        ],
      ),

      // ── Calls ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/calls/incoming/:callId',
        name: 'incomingCall',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return _PlaceholderScreen(title: 'Incoming Call: $callId');
        },
      ),
      GoRoute(
        path: '/calls/active/:callId',
        name: 'activeCall',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return _PlaceholderScreen(title: 'Active Call: $callId');
        },
      ),
      GoRoute(
        path: '/calls/group/:callId',
        name: 'groupCall',
        builder: (context, state) {
          final callId = state.pathParameters['callId']!;
          return _PlaceholderScreen(title: 'Group Call: $callId');
        },
      ),

      // ── Profile & Settings ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const _PlaceholderScreen(title: 'Profile'),
        routes: [
          GoRoute(
            path: 'privacy',
            name: 'privacySettings',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Privacy Settings'),
          ),
          GoRoute(
            path: 'two-step',
            name: 'twoStepVerification',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Two-Step Verification'),
          ),
          GoRoute(
            path: 'account',
            name: 'accountSettings',
            builder: (context, state) =>
                const _PlaceholderScreen(title: 'Account Settings'),
          ),
        ],
      ),

      // ── Media viewer ───────────────────────────────────────────────────────
      GoRoute(
        path: '/media/:messageId',
        name: 'mediaViewer',
        builder: (context, state) {
          final messageId = state.pathParameters['messageId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return MediaViewerScreen(
            url: extra?['url'] as String? ?? '',
            messageId: messageId,
            mediaType: extra?['mediaType'] as String? ?? 'image',
            thumbnailUrl: extra?['thumbnailUrl'] as String?,
          );
        },
      ),

      // ── Search ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
    ],
  );
}
