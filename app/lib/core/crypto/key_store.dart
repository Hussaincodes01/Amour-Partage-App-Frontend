import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'couple_crypto.dart';

/// Keeps this phone's identity key in Android Keystore-backed storage.
class KeyStore {
  KeyStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  String _slot(String uid) => 'identity_x25519_$uid';

  /// Loads the key for [uid], creating it on first use.
  Future<IdentityKeys> identity(String uid) async {
    final saved = await _storage.read(key: _slot(uid));
    if (saved != null) {
      try {
        return await IdentityKeys.fromPrivateBytes(base64Decode(saved));
      } on FormatException {
        // Corrupt slot: fall through and create a new key.
      }
    }
    final keys = await IdentityKeys.generate();
    await _storage.write(key: _slot(uid), value: base64Encode(await keys.privateBytes()));
    return keys;
  }

  /// Destroys the key (unlink / account deletion).
  Future<void> forget(String uid) => _storage.delete(key: _slot(uid));
}
