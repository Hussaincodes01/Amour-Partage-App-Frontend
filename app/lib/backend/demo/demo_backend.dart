import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../core/sync/playback_sync.dart';
import '../../data/models.dart';
import '../backend.dart';
import '../live.dart';
import 'demo_call.dart';
import 'demo_data.dart';

/// In-memory backend with a simulated partner. Nothing leaves the phone.
class DemoBackend implements Backend {
  /// Starts signed out (the full welcome → pairing flow).
  DemoBackend() : this._(signedIn: false);

  /// Starts signed in and paired (used by tests and previews).
  DemoBackend.paired() : this._(signedIn: true);

  DemoBackend._({required bool signedIn}) {
    if (signedIn) {
      _account.value = _demoAccount;
      _couple.value = _demoCouple();
    }
    // Camille is typing when the chat first opens, then stops.
    _later(const Duration(seconds: 6), () => _presence.value = const Presence(online: true));
  }

  static const _demoAccount = Account(uid: 'demo-julian', name: 'Julian', email: 'julian@example.com', photo: null);

  final _rnd = math.Random();
  final _timers = <Timer>[];

  final _account = Live<Account?>(null);
  final _couple = Live<Couple?>(null);
  final _messages = Live<List<ChatMessage>>(DemoData.messages());
  final _presence = Live<Presence>(const Presence(online: true, typing: true));
  final _queue = Live<List<QueueItem>>(List.of(DemoData.queue));
  final _playback = Live<PlaybackState?>(null);
  final _playlists = Live<List<Playlist>>(DemoData.playlists);
  final _countdown = Live<MovieCountdown?>(null);
  final _spark = Live<DailySpark?>(DemoData.spark);
  final _partnerLocation = Live<PartnerLocation?>(null);
  final _myShare = Live<LocationShare>(LocationShare(active: true, until: DateTime.now().add(const Duration(minutes: 58)), myPoint: DemoData.myPoint));
  final _memories = Live<List<Memory>>(DemoData.memories());
  final _incoming = Live<CallInfo?>(null);

  @override
  final clock = ServerClock();

  @override
  bool get isDemo => true;

  Couple _demoCouple() => Couple(
        id: 'demo-couple',
        me: Person(id: DemoData.me.id, name: _account.value?.name ?? DemoData.me.name, photo: DemoData.me.photo),
        partner: DemoData.partner,
        since: DemoData.since,
        safetyEmojis: DemoData.safetyEmojis,
      );

  void _later(Duration d, void Function() f) => _timers.add(Timer(d, f));

  String _id() => 'local-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(1 << 20)}';

  // ── Account ──────────────────────────────────────────────────────────────

  @override
  Stream<Account?> get account => _account.stream;

