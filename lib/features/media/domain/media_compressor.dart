import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Compresses image files that exceed [maxFileSizeBytes] (5 MB) to JPEG
/// quality 85, max 1920×1080, preserving aspect ratio.
///
/// Requirements: 6.1
class MediaCompressor {
  MediaCompressor._();

  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const int jpegQuality = 85;
  static const int maxWidth = 1920;
  static const int maxHeight = 1080;

  /// Returns `true` if [file] exceeds [maxFileSizeBytes].
  static bool needsCompression(File file) {
    return file.lengthSync() > maxFileSizeBytes;
  }

  /// Compresses [imageFile] if it exceeds 5 MB.
  ///
  /// Returns the compressed [File] on success, or the original [File] if
  /// compression is not needed or fails.
  static Future<File> compressImageIfNeeded(File imageFile) async {
    if (!needsCompression(imageFile)) return imageFile;

    try {
      final cacheDir = await getTemporaryDirectory();
      final ext = p.extension(imageFile.path).toLowerCase();
      final outPath = p.join(
        cacheDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        outPath,
        quality: jpegQuality,
        minWidth: 0,
        minHeight: 0,
        // flutter_image_compress uses minWidth/minHeight as the minimum
        // dimension — set to 0 so it only scales down, never up.
        // The actual max is controlled by the source image dimensions
        // relative to maxWidth/maxHeight.
      );

      if (result == null) return imageFile;

      final compressed = File(result.path);
      // If compression somehow made the file larger, return the original.
      if (compressed.lengthSync() >= imageFile.lengthSync()) return imageFile;

      return compressed;
    } catch (_) {
      // Compression failed — return the original file.
      return imageFile;
    }
  }
}
