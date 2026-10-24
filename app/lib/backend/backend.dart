import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/sync/playback_sync.dart';
import '../data/models.dart';

/// Everything the app needs from the server.
///
/// Two implementations:
/// * [DemoBackend] (`lib/backend/demo/`): in-memory, with a simulated partner.
///   Used when the app is built without Firebase settings, and in tests.
/// * [FirebaseBackend] (`lib/backend/firebase/`): Firebase Auth, Firestore,
///   Realtime Database, Storage, Functions and Messaging, plus LiveKit for
///   calls. Private content is end-to-end encrypted before it leaves the phone.
abstract class Backend {
  /// True for the in-memory demo.
  bool get isDemo;

  // ── Account ──────────────────────────────────────────────────────────────

  /// The signed-in account, or null when signed out.
  Stream<Account?> get account;

  Future<void> signInWithGoogle();
  Future<void> signInWithEmail({required String email, required String password, required bool create});
  Future<void> signOut();
  Future<void> updateName(String name);

  /// Deletes the account and everything stored for it (Play requirement).
  Future<void> deleteAccount();

  // ── Couple ───────────────────────────────────────────────────────────────

  /// The paired couple, or null before pairing / after unlinking.
  Stream<Couple?> get couple;

  Future<Invite> createInvite();

  /// Accepts a typed invite code or a scanned QR payload.
  Future<void> acceptInvite(String codeOrPayload);

  /// Unlinks the couple. Shared data is wiped after a 24 h undo window.
  Future<void> unlink();

  /// The partner's new key was checked in person.
  Future<void> confirmSafetyEmojis();

  // ── Chat ─────────────────────────────────────────────────────────────────

  Stream<List<ChatMessage>> get messages;
  Stream<Presence> get partnerPresence;

  Future<void> sendText(String text);
  Future<void> sendPhoto(String path);
  Future<void> sendVoice(String path, Duration length);
  Future<void> heartMessage(String id);
  Future<void> setTyping(bool typing);
  Future<void> markRead();

  /// A quick "thinking of you" nudge (push notification for the partner).
  Future<void> sendLove();

  // ── Together (watch / listen) ────────────────────────────────────────────

  Stream<List<QueueItem>> get queue;

  Future<void> addToQueue({required String title, required String mediaId, String subtitle = '', Duration duration = Duration.zero, MediaProvider provider = MediaProvider.youtube});
  Future<void> removeFromQueue(String id);
  Future<void> reorderQueue(List<String> orderedIds);

  /// Shared player state (see [PlaybackState]).
  Stream<PlaybackState?> get playback;

  /// Server clock used for playback positions.
  ServerClock get clock;

  /// Atomically updates the shared player state (highest `seq` wins).
  Future<void> updatePlayback(PlaybackState Function(PlaybackState? current) update);

  Stream<List<Playlist>> get playlists;
  Future<void> createPlaylist(String name);
  Future<void> addToPlaylist(String playlistId, {required String title, required String mediaId, String subtitle = ''});
  Future<void> removeFromPlaylist(String playlistId, String itemId);

  /// Movie Night 3-2-1 countdown shared by both phones.
  Stream<MovieCountdown?> get countdown;
  Future<void> startCountdown(String service);

  // ── Daily question ───────────────────────────────────────────────────────

  Stream<DailySpark?> get todaySpark;
  Future<void> answerSpark(String sparkId, String answer);
  Future<List<DailySpark>> pastSparks();

  /// Asks the server (Claude) for fresh daily questions on a theme
  /// (`fun`, `deep`, `future` or `memories`). They're used on the next days.
  Future<List<String>> generateQuestions(String theme);

  // ── Location ─────────────────────────────────────────────────────────────

  Stream<PartnerLocation?> get partnerLocation;
  Stream<LocationShare> get myLocationShare;

  /// Shares my live location for [duration] (null = until stopped).
  Future<void> startSharing({Duration? duration, bool approximate = false});
  Future<void> stopSharing();

  // ── Memories ─────────────────────────────────────────────────────────────

  Stream<List<Memory>> get memories;
  Future<void> addMemory({required String title, String note = '', String? photoPath, bool locked = false});

  // ── Calls ────────────────────────────────────────────────────────────────

  /// A call from the partner that is ringing now.
  Stream<CallInfo?> get incomingCall;

  Future<CallSession> startCall({required bool video});
  Future<CallSession> answerCall(CallInfo call);
  Future<void> declineCall(CallInfo call);

  Future<void> dispose();
}

/// A live call. Views are plain widgets so screens don't depend on the SDK.
abstract class CallSession {
  CallInfo get info;

  ValueListenable<CallState> get state;
  ValueListenable<bool> get micOn;
  ValueListenable<bool> get cameraOn;

  /// When the call connected (null while ringing).
  DateTime? get connectedAt;

  Widget remoteView();
  Widget localView();

  Future<void> setMic(bool on);
  Future<void> setCamera(bool on);
  Future<void> flipCamera();
  Future<void> hangUp();
}

/// User-facing error with a message that can be shown as-is.
class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}
