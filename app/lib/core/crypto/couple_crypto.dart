import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// End-to-end encryption for one couple.
///
/// * Each phone has an X25519 identity key. Only the public half leaves the
///   phone (stored on the couple document at pairing).
/// * Both phones derive the same 32-byte couple key:
///   `HKDF-SHA256(X25519(mine, theirs), salt: coupleId, info: "amour/couple-key/v1")`.
/// * Every private field (messages, answers, locations, memories, queue
///   titles) is sealed with XChaCha20-Poly1305 and a random 24-byte nonce.
///   The associated data binds a ciphertext to where it is stored, so it
///   cannot be moved to another document.
/// * Photos and voice notes get their own random key; that key travels
///   inside the sealed message.
///
/// Beta limitation (see PLAN.md §6): a static couple key, so no forward
/// secrecy. A ratcheting protocol replaces this after the beta.
abstract final class E2ee {
  static final _x25519 = X25519();
  static final _aead = Xchacha20.poly1305Aead();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  static const nonceLength = 24;
  static const macLength = 16;
}

/// This phone's X25519 identity key pair.
class IdentityKeys {
  IdentityKeys._(this._pair, this.publicKey);

  final SimpleKeyPair _pair;
  final Uint8List publicKey;

  String get publicKeyBase64 => base64Encode(publicKey);

  static Future<IdentityKeys> generate() async => _from(await E2ee._x25519.newKeyPair());

  /// Restores a key pair from the 32 private bytes kept in secure storage.
  static Future<IdentityKeys> fromPrivateBytes(List<int> bytes) async => _from(await E2ee._x25519.newKeyPairFromSeed(bytes));

  static Future<IdentityKeys> _from(SimpleKeyPair pair) async {
    final pub = await pair.extractPublicKey();
    return IdentityKeys._(pair, Uint8List.fromList(pub.bytes));
  }

  Future<List<int>> privateBytes() => _pair.extractPrivateKeyBytes();
}

/// A sealed value as stored in the database: base64 ciphertext+MAC and nonce.
class Sealed {
  const Sealed(this.ciphertext, this.nonce);

  final String ciphertext;
  final String nonce;

  Map<String, String> toJson() => {'ct': ciphertext, 'n': nonce};

  static Sealed? fromJson(Map<String, Object?> json) {
    final ct = json['ct'], n = json['n'];
    return ct is String && n is String ? Sealed(ct, n) : null;
  }
}

class DecryptionFailed implements Exception {
  const DecryptionFailed(this.reason);

  final String reason;

  @override
  String toString() => 'DecryptionFailed: $reason';
}

/// Seals and opens data with the couple key.
class CoupleCipher {
  CoupleCipher._(this._key, this.coupleId);

  final SecretKey _key;
  final String coupleId;

  static Future<CoupleCipher> derive({required IdentityKeys mine, required List<int> partnerPublicKey, required String coupleId}) async {
    if (partnerPublicKey.length != 32) throw ArgumentError('X25519 public keys are 32 bytes');
    final shared = await E2ee._x25519.sharedSecretKey(
      keyPair: mine._pair,
      remotePublicKey: SimplePublicKey(partnerPublicKey, type: KeyPairType.x25519),
    );
    final key = await E2ee._hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('amour-couple:$coupleId'),
      info: utf8.encode('amour/couple-key/v1'),
    );
    return CoupleCipher._(key, coupleId);
  }

  /// Raw key bytes for sub-keys (e.g. the call media key).
  Future<Uint8List> deriveSubKey(String purpose) async {
    final sub = await E2ee._hkdf.deriveKey(secretKey: _key, info: utf8.encode('amour/$purpose/v1'));
    return Uint8List.fromList(await sub.extractBytes());
  }

  List<int> _aad(String context) => utf8.encode('$coupleId|$context');

  Future<Sealed> seal(List<int> plain, {required String context}) async {
    final box = await E2ee._aead.encrypt(plain, secretKey: _key, aad: _aad(context));
    return Sealed(base64Encode(box.concatenation(nonce: false)), base64Encode(box.nonce));
  }

  Future<Uint8List> open(Sealed sealed, {required String context}) async {
    try {
      final data = base64Decode(sealed.ciphertext);
      if (data.length < E2ee.macLength) throw const DecryptionFailed('too short');
      final box = SecretBox(
        data.sublist(0, data.length - E2ee.macLength),
        nonce: base64Decode(sealed.nonce),
        mac: Mac(data.sublist(data.length - E2ee.macLength)),
      );
      return Uint8List.fromList(await E2ee._aead.decrypt(box, secretKey: _key, aad: _aad(context)));
    } on SecretBoxAuthenticationError {
      throw const DecryptionFailed('authentication failed');
    } on FormatException {
      throw const DecryptionFailed('bad encoding');
    } on ArgumentError {
      throw const DecryptionFailed('bad nonce');
    }
  }

  Future<Sealed> sealJson(Map<String, Object?> value, {required String context}) => seal(utf8.encode(jsonEncode(value)), context: context);

  Future<Map<String, Object?>> openJson(Sealed sealed, {required String context}) async {
    final decoded = jsonDecode(utf8.decode(await open(sealed, context: context)));
    if (decoded is! Map<String, Object?>) throw const DecryptionFailed('not an object');
    return decoded;
  }
}

