import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../data/demo_images.dart';

/// The player on this phone. [WatchTogether] drives it to match the shared state.
abstract class LocalPlayer extends ChangeNotifier {
  /// Real YouTube on devices; a timer-driven stand-in under `flutter test`
  /// (web views can't run there).
  static LocalPlayer create(TickerProvider vsync) =>
      Platform.environment.containsKey('FLUTTER_TEST') ? TickerPlayer(vsync) : YoutubeLocalPlayer();

  String? get mediaId;
  bool get playing;
  Duration get duration;

  /// Updated every frame (ticker) or every ~250 ms (YouTube).
  ValueListenable<Duration> get position;

  /// Called when the current video finishes.
  VoidCallback? onEnded;

  Future<void> load(String mediaId, {required Duration start, required bool play, Duration? knownDuration});
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration to);

  /// The video surface. [cover] is shown before anything is loaded.
  Widget view({ImageProvider? cover});

  bool get supportsFullscreen => false;
  void toggleFullscreen() {}
}

/// Stand-in player: advances a clock and shows the cover image.
class TickerPlayer extends LocalPlayer {
  TickerPlayer(TickerProvider vsync) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  final _position = ValueNotifier(Duration.zero);
  Duration _anchor = Duration.zero;
  String? _mediaId;
  bool _playing = false;
  Duration _duration = const Duration(minutes: 5);

  @override
  String? get mediaId => _mediaId;

  @override
  bool get playing => _playing;

  @override
  Duration get duration => _duration;

  @override
  ValueListenable<Duration> get position => _position;

  void _tick(Duration elapsed) {
    final next = _anchor + elapsed;
    if (next >= _duration) {
      _position.value = _duration;
      pause();
      onEnded?.call();
      return;
    }
    _position.value = next;
  }

  void _restartClock() {
    _ticker.stop();
    _anchor = _position.value;
    if (_playing) _ticker.start();
  }

  @override
  Future<void> load(String mediaId, {required Duration start, required bool play, Duration? knownDuration}) async {
    _mediaId = mediaId;
    _duration = knownDuration != null && knownDuration > Duration.zero ? knownDuration : const Duration(minutes: 5);
    _position.value = start;
    _playing = play;
    _restartClock();
    notifyListeners();
  }

  @override
  Future<void> play() async {
    if (_playing) return;
    _playing = true;
    _restartClock();
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    if (!_playing) return;
    _playing = false;
    _restartClock();
    notifyListeners();
  }

  @override
  Future<void> seek(Duration to) async {
    _position.value = Duration(milliseconds: to.inMilliseconds.clamp(0, _duration.inMilliseconds));
    _restartClock();
  }

  @override
  Widget view({ImageProvider? cover}) => CoverImage(cover ?? DemoImages.neonStreet);

  @override
  void dispose() {
    _ticker.dispose();
    _position.dispose();
    super.dispose();
  }
}

/// The official YouTube IFrame player (keeps ads and branding, per YouTube's
/// terms). Its own controls are hidden; ours drive it so both phones stay in sync.
class YoutubeLocalPlayer extends LocalPlayer {
  YoutubeLocalPlayer() {
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(showControls: false, showFullscreenButton: false, strictRelatedVideos: true, playsInline: true),
    );
    _subs.add(_controller.stream.listen(_onValue));
    _subs.add(_controller.videoStateStream.listen((s) => _position.value = s.position));
  }

  late final YoutubePlayerController _controller;
  final _subs = <StreamSubscription<Object?>>[];
  final _position = ValueNotifier(Duration.zero);
  String? _mediaId;
  bool _playing = false;
  Duration _duration = Duration.zero;

  void _onValue(YoutubePlayerValue v) {
    final playing = v.playerState == PlayerState.playing || v.playerState == PlayerState.buffering;
    final metaDuration = v.metaData.duration;
    var changed = false;
    if (metaDuration > Duration.zero && metaDuration != _duration) {
      _duration = metaDuration;
      changed = true;
    }
    if (v.playerState == PlayerState.ended) {
      _playing = false;
      onEnded?.call();
      changed = true;
    } else if (playing != _playing && v.playerState != PlayerState.unknown) {
      _playing = playing;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  @override
  String? get mediaId => _mediaId;

  @override
  bool get playing => _playing;

  @override
  Duration get duration => _duration;

  @override
  ValueListenable<Duration> get position => _position;

  double _seconds(Duration d) => d.inMilliseconds / 1000;

  @override
  Future<void> load(String mediaId, {required Duration start, required bool play, Duration? knownDuration}) async {
    _mediaId = mediaId;
    if (knownDuration != null && knownDuration > Duration.zero) _duration = knownDuration;
    _position.value = start;
    if (play) {
      await _controller.loadVideoById(videoId: mediaId, startSeconds: _seconds(start));
    } else {
      await _controller.cueVideoById(videoId: mediaId, startSeconds: _seconds(start));
    }
    _playing = play;
    notifyListeners();
  }

  @override
  Future<void> play() async {
    _playing = true;
    notifyListeners();
    await _controller.playVideo();
  }

  @override
  Future<void> pause() async {
    _playing = false;
    notifyListeners();
    await _controller.pauseVideo();
  }

  @override
  Future<void> seek(Duration to) async {
    _position.value = to;
    await _controller.seekTo(seconds: _seconds(to), allowSeekAhead: true);
  }

  @override
  Widget view({ImageProvider? cover}) => YoutubePlayer(controller: _controller, aspectRatio: 16 / 9, enableFullScreenOnVerticalDrag: false, keepAlive: true);

  @override
  bool get supportsFullscreen => true;

  @override
  void toggleFullscreen() => _controller.toggleFullScreen();

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _controller.close();
    _position.dispose();
    super.dispose();
  }
}

String formatClock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}
