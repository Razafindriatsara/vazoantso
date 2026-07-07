import 'package:firebase_core/firebase_core.dart';

/// Configuration Firebase du projet VazoAntso.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBdItowq0W7zmhS_-FF-1E1RTmqAgWw7I0',
    appId: '1:289967245826:web:7ce0619679efdc688ab51b',
    messagingSenderId: '289967245826',
    projectId: 'vazoants0',
    authDomain: 'vazoants0.firebaseapp.com',
    storageBucket: 'vazoants0.firebasestorage.app',
  );
}
