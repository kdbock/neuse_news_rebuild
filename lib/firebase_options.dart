import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // Web options
      return const FirebaseOptions(
        apiKey: 'AIzaSyCYHkIGUB7Et0OoTgChoORHdjz01QYGM5k',
        appId: '1:236600949564:web:1290ec24f72f09c482fc39',
        messagingSenderId: '236600949564',
        projectId: 'neuse-news-df5fd',
        storageBucket: 'neuse-news-df5fd.firebasestorage.app',
      );
    }

    // Platform-specific options
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCYHkIGUB7Et0OoTgChoORHdjz01QYGM5k',
          appId: '1:236600949564:android:1290ec24f72f09c482fc39',
          messagingSenderId: '236600949564',
          projectId: 'neuse-news-df5fd',
          storageBucket: 'neuse-news-df5fd.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBLGdDTvwCFYmMF486cEGfiRgDqLZyP62Y',
          appId: '1:236600949564:ios:8bc6bc5c6066c0da82fc39',
          messagingSenderId: '236600949564',
          projectId: 'neuse-news-df5fd',
          storageBucket: 'neuse-news-df5fd.firebasestorage.app',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not available for this platform.',
        );
    }
  }
}
