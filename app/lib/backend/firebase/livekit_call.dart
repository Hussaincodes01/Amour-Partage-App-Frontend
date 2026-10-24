import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/models.dart';
import '../backend.dart';

/// A call over LiveKit (WebRTC SFU). Audio and video are end-to-end
/// encrypted with a key derived from the couple key, so the server only
/// relays ciphertext.
class LiveKitCallSession implements CallSession {
  LiveKitCallSession._(this.info, this._room, this._onHangUp) : _camera = ValueNotifier(info.video);

  static Future<LiveKitCallSession> connect({
    required CallInfo info,
    required String url,
    required String token,
    required Uint8List mediaKey,
    required Future<void> Function() onHangUp,
  }) async {
    final keyProvider = await BaseKeyProvider.create();
    await keyProvider.setSharedKey(base64Encode(mediaKey));
    final room = Room(
      roomOptions: RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        e2eeOptions: E2EEOptions(keyProvider: keyProvider),
        defaultCameraCaptureOptions: const CameraCaptureOptions(params: VideoParametersPresets.h720_169),
      ),
    );
    final session = LiveKitCallSession._(info, room, onHangUp);
    session._listen();
    await room.connect(url, token);
    await room.localParticipant?.setMicrophoneEnabled(true);
    if (info.video) await room.localParticipant?.setCameraEnabled(true);
    session._refresh();
    return session;
  }

  @override
  final CallInfo info;

  final Room _room;
  final Future<void> Function() _onHangUp;
  late final EventsListener<RoomEvent> _events = _room.createListener();
  final _state = ValueNotifier(CallState.connecting);
  final _mic = ValueNotifier(true);
  final ValueNotifier<bool> _camera;
  final _tracks = ValueNotifier(0);
  DateTime? _connectedAt;
  bool _front = true;
  bool _ended = false;

  void _listen() {
    _events
      ..on<ParticipantConnectedEvent>((_) => _refresh())
      ..on<TrackSubscribedEvent>((_) => _refresh())
      ..on<TrackUnsubscribedEvent>((_) => _refresh())
      ..on<LocalTrackPublishedEvent>((_) => _refresh())
      ..on<ParticipantDisconnectedEvent>((_) => hangUp())
      ..on<RoomDisconnectedEvent>((_) => _end());
  }

  void _refresh() {
    if (_room.remoteParticipants.isNotEmpty && _state.value != CallState.active) {
      _connectedAt = DateTime.now();
      _state.value = CallState.active;
    }
    _tracks.value++;
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _state.value = CallState.ended;
  }

  @override
  ValueListenable<CallState> get state => _state;

  @override
  ValueListenable<bool> get micOn => _mic;

  @override
  ValueListenable<bool> get cameraOn => _camera;

  @override
  DateTime? get connectedAt => _connectedAt;

  VideoTrack? get _remoteVideo {
    for (final p in _room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        final track = pub.track;
        if (track != null && !pub.muted) return track;
      }
    }
    return null;
  }

  VideoTrack? get _localVideo => _room.localParticipant?.videoTrackPublications.firstOrNull?.track;

  @override
  Widget remoteView() => ValueListenableBuilder<int>(
        valueListenable: _tracks,
        builder: (context, _, _) {
          final track = _remoteVideo;
          return track == null ? const SizedBox.shrink() : VideoTrackRenderer(track, fit: VideoViewFit.cover);
        },
      );

  @override
  Widget localView() => ValueListenableBuilder<int>(
        valueListenable: _tracks,
        builder: (context, _, _) {
          final track = _localVideo;
          return track == null ? const SizedBox.shrink() : VideoTrackRenderer(track, fit: VideoViewFit.cover, mirrorMode: _front ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off);
        },
      );

  @override
  Future<void> setMic(bool on) async {
    _mic.value = on;
    await _room.localParticipant?.setMicrophoneEnabled(on);
  }

  @override
  Future<void> setCamera(bool on) async {
    _camera.value = on;
    await _room.localParticipant?.setCameraEnabled(on);
    _tracks.value++;
  }

  @override
  Future<void> flipCamera() async {
    final track = _localVideo;
    if (track is! LocalVideoTrack) return;
    _front = !_front;
    await track.setCameraPosition(_front ? CameraPosition.front : CameraPosition.back);
    _tracks.value++;
  }

  @override
  Future<void> hangUp() async {
    if (_ended) return;
    _end();
    unawaited(_onHangUp().catchError((Object _) {}));
    await _events.dispose();
    await _room.disconnect();
    await _room.dispose();
  }
}
