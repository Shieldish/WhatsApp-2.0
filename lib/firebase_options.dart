import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Reconfigure your Firebase project using the FlutterFire CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Android — values from google-services.json
  // ---------------------------------------------------------------------------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrqiDCqVsbv6OmWT43BqSiHR1LTkW72Bk',
    appId: '1:406238741974:android:87da17830b2ddd3cee5077',
    messagingSenderId: '406238741974',
    projectId: 'whatsapp2-0-c8826',
    storageBucket: 'whatsapp2-0-c8826.firebasestorage.app',
  );

  // ---------------------------------------------------------------------------
  // iOS — values from GoogleService-Info.plist
  // ---------------------------------------------------------------------------
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDvbKd8yS3DeruWzGw_t6LK4wIb7cGIg7Y',
    appId: '1:406238741974:ios:3feccb5cbb3f7102ee5077',
    messagingSenderId: '406238741974',
    projectId: 'whatsapp2-0-c8826',
    storageBucket: 'whatsapp2-0-c8826.firebasestorage.app',
    iosBundleId: 'com.example.whatsapp20',
  );
}
