import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp2_0/features/media/data/media_cache.dart';
import 'package:whatsapp2_0/features/media/data/media_repository_impl.dart';
import 'package:whatsapp2_0/features/media/domain/auto_download_policy.dart';
import 'package:whatsapp2_0/features/media/domain/media_repository.dart';

/// Provides the [MediaRepository] implementation backed by Firebase Storage.
///
/// Requirements: 6.2, 6.3, 6.4, 6.8
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl();
});

/// Provides the [AutoDownloadPolicy] for media auto-download decisions.
///
/// Requirements: 6.7
final autoDownloadPolicyProvider = Provider<AutoDownloadPolicy>((ref) {
  return AutoDownloadPolicy();
});

/// Exposes [MediaCache] as a provider for dependency injection in tests.
///
/// Requirements: 6.6
final mediaCacheProvider = Provider<Type>((ref) => MediaCache);
