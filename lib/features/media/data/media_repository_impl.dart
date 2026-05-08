import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:whatsapp2_0/core/result.dart';
import 'package:whatsapp2_0/features/media/data/media_cache.dart';
import 'package:whatsapp2_0/features/media/domain/media_repository.dart';

/// Concrete Firebase Storage-backed implementation of [MediaRepository].
///
/// Requirements: 6.2, 6.3, 6.4, 6.6, 6.8
class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Active upload tasks keyed by uploadId.
  final Map<String, UploadTask> _uploadTasks = {};

  /// Pending retry info keyed by uploadId: (file, mediaType, conversationId).
  final Map<String, _PendingUpload> _pendingUploads = {};

  // ---------------------------------------------------------------------------
  // uploadMedia
  // ---------------------------------------------------------------------------

  @override
  Future<Result<String, AppError>> uploadMedia(
    File file,
    String mediaType,
    String conversationId,
  ) async {
    final uploadId = _generateUploadId();
    return _doUpload(uploadId, file, mediaType, conversationId);
  }

  Future<Result<String, AppError>> _doUpload(
    String uploadId,
    File file,
    String mediaType,
    String conversationId,
  ) async {
    try {
      final filename =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      final ref = _storage.ref('media/$conversationId/$filename');

      final metadata = SettableMetadata(contentType: _contentType(mediaType));
      final task = ref.putFile(file, metadata);
      _uploadTasks[uploadId] = task;
      _pendingUploads[uploadId] = _PendingUpload(
        file: file,
        mediaType: mediaType,
        conversationId: conversationId,
      );

      await task;
      final url = await ref.getDownloadURL();
      _uploadTasks.remove(uploadId);
      return Ok(url);
    } on FirebaseException catch (e) {
      _uploadTasks.remove(uploadId);
      return Err(MediaError(message: 'Upload failed: ${e.message ?? e.code}'));
    } catch (e) {
      _uploadTasks.remove(uploadId);
      return Err(MediaError(message: 'Upload failed: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // uploadProgress
  // ---------------------------------------------------------------------------

  @override
  Stream<double> uploadProgress(String uploadId) {
    final task = _uploadTasks[uploadId];
    if (task == null) return const Stream.empty();

    return task.snapshotEvents.map((snapshot) {
      final total = snapshot.totalBytes;
      if (total == 0) return 0.0;
      return snapshot.bytesTransferred / total;
    });
  }

  // ---------------------------------------------------------------------------
  // downloadMedia
  // ---------------------------------------------------------------------------

  @override
  Future<Result<File, AppError>> downloadMedia(
    String url,
    String messageId,
  ) async {
    // Check cache first.
    final cached = await MediaCache.get(url);
    if (cached != null) return Ok(cached);

    try {
      final ref = _storage.refFromURL(url);
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        p.join(
          tempDir.path,
          '${messageId}_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      await ref.writeToFile(tempFile);

      // Store in cache.
      await MediaCache.put(url, tempFile);

      return Ok(tempFile);
    } on FirebaseException catch (e) {
      return Err(
        MediaError(message: 'Download failed: ${e.message ?? e.code}'),
      );
    } catch (e) {
      return Err(MediaError(message: 'Download failed: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // retryFailedUpload
  // ---------------------------------------------------------------------------

  @override
  Future<Result<String, AppError>> retryFailedUpload(String uploadId) async {
    final pending = _pendingUploads[uploadId];
    if (pending == null) {
      return Err(
        MediaError(message: 'No pending upload found for id: $uploadId'),
      );
    }

    const delays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    for (var attempt = 0; attempt < delays.length; attempt++) {
      await Future<void>.delayed(delays[attempt]);

      final result = await _doUpload(
        uploadId,
        pending.file,
        pending.mediaType,
        pending.conversationId,
      );

      if (result.isOk) {
        _pendingUploads.remove(uploadId);
        return result;
      }

      // Last attempt — return the error.
      if (attempt == delays.length - 1) {
        _pendingUploads.remove(uploadId);
        return result;
      }
    }

    return Err(MediaError(message: 'Upload failed after 3 retries.'));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String _generateUploadId() {
    return 'upload_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _contentType(String mediaType) {
    return switch (mediaType.toLowerCase()) {
      'image' => 'image/jpeg',
      'video' => 'video/mp4',
      'audio' => 'audio/aac',
      'document' => 'application/octet-stream',
      _ => 'application/octet-stream',
    };
  }
}

class _PendingUpload {
  const _PendingUpload({
    required this.file,
    required this.mediaType,
    required this.conversationId,
  });

  final File file;
  final String mediaType;
  final String conversationId;
}
