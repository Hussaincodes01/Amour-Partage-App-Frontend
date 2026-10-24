import 'package:flutter/services.dart';

/// Native privacy switches implemented in MainActivity.kt.
abstract final class PrivacyChannel {
  static const _channel = MethodChannel('amour/privacy');

  /// Blocks screenshots, screen recording and the recent-apps preview
  /// (Android FLAG_SECURE).
  static Future<void> setScreenshotShield(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setScreenshotShield', {'enabled': enabled});
    } on MissingPluginException {
      // Not on Android (tests, previews).
    } on PlatformException {
      // Ignore: the shield stays in its previous state.
    }
  }
}
