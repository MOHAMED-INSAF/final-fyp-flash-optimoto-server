import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBkQm5jY8pB-7XP3z9K4L2N1M8o7V6u5T4',
    appId: '1:123456789012:web:abcdef1234567890123456',
    messagingSenderId: '123456789012',
    projectId: 'optimoto-firebase-app',
    authDomain: 'optimoto-firebase-app.firebaseapp.com',
    storageBucket: 'optimoto-firebase-app.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkQm5jY8pB-7XP3z9K4L2N1M8o7V6u5T4',
    appId: '1:123456789012:android:abcdef1234567890123456',
    messagingSenderId: '123456789012',
    projectId: 'optimoto-firebase-app',
    storageBucket: 'optimoto-firebase-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBkQm5jY8pB-7XP3z9K4L2N1M8o7V6u5T4',
    appId: '1:123456789012:ios:abcdef1234567890123456',
    messagingSenderId: '123456789012',
    projectId: 'optimoto-firebase-app',
    storageBucket: 'optimoto-firebase-app.appspot.com',
    iosBundleId: 'com.example.optimoto',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBkQm5jY8pB-7XP3z9K4L2N1M8o7V6u5T4',
    appId: '1:123456789012:macos:abcdef1234567890123456',
    messagingSenderId: '123456789012',
    projectId: 'optimoto-firebase-app',
    storageBucket: 'optimoto-firebase-app.appspot.com',
    iosBundleId: 'com.example.optimoto',
  );
}
