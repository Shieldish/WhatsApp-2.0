import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/features/presence/data/presence_repository_impl.dart';
import 'package:whatsapp2_0/features/presence/domain/entities/presence_info.dart';
import 'package:whatsapp2_0/features/presence/domain/presence_heartbeat_service.dart';
import 'package:whatsapp2_0/features/presence/domain/presence_privacy_filter.dart';
import 'package:whatsapp2_0/features/presence/domain/presence_repository.dart';

/// Provides the [FirebaseFirestore] instance (shared).
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provides the [PresenceRepository] implementation backed by Firestore.
final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return PresenceRepositoryImpl(firestore: firestore);
});

/// Provides the [PresenceHeartbeatService].
final presenceHeartbeatServiceProvider = Provider<PresenceHeartbeatService>((
  ref,
) {
  final repository = ref.watch(presenceRepositoryProvider);
  final service = PresenceHeartbeatService(repository: repository);
  ref.onDispose(service.dispose);
  return service;
});

/// Provides the [PresencePrivacyFilter].
final presencePrivacyFilterProvider = Provider<PresencePrivacyFilter>((ref) {
  return PresencePrivacyFilter();
});

/// Provider that streams the presence of a specific user.
final presenceStreamProvider =
    StreamProvider.family<PresenceInfo, String>((ref, userId) {
  final repository = ref.watch(presenceRepositoryProvider);
  return repository.watchPresence(userId);
});

/// Provider that gives a formatted "last seen" text for a user.
final lastSeenTextProvider = Provider.family<String, PresenceInfo>((ref, info) {
  if (info.isOnline) return 'online';
  if (info.lastSeen == null) return '';
  final now = DateTime.now();
  final lastSeen = info.lastSeen!;
  final diff = now.difference(lastSeen);

  if (diff.inMinutes < 1) return 'last seen just now';
  if (diff.inMinutes < 60) return 'last seen ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'last seen ${diff.inHours}h ago';
  if (diff.inDays < 7) return 'last seen ${diff.inDays}d ago';
  return 'last seen on ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
});