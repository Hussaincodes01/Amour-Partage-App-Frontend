import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend.dart';
import '../core/security/privacy_channel.dart';
import '../core/sync/playback_sync.dart';
import 'models.dart';

enum SessionPhase { loading, signedOut, unpaired, paired }

/// Privacy switches kept on the device.
enum Guard { appLock, screenshots, links, mediaBlur, discreet }

/// App state for the UI. Mirrors the [Backend] streams and keeps local
/// settings (tab, privacy switches). Screens read it through [AppScope].
class CoupleState extends ChangeNotifier {
  CoupleState(this.backend) {
    _listen(backend.account, (Account? a) {
      account = a;
      _accountKnown = true;
    });
    _listen(backend.couple, (Couple? c) {
      couple = c;
      _coupleKnown = true;
    });
    _listen(backend.messages, (List<ChatMessage> m) {
      final hadNew = m.length > messages.length && m.isNotEmpty && !m.last.mine && messages.isNotEmpty;
      messages = m;
      if (hadNew) tab == 2 ? backend.markRead() : chatUnread = true;
    });
    _listen(backend.partnerPresence, (Presence p) => presence = p);
    _listen(backend.queue, (List<QueueItem> q) => queue = q);
    _listen(backend.playback, (PlaybackState? p) => playback = p);
    _listen(backend.todaySpark, (DailySpark? s) => spark = s);
    _listen(backend.partnerLocation, (PartnerLocation? l) => partnerLocation = l);
    _listen(backend.myLocationShare, (LocationShare s) => myShare = s);
    _listen(backend.memories, (List<Memory> m) => memories = m);
    _listen(backend.incomingCall, (CallInfo? c) => incomingCall = c);
    _loadGuards();
  }

  final Backend backend;
  final _subs = <StreamSubscription<Object?>>[];
  bool _disposed = false;

  void _listen<T>(Stream<T> stream, void Function(T) apply) {
    _subs.add(stream.listen((v) {
      apply(v);
      if (!_disposed) notifyListeners();
    }));
  }

  // ── Session ──────────────────────────────────────────────────────────────

  Account? account;
  Couple? couple;
  bool _accountKnown = false;
  bool _coupleKnown = false;

  SessionPhase get phase {
    if (!_accountKnown) return SessionPhase.loading;
    if (account == null) return SessionPhase.signedOut;
    if (couple != null) return SessionPhase.paired;
    return _coupleKnown ? SessionPhase.unpaired : SessionPhase.loading;
  }

  String get myName => couple?.me.name ?? account?.name ?? 'You';
  String get partnerName => couple?.partner.name ?? 'your partner';

  // ── Navigation ───────────────────────────────────────────────────────────

  int tab = 0;
  bool chatUnread = false;

  void selectTab(int index) {
    if (index == tab) return;
    tab = index;
    if (index == 2) {
      chatUnread = false;
      backend.markRead();
    }
    notifyListeners();
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  List<ChatMessage> messages = const [];
  Presence presence = const Presence();
  final Set<String> unlockedMoments = {};

  void unlockMoment(String id) {
    unlockedMoments.add(id);
    notifyListeners();
  }

  // ── Together ─────────────────────────────────────────────────────────────

  List<QueueItem> queue = const [];
  PlaybackState? playback;

  /// The queue item playing now (or the first one).
  QueueItem? get nowPlaying {
    if (queue.isEmpty) return null;
    final id = playback?.mediaId;
    return queue.firstWhere((q) => q.mediaId == id, orElse: () => queue.first);
  }

  List<QueueItem> get upNext {
    final now = nowPlaying;
    return [for (final q in queue) if (q.id != now?.id) q];
  }

  // ── Daily question ───────────────────────────────────────────────────────

  DailySpark? spark;

  // ── Location ─────────────────────────────────────────────────────────────

  PartnerLocation? partnerLocation;
  LocationShare myShare = const LocationShare();

  // ── Memories ─────────────────────────────────────────────────────────────

  List<Memory> memories = const [];
  bool vaultUnlocked = false;

  void setVaultUnlocked(bool value) {
    vaultUnlocked = value;
    notifyListeners();
  }

  // ── Calls ────────────────────────────────────────────────────────────────

  CallInfo? incomingCall;

  // ── Privacy switches ─────────────────────────────────────────────────────

  final Map<Guard, bool> guards = {for (final g in Guard.values) g: true};

  bool guard(Guard g) => guards[g] ?? true;

  int get activeGuards => guards.values.where((on) => on).length;

  Future<void> setGuard(Guard g, bool on) async {
    guards[g] = on;
    if (g == Guard.screenshots) PrivacyChannel.setScreenshotShield(on);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guard_${g.name}', on);
    } on Exception {
      // Applies for this session only.
    }
  }

  Future<void> _loadGuards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final g in Guard.values) {
        final saved = prefs.getBool('guard_${g.name}');
        if (saved != null) guards[g] = saved;
      }
      PrivacyChannel.setScreenshotShield(guard(Guard.screenshots));
      if (!_disposed) notifyListeners();
    } on Exception {
      // Defaults stay on.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}

/// Exposes [CoupleState] to the widget tree.
class AppScope extends InheritedNotifier<CoupleState> {
  const AppScope({super.key, required CoupleState state, required super.child}) : super(notifier: state);

  /// Subscribes the caller to changes.
  static CoupleState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads without subscribing (for callbacks).
  static CoupleState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
