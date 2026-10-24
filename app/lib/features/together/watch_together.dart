import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../backend/backend.dart';
import '../../core/sync/playback_sync.dart';
import '../../data/models.dart';
import 'local_player.dart';

/// Keeps this phone's player in step with the shared playback state.
///
/// Every control (play, pause, seek, skip) writes a new [PlaybackState]; both
/// phones then reconcile their player against it, seeking only when they are
/// more than [PlaybackSync.driftToleranceMs] apart.
class WatchTogether extends ChangeNotifier {
  WatchTogether({required this.backend, required this.player, required this.myId, required this.queue}) {
    _sub = backend.playback.listen(_onShared);
    player.addListener(notifyListeners);
    player.onEnded = _onEnded;
    // Players drift a little over time; re-check now and then while playing.
    _driftCheck = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_shared?.playing ?? false) _reconcile();
    });
  }

  final Backend backend;
  final LocalPlayer player;
  final String myId;

  /// The current queue (kept fresh by the screen).
  List<QueueItem> queue;

  late final StreamSubscription<PlaybackState?> _sub;
  late final Timer _driftCheck;
  PlaybackState? _shared;
  bool _disposed = false;

  PlaybackState? get shared => _shared;

  bool _visible = true;

  /// YouTube may only play while its player is on screen, so a hidden player
  /// pauses locally (without pausing your partner) and catches up when shown.
  set visible(bool value) {
    if (value == _visible) return;
    _visible = value;
    value ? _reconcile() : player.pause();
  }

  QueueItem? get current {
    if (queue.isEmpty) return null;
    final id = _shared?.mediaId ?? player.mediaId;
    return queue.firstWhere((q) => q.mediaId == id, orElse: () => queue.first);
  }

  bool get playing => _shared?.playing ?? player.playing;

  /// True when the other phone made the last change.
  bool get lastChangeByPartner => _shared != null && _shared!.by != myId;

  void _onShared(PlaybackState? state) {
    if (state == null) return;
    _shared = state;
    _reconcile();
    if (!_disposed) notifyListeners();
  }

  Future<void> _reconcile() async {
    final state = _shared;
    if (!_visible || state == null || state.mediaId.isEmpty) return;
    final actions = PlaybackSync.reconcile(
      remote: state,
      localMediaId: player.mediaId,
      localPositionMs: player.position.value.inMilliseconds,
      localPlaying: player.playing,
      serverNowMs: backend.clock.nowMs(),
    );
    for (final a in actions) {
      switch (a.kind) {
        case SyncActionKind.load:
          final item = queue.where((q) => q.mediaId == a.mediaId).firstOrNull;
          await player.load(a.mediaId!, start: Duration(milliseconds: a.positionMs ?? 0), play: state.playing, knownDuration: item?.duration);
        case SyncActionKind.seek:
          await player.seek(Duration(milliseconds: a.positionMs!));
        case SyncActionKind.play:
          await player.play();
        case SyncActionKind.pause:
          await player.pause();
      }
    }
  }

  Future<void> _write({String? mediaId, bool? playing, Duration? position}) => backend.updatePlayback(
        (current) => PlaybackSync.next(
          current,
          by: myId,
          serverNowMs: backend.clock.nowMs(),
          mediaId: mediaId,
          playing: playing,
          positionMs: position?.inMilliseconds,
        ),
      );

  /// Starts [item] from the beginning on both phones.
  Future<void> playItem(QueueItem item) async {
    await player.load(item.mediaId, start: Duration.zero, play: true, knownDuration: item.duration);
    await _write(mediaId: item.mediaId, playing: true, position: Duration.zero);
  }

  Future<void> togglePlay() async {
    final item = current;
    if (item == null) return;
    if (player.mediaId != item.mediaId || _shared == null) return playItem(item);
    final next = !playing;
    next ? await player.play() : await player.pause();
    await _write(playing: next, position: player.position.value);
  }

  Future<void> seek(Duration to) async {
    if (current == null) return;
    await player.seek(to);
    await _write(position: to);
  }

  Future<void> skip(int seconds) {
    final to = player.position.value + Duration(seconds: seconds);
    return seek(to < Duration.zero ? Duration.zero : to);
  }

  Future<void> next() async {
    final item = current;
    if (item == null || queue.length < 2) return;
    final i = queue.indexWhere((q) => q.id == item.id);
    await playItem(queue[(i + 1) % queue.length]);
  }

  void _onEnded() {
    // Both phones finish at about the same time and pick the same next item.
    if (queue.length > 1) next();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    _driftCheck.cancel();
    player.removeListener(notifyListeners);
    player.onEnded = null;
    super.dispose();
  }
}
