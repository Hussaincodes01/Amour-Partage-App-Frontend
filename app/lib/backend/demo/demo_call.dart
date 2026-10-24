import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../data/demo_images.dart';
import '../../data/models.dart';
import '../backend.dart';

/// Demo call: rings for two seconds, then "connects" with sample video.
class DemoCallSession implements CallSession {
  DemoCallSession(this.info, {bool connectNow = false}) : _camera = ValueNotifier(info.video) {
    if (connectNow) {
      _connect();
    } else {
      _ring = Timer(const Duration(seconds: 2), _connect);
    }
  }

  @override
  final CallInfo info;

  final _state = ValueNotifier(CallState.ringing);
  final _mic = ValueNotifier(true);
  final ValueNotifier<bool> _camera;
  Timer? _ring;
  DateTime? _connectedAt;

  void _connect() {
    _connectedAt = DateTime.now();
    _state.value = CallState.active;
  }

  @override
  ValueListenable<CallState> get state => _state;

  @override
  ValueListenable<bool> get micOn => _mic;

  @override
  ValueListenable<bool> get cameraOn => _camera;

  @override
  DateTime? get connectedAt => _connectedAt;

  @override
  Widget remoteView() => const Image(image: DemoImages.partnerVideo, fit: BoxFit.cover, gaplessPlayback: true);

  @override
  Widget localView() => const Image(image: DemoImages.selfVideo, fit: BoxFit.cover, gaplessPlayback: true);

  @override
  Future<void> setMic(bool on) async => _mic.value = on;

  @override
  Future<void> setCamera(bool on) async => _camera.value = on;

  @override
  Future<void> flipCamera() async {}

  @override
  Future<void> hangUp() async {
    _ring?.cancel();
    _state.value = CallState.ended;
  }
}
