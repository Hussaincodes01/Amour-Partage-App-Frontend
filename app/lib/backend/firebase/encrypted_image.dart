import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/crypto/couple_crypto.dart';

/// Downloads an encrypted photo from Cloud Storage and decrypts it on the
/// phone. Decoded images are cached by Flutter's image cache like any other.
class EncryptedImage extends ImageProvider<EncryptedImage> {
  const EncryptedImage({required this.path, required this.key, required this.download});

  /// Storage path; also the cache identity.
  final String path;
  final MediaKey key;
  final Future<Uint8List?> Function(String path) download;

  @override
  Future<EncryptedImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(EncryptedImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1, debugLabel: 'EncryptedImage($path)');
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final data = await download(path);
    if (data == null) throw StateError('Photo not found: $path');
    final bytes = await MediaCipher.decrypt(data, key);
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) => other is EncryptedImage && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
