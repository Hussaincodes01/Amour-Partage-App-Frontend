import 'package:flutter/widgets.dart';

import '../core/security/privacy_channel.dart';
import 'mock.dart';
import 'models.dart';

enum LocationShare { off, oneHour, eightHours, untilStopped }

/// App-wide state for the couple's shared space (local-only for the beta UI).
class CoupleState extends ChangeNotifier {
  // Navigation
  int tab = 0;
  bool chatUnread = true;

  void selectTab(int index) {
    if (index == tab) return;
    tab = index;
    if (index == 2) chatUnread = false;
    notifyListeners();
  }

  // Chat
  final List<ChatMessage> messages = List.of(Mock.messages);
  final Set<String> unlockedMoments = {};

  bool partnerTyping = true;

  static String _now() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return '$h:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
  }

  String _id() => 'local-${DateTime.now().microsecondsSinceEpoch}';

  void sendMessage(String text) {
    messages.add(ChatMessage(id: _id(), sender: Sender.me, kind: MessageKind.text, time: _now(), text: text, seen: false));
    notifyListeners();
  }

  void sendPhoto(String path) {
    messages.add(ChatMessage(id: _id(), sender: Sender.me, kind: MessageKind.photo, time: _now(), photoPath: path, seen: false));
    notifyListeners();
  }

  void sendVoiceNote(Duration length) {
    messages.add(ChatMessage(id: _id(), sender: Sender.me, kind: MessageKind.voiceNote, time: _now(), duration: length, seen: false));
    notifyListeners();
  }

  void setPartnerTyping(bool value) {
    if (partnerTyping == value) return;
    partnerTyping = value;
    notifyListeners();
  }

  /// Demo stand-in for the partner's live replies until sync is wired up.
  void receivePartnerMessage(String text) {
    partnerTyping = false;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      if (m.sender == Sender.me && !m.seen) {
        messages[i] = ChatMessage(id: m.id, sender: m.sender, kind: m.kind, time: m.time, text: m.text, duration: m.duration, photoPath: m.photoPath, transcript: m.transcript);
      }
    }
    messages.add(ChatMessage(id: _id(), sender: Sender.partner, kind: MessageKind.text, time: _now(), text: text));
    notifyListeners();
  }

  void unlockMoment(String id) {
    unlockedMoments.add(id);
    notifyListeners();
  }

  // Lounge
  MediaSource source = MediaSource.youtube;
  final List<QueueItem> queue = List.of(Mock.queue);

  void reorderQueue(int oldIndex, int newIndex) {
    queue.insert(newIndex, queue.removeAt(oldIndex));
    notifyListeners();
  }

  void addToQueue(QueueItem item) {
    queue.add(item);
    notifyListeners();
  }

  void removeFromQueue(String id) {
    queue.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  // Daily question
  SoulSpark spark = Mock.spark;

  void answerSpark(String answer) {
    spark = spark.withMyAnswer(answer);
    notifyListeners();
  }

  // Privacy guards
  bool biometricLock = true;
  bool screenshotShield = true;
  bool linkGuard = true;
  bool mediaBlur = true;
  bool discreetNotifications = true;
  bool ghostMode = false;

  void toggle(String key) {
    switch (key) {
      case 'biometric':
        biometricLock = !biometricLock;
      case 'screenshot':
        screenshotShield = !screenshotShield;
        PrivacyChannel.setScreenshotShield(screenshotShield);
      case 'link':
        linkGuard = !linkGuard;
      case 'media':
        mediaBlur = !mediaBlur;
      case 'discreet':
        discreetNotifications = !discreetNotifications;
      case 'ghost':
        ghostMode = !ghostMode;
    }
    notifyListeners();
  }

  int get activeGuards => [biometricLock, screenshotShield, linkGuard, mediaBlur, discreetNotifications].where((g) => g).length;

  // Memory vault
  final List<Memory> vault = List.of(Mock.vault);
  bool vaultUnlocked = false;

  void addMemory(Memory memory) {
    vault.insert(0, memory);
    notifyListeners();
  }

  void setVaultUnlocked(bool value) {
    vaultUnlocked = value;
    notifyListeners();
  }

  // Location
  LocationShare locationShare = LocationShare.oneHour;

  void setLocationShare(LocationShare value) {
    locationShare = value;
    notifyListeners();
  }

  // Sparks counter (call screen)
  int sparks = 142;

  void addSpark() {
    sparks++;
    notifyListeners();
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
