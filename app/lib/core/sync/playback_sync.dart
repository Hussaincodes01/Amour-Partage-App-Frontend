import 'dart:math' as math;

/// Shared Watch/Listen Together state, stored at `rtdb:/sessions/{coupleId}`.
///
/// [positionMs] is where playback was at server time [atMs]. While playing,
/// the expected position at any later moment is `positionMs + (now − atMs)`,
/// so clients only write on play / pause / seek / skip, never every second.
class PlaybackState {
  const PlaybackState({
    required this.mediaId,
    required this.playing,
    required this.positionMs,
    required this.atMs,
    required this.by,
    required this.seq,
    this.buffering = false,
  });

  final String mediaId;
  final bool playing;
  final int positionMs;
  final int atMs;
  final String by;

  /// Increases by one on every write; the highest wins (last writer wins).
  final int seq;

  /// One player is buffering: both wait, then resume together.
  final bool buffering;

  /// Expected playback position at server time [serverNowMs].
  int positionAt(int serverNowMs) => playing && !buffering ? positionMs + math.max(0, serverNowMs - atMs) : positionMs;

  Map<String, Object?> toJson() => {
        'mediaId': mediaId,
        'playing': playing,
        'positionMs': positionMs,
        'at': atMs,
        'by': by,
        'seq': seq,
        'buffering': buffering,
      };

  static PlaybackState? fromJson(Object? json) {
    if (json is! Map) return null;
    final mediaId = json['mediaId'];
    if (mediaId is! String) return null;
    int n(Object? v) => v is num ? v.toInt() : 0;
    return PlaybackState(
      mediaId: mediaId,
      playing: json['playing'] == true,
      positionMs: n(json['positionMs']),
      atMs: n(json['at']),
      by: json['by'] is String ? json['by'] as String : '',
      seq: n(json['seq']),
      buffering: json['buffering'] == true,
    );
  }
}

enum SyncActionKind { load, seek, play, pause }

class SyncAction {
  const SyncAction(this.kind, {this.positionMs, this.mediaId});

  final SyncActionKind kind;
  final int? positionMs;
  final String? mediaId;

  @override
  String toString() => 'SyncAction(${kind.name}${positionMs != null ? ' @$positionMs' : ''}${mediaId != null ? ' $mediaId' : ''})';
}

abstract final class PlaybackSync {
  /// Drift under this is left alone, so small jitter never causes a seek.
  static const driftToleranceMs = 800;

  /// What the local player must do to match [remote].
  static List<SyncAction> reconcile({
    required PlaybackState remote,
    required String? localMediaId,
    required int localPositionMs,
    required bool localPlaying,
    required int serverNowMs,
  }) {
    final target = remote.positionAt(serverNowMs);
    final shouldPlay = remote.playing && !remote.buffering;
    if (localMediaId != remote.mediaId) {
      return [
        SyncAction(SyncActionKind.load, mediaId: remote.mediaId, positionMs: target),
        SyncAction(shouldPlay ? SyncActionKind.play : SyncActionKind.pause),
      ];
    }
    final actions = <SyncAction>[];
    if ((localPositionMs - target).abs() > driftToleranceMs) {
      actions.add(SyncAction(SyncActionKind.seek, positionMs: target));
    }
    if (shouldPlay != localPlaying) {
      actions.add(SyncAction(shouldPlay ? SyncActionKind.play : SyncActionKind.pause));
    }
    return actions;
  }

  /// The state to write when this user acts on [current].
  static PlaybackState next(
    PlaybackState? current, {
    required String by,
    required int serverNowMs,
    String? mediaId,
    bool? playing,
    int? positionMs,
    bool? buffering,
  }) {
    final switching = mediaId != null && mediaId != current?.mediaId;
    final position = positionMs ?? (switching ? 0 : current?.positionAt(serverNowMs) ?? 0);
    return PlaybackState(
      mediaId: mediaId ?? current?.mediaId ?? '',
      playing: playing ?? current?.playing ?? false,
      positionMs: math.max(0, position),
      atMs: serverNowMs,
      by: by,
      seq: (current?.seq ?? 0) + 1,
      buffering: buffering ?? (switching ? false : current?.buffering ?? false),
    );
  }

  /// Last writer wins: accept [incoming] only if it is newer than [current].
  static bool isNewer(PlaybackState incoming, PlaybackState? current) =>
      current == null || incoming.seq > current.seq || (incoming.seq == current.seq && incoming.atMs > current.atMs);
}

/// Converts local time to the backend's clock (`.info/serverTimeOffset`).
class ServerClock {
  ServerClock([this.offsetMs = 0]);

  int offsetMs;

  int nowMs([DateTime? local]) => (local ?? DateTime.now()).millisecondsSinceEpoch + offsetMs;
}
