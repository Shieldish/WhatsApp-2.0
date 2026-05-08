import 'dart:io';

import 'package:whatsapp2_0/core/result.dart';

/// Abstract interface for media upload, download, and caching operations.
///
/// Requirements: 6.2, 6.3, 6.4, 6.8
abstract class MediaRepository {
  /// Uploads [file] to Firebase Storage under `media/{conversationId}/`.
  ///
  /// Returns [Ok] with the public download URL on success, or [Err] on
  /// failure. The upload is resumable and progress can be monitored via
  /// [uploadProgress].
  ///
  /// Requirements: 6.2, 6.3, 6.4
  Future<Result<String, AppError>> uploadMedia(
    File file,
    String mediaType,
    String conversationId,
  );

  /// Returns a stream of upload progress values (0.0 – 1.0) for the upload
  /// identified by [uploadId].
  ///
  /// Emits 1.0 when the upload completes.
  Stream<double> uploadProgress(String uploadId);

  /// Downloads the media file at [url] to the local cache directory.
  ///
  /// Returns [Ok] with the local [File] on success, or [Err] on failure.
  ///
  /// Requirements: 6.6
  Future<Result<File, AppError>> downloadMedia(String url, String messageId);

  /// Retries a failed upload identified by [uploadId] with exponential
  /// back-off (1 s, 2 s, 4 s delays, max 3 retries).
  ///
  /// Returns [Ok] with the download URL on success, or [Err] after all
  /// retries are exhausted.
  ///
  /// Requirements: 6.8
  Future<Result<String, AppError>> retryFailedUpload(String uploadId);
}
