import 'package:amour_partage/core/sync/playback_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const playing = PlaybackState(mediaId: 'abc', playing: true, positionMs: 10000, atMs: 1000000, by: 'a', seq: 3);

  test('expected position advances only while playing', () {
    expect(playing.positionAt(1005000), 15000);
    expect(playing.positionAt(990000), 10000, reason: 'clock skew never rewinds');
    const paused = PlaybackState(mediaId: 'abc', playing: false, positionMs: 10000, atMs: 1000000, by: 'a', seq: 3);
    expect(paused.positionAt(1005000), 10000);
    const buffering = PlaybackState(mediaId: 'abc', playing: true, positionMs: 10000, atMs: 1000000, by: 'a', seq: 3, buffering: true);
    expect(buffering.positionAt(1005000), 10000);
  });

  test('small drift is left alone', () {
    final actions = PlaybackSync.reconcile(remote: playing, localMediaId: 'abc', localPositionMs: 15500, localPlaying: true, serverNowMs: 1005000);
    expect(actions, isEmpty);
  });

  test('large drift seeks to the shared position', () {
    final actions = PlaybackSync.reconcile(remote: playing, localMediaId: 'abc', localPositionMs: 12000, localPlaying: true, serverNowMs: 1005000);
    expect(actions.single.kind, SyncActionKind.seek);
    expect(actions.single.positionMs, 15000);
  });

  test('a paused partner pauses this phone', () {
    const paused = PlaybackState(mediaId: 'abc', playing: false, positionMs: 15000, atMs: 1005000, by: 'b', seq: 4);
    final actions = PlaybackSync.reconcile(remote: paused, localMediaId: 'abc', localPositionMs: 15100, localPlaying: true, serverNowMs: 1005100);
    expect(actions.map((a) => a.kind), [SyncActionKind.pause]);
  });

  test('a new video loads at the right position and plays', () {
    final actions = PlaybackSync.reconcile(remote: playing, localMediaId: 'other', localPositionMs: 0, localPlaying: false, serverNowMs: 1002000);
    expect(actions.map((a) => a.kind), [SyncActionKind.load, SyncActionKind.play]);
    expect(actions.first.mediaId, 'abc');
    expect(actions.first.positionMs, 12000);
  });

  test('next() bumps seq and keeps the projected position', () {
    final next = PlaybackSync.next(playing, by: 'b', serverNowMs: 1004000, playing: false);
    expect(next.seq, 4);
    expect(next.playing, isFalse);
    expect(next.positionMs, 14000);
    expect(next.by, 'b');
    expect(next.atMs, 1004000);
  });

  test('switching video starts from zero unless a position is given', () {
    expect(PlaybackSync.next(playing, by: 'a', serverNowMs: 1004000, mediaId: 'xyz').positionMs, 0);
    expect(PlaybackSync.next(null, by: 'a', serverNowMs: 1, mediaId: 'xyz', playing: true).seq, 1);
  });

  test('last writer wins by seq', () {
    final newer = PlaybackSync.next(playing, by: 'b', serverNowMs: 1004000);
    expect(PlaybackSync.isNewer(newer, playing), isTrue);
    expect(PlaybackSync.isNewer(playing, newer), isFalse);
    expect(PlaybackSync.isNewer(playing, null), isTrue);
  });

  test('state survives a JSON round trip', () {
    expect(PlaybackState.fromJson(playing.toJson())!.toJson(), playing.toJson());
    expect(PlaybackState.fromJson(null), isNull);
    expect(PlaybackState.fromJson({'playing': true}), isNull);
  });
}
