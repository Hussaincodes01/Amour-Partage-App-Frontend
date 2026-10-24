import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Local playback clock for the synced player UI. Position updates go through
/// a [ValueNotifier] so only the scrubber and timecodes rebuild each frame.
class PlayerController extends ChangeNotifier {
  PlayerController({required TickerProvider vsync, this.total = const Duration(minutes: 6, seconds: 18), Duration start = const Duration(minutes: 3, seconds: 24)})
      : position = ValueNotifier(start) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  final ValueNotifier<Duration> position;
  Duration total;
  Duration _anchorPosition = Duration.zero;
  Duration _anchorElapsed = Duration.zero;
  bool playing = false;
  bool muted = false;
  String title = 'Lo-Fi Beats & Chill Synthwave';

  double get progress => position.value.inMilliseconds / total.inMilliseconds;

  void _onTick(Duration elapsed) {
    final next = _anchorPosition + (elapsed - _anchorElapsed);
    if (next >= total) {
      position.value = total;
      pause();
      return;
    }
    position.value = next;
  }

  void play() {
    if (playing) return;
    playing = true;
    _anchorPosition = position.value;
    _anchorElapsed = Duration.zero;
    _ticker.start();
    notifyListeners();
  }

  void pause() {
    if (!playing) return;
    playing = false;
    _ticker.stop();
    notifyListeners();
  }

  void toggle() => playing ? pause() : play();

  void seek(Duration to) {
    final clamped = Duration(milliseconds: to.inMilliseconds.clamp(0, total.inMilliseconds));
    position.value = clamped;
    if (playing) {
      _ticker.stop();
      _anchorPosition = clamped;
      _anchorElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void seekFraction(double f) => seek(total * f.clamp(0.0, 1.0));

  void skip(int seconds) => seek(position.value + Duration(seconds: seconds));

  void load(String newTitle, Duration length) {
    title = newTitle;
    total = length;
    seek(Duration.zero);
    notifyListeners();
  }

  void toggleMute() {
    muted = !muted;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    position.dispose();
    super.dispose();
  }
}

String formatClock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

Duration parseClock(String clock) {
  final parts = clock.split(':').map(int.parse).toList();
  return parts.length == 2 ? Duration(minutes: parts[0], seconds: parts[1]) : Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
}
