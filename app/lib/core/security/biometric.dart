import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { success, failed, unavailable }

/// Thin wrapper over the system biometric prompt (fingerprint / face).
abstract final class Biometric {
  static final _auth = LocalAuthentication();

  static Future<BiometricResult> unlock(String reason) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return BiometricResult.unavailable;
      final ok = await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
      return ok ? BiometricResult.success : BiometricResult.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noBiometricHardware || LocalAuthExceptionCode.noBiometricsEnrolled || LocalAuthExceptionCode.noCredentialsSet => BiometricResult.unavailable,
        _ => BiometricResult.failed,
      };
    } on PlatformException {
      return BiometricResult.unavailable;
    } on MissingPluginException {
      // Tests / unsupported platforms.
      return BiometricResult.unavailable;
    }
  }
}
