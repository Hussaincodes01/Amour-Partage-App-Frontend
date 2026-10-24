import 'dart:convert';

import 'package:amour_partage/core/crypto/couple_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> hex(String s) => [for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];

void main() {
  // RFC 7748 §6.1 test vectors.
  const alicePrivate = '77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a';
  const alicePublic = '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';
  const bobPrivate = '5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb';
  const bobPublic = 'de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f';

  late IdentityKeys alice;
  late IdentityKeys bob;
  late CoupleCipher aliceCipher;
  late CoupleCipher bobCipher;

  setUpAll(() async {
    alice = await IdentityKeys.fromPrivateBytes(hex(alicePrivate));
    bob = await IdentityKeys.fromPrivateBytes(hex(bobPrivate));
    aliceCipher = await CoupleCipher.derive(mine: alice, partnerPublicKey: bob.publicKey, coupleId: 'c1');
    bobCipher = await CoupleCipher.derive(mine: bob, partnerPublicKey: alice.publicKey, coupleId: 'c1');
  });

  test('X25519 public keys match RFC 7748', () {
    expect(alice.publicKey, hex(alicePublic));
    expect(bob.publicKey, hex(bobPublic));
  });

  test('both partners derive the same couple key', () async {
    final sealed = await aliceCipher.sealJson({'text': 'Je t’aime'}, context: 'msg:1:alice');
    expect(await bobCipher.openJson(sealed, context: 'msg:1:alice'), {'text': 'Je t’aime'});
    expect(await aliceCipher.deriveSubKey('call-media'), await bobCipher.deriveSubKey('call-media'));
  });

  test('every seal uses a fresh nonce', () async {
    final a = await aliceCipher.seal(utf8.encode('same'), context: 'x');
    final b = await aliceCipher.seal(utf8.encode('same'), context: 'x');
    expect(a.nonce, isNot(b.nonce));
    expect(a.ciphertext, isNot(b.ciphertext));
    expect(base64Decode(a.nonce), hasLength(24));
  });

  test('tampered ciphertext is rejected', () async {
    final sealed = await aliceCipher.seal(utf8.encode('hello'), context: 'msg:2:alice');
    final bytes = base64Decode(sealed.ciphertext);
    bytes[0] ^= 1;
    await expectLater(bobCipher.open(Sealed(base64Encode(bytes), sealed.nonce), context: 'msg:2:alice'), throwsA(isA<DecryptionFailed>()));
  });

  test('a ciphertext cannot be moved to another document or sender', () async {
    final sealed = await aliceCipher.seal(utf8.encode('hello'), context: 'msg:3:alice');
    await expectLater(bobCipher.open(sealed, context: 'msg:4:alice'), throwsA(isA<DecryptionFailed>()));
    await expectLater(bobCipher.open(sealed, context: 'msg:3:bob'), throwsA(isA<DecryptionFailed>()));
  });

  test('another couple cannot open it', () async {
    final eve = await IdentityKeys.generate();
    final eveCipher = await CoupleCipher.derive(mine: eve, partnerPublicKey: alice.publicKey, coupleId: 'c1');
    final otherCouple = await CoupleCipher.derive(mine: bob, partnerPublicKey: alice.publicKey, coupleId: 'c2');
    final sealed = await aliceCipher.seal(utf8.encode('secret'), context: 'msg:5:alice');
    await expectLater(eveCipher.open(sealed, context: 'msg:5:alice'), throwsA(isA<DecryptionFailed>()));
    await expectLater(otherCouple.open(sealed, context: 'msg:5:alice'), throwsA(isA<DecryptionFailed>()));
  });

  test('media round-trips and detects tampering', () async {
    final photo = List<int>.generate(50000, (i) => i % 251);
    final (data, key) = await MediaCipher.encrypt(photo);
    expect(await MediaCipher.decrypt(data, key), photo);
    data[100] ^= 0xff;
    await expectLater(MediaCipher.decrypt(data, key), throwsA(isA<DecryptionFailed>()));
  });

  test('identity keys survive a save and restore', () async {
    final keys = await IdentityKeys.generate();
    final restored = await IdentityKeys.fromPrivateBytes(await keys.privateBytes());
    expect(restored.publicKey, keys.publicKey);
  });

  test('safety emojis are the same on both phones and change with the key', () async {
    final a = await SafetyEmojis.derive(alice.publicKey, bob.publicKey);
    final b = await SafetyEmojis.derive(bob.publicKey, alice.publicKey);
    expect(a, hasLength(4));
    expect(a, b);
    final eve = await IdentityKeys.generate();
    expect(await SafetyEmojis.derive(alice.publicKey, eve.publicKey), isNot(a));
  });
}