/// One-off key for a photo or voice note.
class MediaKey {
  const MediaKey(this.key, this.nonce);

  final String key;
  final String nonce;

  Map<String, String> toJson() => {'k': key, 'n': nonce};

  static MediaKey? fromJson(Object? json) =>
      json is Map && json['k'] is String && json['n'] is String ? MediaKey(json['k'] as String, json['n'] as String) : null;
}

abstract final class MediaCipher {
  /// Encrypts [bytes] with a fresh key. Upload the result; send the key sealed.
  static Future<(Uint8List, MediaKey)> encrypt(List<int> bytes) async {
    final key = await E2ee._aead.newSecretKey();
    final box = await E2ee._aead.encrypt(bytes, secretKey: key);
    return (
      Uint8List.fromList(box.concatenation(nonce: false)),
      MediaKey(base64Encode(await key.extractBytes()), base64Encode(box.nonce)),
    );
  }

  static Future<Uint8List> decrypt(List<int> data, MediaKey key) async {
    try {
      final box = SecretBox(
        data.sublist(0, data.length - E2ee.macLength),
        nonce: base64Decode(key.nonce),
        mac: Mac(data.sublist(data.length - E2ee.macLength)),
      );
      return Uint8List.fromList(await E2ee._aead.decrypt(box, secretKey: SecretKey(base64Decode(key.key))));
    } on SecretBoxAuthenticationError {
      throw const DecryptionFailed('media authentication failed');
    }
  }
}

/// Four emojis both partners compare in person. They are derived from both
/// public keys, so a swapped key (interception) shows different emojis.
abstract final class SafetyEmojis {
  static const table = [
    '🐶', '🐱', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔', '🐧', '🐦', '🦉',
    '🦄', '🐝', '🦋', '🐢', '🐙', '🦀', '🐬', '🐳', '🌵', '🌲', '🌻', '🌹', '🍄', '🌙', '⭐', '🔥',
    '🌈', '❄️', '🍎', '🍋', '🍉', '🍇', '🍓', '🍒', '🥑', '🥐', '🍕', '🍩', '🍪', '🎂', '☕', '🍿',
    '⚽', '🎸', '🎧', '🎨', '🚲', '🚀', '⛵', '🏝️', '🎈', '🎁', '💎', '🔑', '📷', '💌', '🧸', '🪐',
  ];

  static Future<List<String>> derive(List<int> keyA, List<int> keyB) async {
    final ordered = _compare(keyA, keyB) <= 0 ? [keyA, keyB] : [keyB, keyA];
    final digest = await Sha256().hash([...utf8.encode('amour/safety/v1'), ...ordered[0], ...ordered[1]]);
    return [for (var i = 0; i < 4; i++) table[digest.bytes[i] % table.length]];
  }

  static int _compare(List<int> a, List<int> b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i] - b[i];
    }
    return a.length - b.length;
  }
}
