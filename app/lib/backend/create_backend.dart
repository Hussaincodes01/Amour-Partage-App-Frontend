import 'package:flutter/foundation.dart';

import '../app/config.dart';
import 'backend.dart';
import 'demo/demo_backend.dart';
import 'firebase/firebase_backend.dart';

/// Firebase when the build has Firebase settings, otherwise the demo.
Future<Backend> createBackend() async {
  if (!AppConfig.firebaseEnabled) return DemoBackend();
  try {
    return await FirebaseBackend.start();
  } on Object catch (e, s) {
    debugPrint('Firebase failed to start, using the demo backend: $e\n$s');
    return DemoBackend();
  }
}
