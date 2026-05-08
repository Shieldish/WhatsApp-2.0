import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whatsapp2_0/features/chats/domain/entities/message.dart';

/// User-configurable auto-download settings.
///
/// Requirements: 6.7
class AutoDownloadSettings {
  const AutoDownloadSettings({
    this.autoDownloadImagesOnWifi = true,
    this.autoDownloadImagesOnMobile = false,
    this.autoDownloadVideoOnWifi = false,
    this.autoDownloadVideoOnMobile = false,
    this.autoDownloadDocumentsOnWifi = false,
    this.autoDownloadDocumentsOnMobile = false,
  });

  final bool autoDownloadImagesOnWifi;
  final bool autoDownloadImagesOnMobile;
  final bool autoDownloadVideoOnWifi;
  final bool autoDownloadVideoOnMobile;
  final bool autoDownloadDocumentsOnWifi;
  final bool autoDownloadDocumentsOnMobile;

  Map<String, dynamic> toJson() => {
    'autoDownloadImagesOnWifi': autoDownloadImagesOnWifi,
    'autoDownloadImagesOnMobile': autoDownloadImagesOnMobile,
    'autoDownloadVideoOnWifi': autoDownloadVideoOnWifi,
    'autoDownloadVideoOnMobile': autoDownloadVideoOnMobile,
    'autoDownloadDocumentsOnWifi': autoDownloadDocumentsOnWifi,
    'autoDownloadDocumentsOnMobile': autoDownloadDocumentsOnMobile,
  };

  factory AutoDownloadSettings.fromJson(
    Map<String, dynamic> json,
  ) => AutoDownloadSettings(
    autoDownloadImagesOnWifi: json['autoDownloadImagesOnWifi'] as bool? ?? true,
    autoDownloadImagesOnMobile:
        json['autoDownloadImagesOnMobile'] as bool? ?? false,
    autoDownloadVideoOnWifi: json['autoDownloadVideoOnWifi'] as bool? ?? false,
    autoDownloadVideoOnMobile:
        json['autoDownloadVideoOnMobile'] as bool? ?? false,
    autoDownloadDocumentsOnWifi:
        json['autoDownloadDocumentsOnWifi'] as bool? ?? false,
    autoDownloadDocumentsOnMobile:
        json['autoDownloadDocumentsOnMobile'] as bool? ?? false,
  );
}

/// Determines whether a media file should be auto-downloaded based on the
/// current connectivity and the user's settings.
///
/// Requirements: 6.7
class AutoDownloadPolicy {
  AutoDownloadPolicy({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _storageKey = 'auto_download_policy';

  final FlutterSecureStorage _storage;

  /// Returns `true` if [mediaType] should be auto-downloaded given the
  /// current [connectivity] and the stored settings.
  Future<bool> shouldAutoDownload(
    MediaType mediaType,
    ConnectivityResult connectivity,
  ) async {
    final settings = await getPolicy();
    final isWifi = connectivity == ConnectivityResult.wifi;

    return switch (mediaType) {
      MediaType.image =>
        isWifi
            ? settings.autoDownloadImagesOnWifi
            : settings.autoDownloadImagesOnMobile,
      MediaType.video =>
        isWifi
            ? settings.autoDownloadVideoOnWifi
            : settings.autoDownloadVideoOnMobile,
      MediaType.document =>
        isWifi
            ? settings.autoDownloadDocumentsOnWifi
            : settings.autoDownloadDocumentsOnMobile,
      MediaType.audio => isWifi, // audio always auto-downloads on Wi-Fi
    };
  }

  /// Persists [settings] to secure storage.
  Future<void> updatePolicy(AutoDownloadSettings settings) async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(settings.toJson()),
    );
  }

  /// Reads the stored settings, returning defaults if none are stored.
  Future<AutoDownloadSettings> getPolicy() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null) return const AutoDownloadSettings();
    try {
      return AutoDownloadSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const AutoDownloadSettings();
    }
  }
}
