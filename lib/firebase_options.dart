import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtbAOMGDksptqkGrUshnVhfIlMxEwDIZg',
    appId: '1:385999084012:android:69af175842668c8cfe88c9',
    messagingSenderId: '385999084012',
    projectId: 'khat-d3d55',
    storageBucket: 'khat-d3d55.appspot.com',
  );
}
