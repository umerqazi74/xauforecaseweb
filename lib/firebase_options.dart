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
    apiKey: 'AIzaSyCVJ1shDGdcAXjnX6Yf9roV6GaONBxyvCY',
    appId: '1:903200174736:web:bfc8220bff0b4c761cde15',
    messagingSenderId: '903200174736',
    projectId: 'xauforecasting',
    authDomain: 'xauforecasting.firebaseapp.com',
    databaseURL: 'https://xauforecasting-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'xauforecasting.firebasestorage.app',
    measurementId: 'G-97ZFJZ18SQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCr7uWXZhNNo3VlyP2BNJjBZNf_YvYRK1o',
    appId: '1:903200174736:android:786cfe2280175a7a1cde15',
    messagingSenderId: '903200174736',
    projectId: 'xauforecasting',
    databaseURL: 'https://xauforecasting-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'xauforecasting.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAM9YrORmI3M1SnanbD88_aKMQfeaXO8eA',
    appId: '1:903200174736:ios:89302e14aabb8ea31cde15',
    messagingSenderId: '903200174736',
    projectId: 'xauforecasting',
    databaseURL: 'https://xauforecasting-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'xauforecasting.firebasestorage.app',
    iosBundleId: 'com.example.xauForecaste',
  );
}