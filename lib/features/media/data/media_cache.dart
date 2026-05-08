import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// LRU disk cache for downloaded media files.
///
/// Files are stored in the app's cache directory under `media_cache/`.
/// The cache evicts the oldest files when the total size exceeds
/// [maxCacheSizeBytes] (100 MB).
///
/// Requirements: 6.6
class MediaCache {
  MediaCache._();

  static const int maxCacheSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const String _cacheSubdir = 'media_cache';

  /// Returns the cache directory, creating it if it does not exist.
  static Future<Directory> _cacheDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory(p.join(base.path, _cacheSubdir));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Derives a stable cache filename from [url] using its MD5 hash.
  static String _cacheKey(String url) {
    final bytes = utf8.encode(url);
    return md5.convert(bytes).toString();
  }

  /// Returns the cached [File] for [url], or `null` if not cached.
  static Future<File?> get(String url) async {
    final dir = await _cacheDir();
    final file = File(p.join(dir.path, _cacheKey(url)));
    if (file.existsSync()) {
      // Touch the file to update its last-modified time (LRU tracking).
      file.setLastModifiedSync(DateTime.now());
      return file;
    }
    return null;
  }

  /// Stores [file] in the cache under the key derived from [url].
  ///
  /// Evicts old files if the cache exceeds [maxCacheSizeBytes].
  static Future<void> put(String url, File file) async {
    final dir = await _cacheDir();
    final dest = File(p.join(dir.path, _cacheKey(url)));
    await file.copy(dest.path);
    await _evictIfNeeded(dir);
  }

  /// Removes the cached file for [url], if present.
  static Future<void> remove(String url) async {
    final dir = await _cacheDir();
    final file = File(p.join(dir.path, _cacheKey(url)));
    if (file.existsSync()) file.deleteSync();
  }

  /// Clears all cached files.
  static Future<void> clear() async {
    final dir = await _cacheDir();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Evicts the oldest files until the total cache size is below
  /// [maxCacheSizeBytes].
  static Future<void> _evictIfNeeded(Directory dir) async {
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    int totalSize = files.fold(0, (sum, f) => sum + f.lengthSync());

    for (final file in files) {
      if (totalSize <= maxCacheSizeBytes) break;
      totalSize -= file.lengthSync();
      file.deleteSync();
    }
  }
}
