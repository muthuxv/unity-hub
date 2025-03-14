// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCKtf1l-cLLse1CYWbZQXheHANldD8mzN8',
    appId: '1:244178234425:web:905a016fb6509e593531e8',
    messagingSenderId: '244178234425',
    projectId: 'unity-hub-446a0',
    authDomain: 'unity-hub-446a0.firebaseapp.com',
    storageBucket: 'unity-hub-446a0.appspot.com',
    measurementId: 'G-PC2QPG35N4',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAMAMbUbGQbiJTjDI8hoyuO951_zHh9bdc',
    appId: '1:244178234425:android:c2ee190b0efa44063531e8',
    messagingSenderId: '244178234425',
    projectId: 'unity-hub-446a0',
    storageBucket: 'unity-hub-446a0.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCwga_Wu4m9rFlt_nGOExXuKDr4zBFpBAI',
    appId: '1:244178234425:ios:e2fd62752dbff2b13531e8',
    messagingSenderId: '244178234425',
    projectId: 'unity-hub-446a0',
    storageBucket: 'unity-hub-446a0.appspot.com',
    androidClientId: '244178234425-a83cqg6ghn0vgmetuqhtcm8to7tf5mm1.apps.googleusercontent.com',
    iosClientId: '244178234425-86cnhu3j0iqae8ei9sa6477srrnkm95d.apps.googleusercontent.com',
    iosBundleId: 'com.example.testProject',
  );

}