  @override
  Future<void> signInWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _account.value = _demoAccount;
  }

  @override
  Future<void> signInWithEmail({required String email, required String password, required bool create}) async {
    if (!email.contains('@')) throw const BackendException('Enter a valid email address.');
    if (password.length < 8) throw const BackendException('Use at least 8 characters for the password.');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _account.value = Account(uid: _demoAccount.uid, name: _account.value?.name ?? 'Julian', email: email);
  }

  @override
  Future<void> signOut() async {
    _couple.value = null;
    _account.value = null;
  }

  @override
  Future<void> updateName(String name) async {
    final a = _account.value;
    if (a == null) return;
    _account.value = Account(uid: a.uid, name: name, email: a.email, photo: a.photo);
    if (_couple.value != null) _couple.value = _demoCouple();
  }

  @override
  Future<void> deleteAccount() => signOut();

  // ── Couple ───────────────────────────────────────────────────────────────

  @override
  Stream<Couple?> get couple => _couple.stream;

  @override
  Future<Invite> createInvite() async {
    final expires = DateTime.now().add(const Duration(minutes: 15));
    // Demo: the partner "scans" the invite after a few seconds.
    _later(const Duration(seconds: 6), () {
      if (_account.value != null && _couple.value == null) _couple.value = _demoCouple();
    });
    return Invite(code: 'CA11-0E7E', expiresAt: expires, qrPayload: 'amour://pair?c=CA110E7E');
  }

  @override
  Future<void> acceptInvite(String codeOrPayload) async {
    final code = codeOrPayload.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (code.length < 8) throw const BackendException('Invite codes have 8 letters and numbers.');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _couple.value = _demoCouple();
  }

  @override
  Future<void> unlink() async => _couple.value = null;

  @override
  Future<void> confirmSafetyEmojis() async {}

  // ── Chat ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> get messages => _messages.stream;

  @override
  Stream<Presence> get partnerPresence => _presence.stream;

  void _append(ChatMessage m) {
    _messages.value = [..._messages.value, m];
    _replySoon();
  }

  @override
  Future<void> sendText(String text) async =>
      _append(ChatMessage(id: _id(), mine: true, kind: MessageKind.text, sentAt: DateTime.now(), text: text));

  @override
  Future<void> sendPhoto(String path) async =>
      _append(ChatMessage(id: _id(), mine: true, kind: MessageKind.photo, sentAt: DateTime.now(), image: FileImage(File(path))));

  @override
  Future<void> sendVoice(String path, Duration length) async =>
      _append(ChatMessage(id: _id(), mine: true, kind: MessageKind.voice, sentAt: DateTime.now(), duration: length));

  @override
  Future<void> heartMessage(String id) async {
    _messages.value = [for (final m in _messages.value) m.id == id ? m.copyWith(hearts: m.hearts > 0 ? 0 : 1) : m];
  }

  @override
  Future<void> setTyping(bool typing) async {}

  @override
  Future<void> markRead() async {}

  @override
  Future<void> sendLove() async {}

  /// Camille reads, types, then answers.
  void _replySoon() {
    _later(const Duration(milliseconds: 900), () {
      _messages.value = [for (final m in _messages.value) m.mine ? m.copyWith(status: MessageStatus.read) : m];
      _presence.value = const Presence(online: true, typing: true);
      _later(const Duration(milliseconds: 1800), () {
        _presence.value = const Presence(online: true);
        _messages.value = [
          ..._messages.value,
          ChatMessage(id: _id(), mine: false, kind: MessageKind.text, sentAt: DateTime.now(), text: DemoData.replies[_rnd.nextInt(DemoData.replies.length)]),
        ];
      });
    });
  }

  // ── Together ─────────────────────────────────────────────────────────────

  @override
  Stream<List<QueueItem>> get queue => _queue.stream;

  @override
  Future<void> addToQueue({required String title, required String mediaId, String subtitle = '', Duration duration = Duration.zero, MediaProvider provider = MediaProvider.youtube}) async {
    _queue.value = [
      ..._queue.value,
      QueueItem(
        id: _id(),
        title: title,
        subtitle: subtitle,
        duration: duration,
        addedBy: _account.value?.name ?? 'Julian',
        mediaId: mediaId,
        provider: provider,
        thumbnail: provider == MediaProvider.youtube ? NetworkImage('https://i.ytimg.com/vi/$mediaId/hqdefault.jpg') : null,
      ),
    ];
  }

  @override
  Future<void> removeFromQueue(String id) async => _queue.value = _queue.value.where((q) => q.id != id).toList();

  @override
  Future<void> reorderQueue(List<String> orderedIds) async {
    final byId = {for (final q in _queue.value) q.id: q};
    _queue.value = [for (final id in orderedIds) ?byId[id]];
  }

  @override
  Stream<PlaybackState?> get playback => _playback.stream;

  @override
  Future<void> updatePlayback(PlaybackState Function(PlaybackState? current) update) async {
    final next = update(_playback.value);
    if (PlaybackSync.isNewer(next, _playback.value)) _playback.value = next;
  }

  @override
  Stream<List<Playlist>> get playlists => _playlists.stream;

  @override
  Future<void> createPlaylist(String name) async => _playlists.value = [..._playlists.value, Playlist(id: _id(), name: name)];

  @override
  Future<void> addToPlaylist(String playlistId, {required String title, required String mediaId, String subtitle = ''}) async {
    final item = QueueItem(
      id: _id(),
      title: title,
      subtitle: subtitle,
      duration: Duration.zero,
      addedBy: _account.value?.name ?? 'Julian',
      mediaId: mediaId,
      thumbnail: NetworkImage('https://i.ytimg.com/vi/$mediaId/hqdefault.jpg'),
    );
    _playlists.value = [for (final p in _playlists.value) p.id == playlistId ? Playlist(id: p.id, name: p.name, items: [...p.items, item]) : p];
  }

  @override
  Future<void> removeFromPlaylist(String playlistId, String itemId) async {
    _playlists.value = [
      for (final p in _playlists.value) p.id == playlistId ? Playlist(id: p.id, name: p.name, items: p.items.where((i) => i.id != itemId).toList()) : p,
    ];
  }

  @override
  Stream<MovieCountdown?> get countdown => _countdown.stream;

  @override
  Future<void> startCountdown(String service) async {
    _countdown.value = MovieCountdown(service: service, startAt: DateTime.now().add(const Duration(seconds: 4)), by: _account.value?.uid ?? '');
  }

  // ── Daily question ───────────────────────────────────────────────────────

  @override
  Stream<DailySpark?> get todaySpark => _spark.stream;

  @override
  Future<void> answerSpark(String sparkId, String answer) async {
    final s = _spark.value;
    if (s == null || s.id != sparkId) return;
    _spark.value = DailySpark(id: s.id, prompt: s.prompt, myAnswer: answer, partnerAnswered: true, partnerAnswer: DemoData.sparkPartnerAnswer);
  }

  @override
  Future<List<DailySpark>> pastSparks() async => DemoData.pastSparks;

  @override
  Future<List<String>> generateQuestions(String theme) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return DemoData.aiQuestions[theme] ?? DemoData.aiQuestions['fun']!;
  }

  // ── Location ─────────────────────────────────────────────────────────────

  @override
  Stream<PartnerLocation?> get partnerLocation {
    _partnerLocation.value ??= PartnerLocation(
      point: DemoData.partnerPoint,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 1)),
      distanceKm: 3.86,
    );
    return _partnerLocation.stream;
  }

  @override
  Stream<LocationShare> get myLocationShare => _myShare.stream;

  @override
  Future<void> startSharing({Duration? duration, bool approximate = false}) async {
    _myShare.value = LocationShare(active: true, until: duration == null ? null : DateTime.now().add(duration), approximate: approximate, myPoint: DemoData.myPoint);
  }

  @override
  Future<void> stopSharing() async => _myShare.value = const LocationShare();

  // ── Memories ─────────────────────────────────────────────────────────────

  @override
  Stream<List<Memory>> get memories => _memories.stream;

  @override
  Future<void> addMemory({required String title, String note = '', String? photoPath, bool locked = false}) async {
    _memories.value = [
      Memory(id: _id(), title: title, note: note, date: DateTime.now(), image: photoPath != null ? FileImage(File(photoPath)) : null, locked: locked),
      ..._memories.value,
    ];
  }

  // ── Calls ────────────────────────────────────────────────────────────────

  @override
  Stream<CallInfo?> get incomingCall => _incoming.stream;

  @override
  Future<CallSession> startCall({required bool video}) async => DemoCallSession(CallInfo(id: _id(), video: video, incoming: false));

  @override
  Future<CallSession> answerCall(CallInfo call) async {
    _incoming.value = null;
    return DemoCallSession(CallInfo(id: call.id, video: call.video, incoming: true), connectNow: true);
  }

  @override
  Future<void> declineCall(CallInfo call) async => _incoming.value = null;

  /// Demo helper: makes the partner call you.
  void simulateIncomingCall({bool video = true}) => _incoming.value = CallInfo(id: _id(), video: video, incoming: true);

  @override
  Future<void> dispose() async {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
