import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint, Transaction;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config.dart';
import '../../core/crypto/couple_crypto.dart';
import '../../core/crypto/key_store.dart';
import '../../core/sync/playback_sync.dart';
import '../../data/models.dart';
import '../backend.dart';
import '../live.dart';
import 'encrypted_image.dart';
import 'livekit_call.dart';

/// Firebase + LiveKit backend. Data layout (see `backend/README.md`):
///
/// * Firestore `users/{uid}`, `couples/{cid}` and its sub-collections
///   (`messages`, `queue`, `playlists`, `sparks`, `locations`, `memories`,
///   `calls`). Private fields are sealed with the couple key (`ct` + `n`).
/// * Realtime Database `/couples/{cid}/{presence,typing,playback,countdown}`
///   for fast-changing state.
/// * Storage `couples/{cid}/media/*` holds encrypted photos and voice notes.
/// * Cloud Functions handle pairing, calls (LiveKit tokens), push
///   notifications, daily questions and account deletion.
class FirebaseBackend with WidgetsBindingObserver implements Backend {
  FirebaseBackend._();

  static Future<FirebaseBackend> start() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: AppConfig.firebaseApiKey,
        appId: AppConfig.firebaseAppId,
        messagingSenderId: AppConfig.firebaseSenderId,
        projectId: AppConfig.firebaseProjectId,
        databaseURL: AppConfig.firebaseDatabaseUrl,
        storageBucket: AppConfig.firebaseStorageBucket,
      ),
    );
    final backend = FirebaseBackend._();
    if (AppConfig.useEmulators) await backend._useEmulators(AppConfig.emulatorHost);
    backend._start();
    return backend;
  }

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _rtdb = FirebaseDatabase.instance;
  final _storage = FirebaseStorage.instance;
  late final _functions = FirebaseFunctions.instanceFor(region: AppConfig.functionsRegion);
  final _keys = KeyStore();

  final _account = Live<Account?>(null);
  final _couple = Live<Couple?>(null);
  final _messages = Live<List<ChatMessage>>(const []);
  final _presence = Live<Presence>(const Presence());
  final _queue = Live<List<QueueItem>>(const []);
  final _playback = Live<PlaybackState?>(null);
  final _playlists = Live<List<Playlist>>(const []);
  final _countdown = Live<MovieCountdown?>(null);
  final _spark = Live<DailySpark?>(null);
  final _partnerLocation = Live<PartnerLocation?>(null);
  final _myShare = Live<LocationShare>(const LocationShare());
  final _memories = Live<List<Memory>>(const []);
  final _incoming = Live<CallInfo?>(null);

  @override
  final clock = ServerClock();

  StreamSubscription<User?>? _authSub;
  final _userSubs = <StreamSubscription<Object?>>[];
  final _coupleSubs = <StreamSubscription<Object?>>[];

  User? _user;
  IdentityKeys? _identity;
  String? _coupleId;
  String? _partnerId;
  String? _partnerKey;
  CoupleCipher? _cipher;
  Map<String, Object?> _coupleData = const {};

  @override
  bool get isDemo => false;

  Future<void> _useEmulators(String host) async {
    await _auth.useAuthEmulator(host, 9099);
    _db.useFirestoreEmulator(host, 8080);
    _rtdb.useDatabaseEmulator(host, 9000);
    await _storage.useStorageEmulator(host, 9199);
    _functions.useFunctionsEmulator(host, 5001);
  }

  void _start() {
    WidgetsBinding.instance.addObserver(this);
    _authSub = _auth.authStateChanges().listen(_onUser);
    _rtdb.ref('.info/serverTimeOffset').onValue.listen((e) {
      final v = e.snapshot.value;
      if (v is num) clock.offsetMs = v.toInt();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Presence follows the app being open.
    if (state == AppLifecycleState.paused) _rtdb.goOffline();
    if (state == AppLifecycleState.resumed) _rtdb.goOnline();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String get _uid => _user?.uid ?? (throw const BackendException('Please sign in again.'));

  CoupleCipher get _key => _cipher ?? (throw const BackendException('Pair with your partner first.'));

  DocumentReference<Map<String, dynamic>> get _coupleRef {
    final id = _coupleId;
    if (id == null) throw const BackendException('Pair with your partner first.');
    return _db.collection('couples').doc(id);
  }

  DatabaseReference _live(String path) => _rtdb.ref('couples/$_coupleId/$path');

  Future<Map<String, Object?>> _call(String name, [Map<String, Object?> data = const {}]) async {
    try {
      final result = await _functions.httpsCallable(name).call<Object?>(data);
      final value = result.data;
      return value is Map ? Map<String, Object?>.from(value) : const {};
    } on FirebaseFunctionsException catch (e) {
      throw BackendException(e.message ?? 'Something went wrong. Please try again.');
    }
  }

  String _name(String? uid) {
    final names = _coupleData['names'];
    if (uid != null && names is Map && names[uid] is String) return names[uid] as String;
    return uid == _user?.uid ? 'You' : 'Partner';
  }

  static DateTime _time(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();

  Future<Uint8List?> _download(String path) => _storage.ref(path).getData(25 * 1024 * 1024);

  Future<String> _uploadEncrypted(List<int> bytes, String kind) async {
    final (data, key) = await MediaCipher.encrypt(bytes);
    final path = 'couples/$_coupleId/media/${_db.collection('_').doc().id}.$kind';
    await _storage.ref(path).putData(data, SettableMetadata(contentType: 'application/octet-stream'));
    _pendingKeys[path] = key;
    return path;
  }

  /// Media keys of uploads made in this session, so they can be sealed with the
  /// message that references them.
  final _pendingKeys = <String, MediaKey>{};

  // ── Account ──────────────────────────────────────────────────────────────

  @override
  Stream<Account?> get account => _account.stream;

  Future<void> _onUser(User? user) async {
    for (final s in _userSubs) {
      await s.cancel();
    }
    _userSubs.clear();
    _user = user;
    if (user == null) {
      _identity = null;
      await _onCoupleId(null);
      _account.value = null;
      return;
    }
    _identity = await _keys.identity(user.uid);
    final userRef = _db.collection('users').doc(user.uid);
    final existing = await userRef.get();
    await userRef.set({
      if (!existing.exists || existing.data()?['name'] == null) 'name': user.displayName ?? user.email?.split('@').first ?? 'Me',
      'email': user.email,
      'photoUrl': user.photoURL,
      'publicKey': _identity!.publicKeyBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _userSubs.add(userRef.snapshots().listen((snap) {
      final data = snap.data() ?? const {};
      _account.value = Account(
        uid: user.uid,
        name: (data['name'] as String?) ?? user.displayName ?? 'Me',
        email: user.email,
        photo: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
      );
      _onCoupleId(data['coupleId'] as String?);
    }));
    unawaited(_registerDevice(user.uid));
  }

  Future<void> _registerDevice(String uid) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final prefs = await SharedPreferences.getInstance();
      var deviceId = prefs.getString('device_id');
      if (deviceId == null) {
        deviceId = _db.collection('_').doc().id;
        await prefs.setString('device_id', deviceId);
      }
      Future<void> save(String? token) async {
        if (token == null) return;
        await _db.collection('users').doc(uid).collection('devices').doc(deviceId).set({
          'fcmToken': token,
          'platform': Platform.operatingSystem,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // The token arrives on onRegistered now and whenever it rotates.
      _userSubs.add(messaging.onRegistered.listen(save));
      await messaging.register();
    } on Exception catch (e) {
      debugPrint('Push notifications unavailable: $e');
    }
  }

  BackendException _authError(FirebaseAuthException e) => BackendException(switch (e.code) {
        'invalid-email' => 'That email address doesn’t look right.',
        'email-already-in-use' => 'There’s already an account with this email. Sign in instead.',
        'weak-password' => 'Use at least 8 characters for the password.',
        'wrong-password' || 'invalid-credential' || 'user-not-found' => 'Wrong email or password.',
        'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
        'network-request-failed' => 'No connection. Check your internet and try again.',
        _ => e.message ?? 'Couldn’t sign in. Please try again.',
      });

  @override
  Future<void> signInWithGoogle() async {
    try {
      final google = GoogleSignIn.instance;
      await google.initialize(serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId);
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const BackendException('Google didn’t return a sign-in token.');
      await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw BackendException(e.description ?? 'Google sign-in failed.');
    } on FirebaseAuthException catch (e) {
      throw _authError(e);
    }
  }

  @override
  Future<void> signInWithEmail({required String email, required String password, required bool create}) async {
    if (create && password.length < 8) throw const BackendException('Use at least 8 characters for the password.');
    try {
      if (create) {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      throw _authError(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _setOnline(false);
    await stopSharing();
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } on Exception {
      // Not signed in with Google.
    }
  }

  @override
  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _db.collection('users').doc(_uid).set({'name': trimmed}, SetOptions(merge: true));
    if (_coupleId != null) await _coupleRef.update({'names.$_uid': trimmed});
    await _user?.updateDisplayName(trimmed);
  }

  @override
  Future<void> deleteAccount() async {
    final uid = _uid;
    await stopSharing();
    await _call('deleteAccount');
    await _keys.forget(uid);
    await _auth.signOut();
  }

  // ── Couple ───────────────────────────────────────────────────────────────

  @override
  Stream<Couple?> get couple => _couple.stream;

  Future<void> _onCoupleId(String? id) async {
    if (id == _coupleId && (id == null || _coupleSubs.isNotEmpty)) return;
    for (final s in _coupleSubs) {
      await s.cancel();
    }
    _coupleSubs.clear();
    await _locationSub?.cancel();
    _locationSub = null;
    _coupleId = id;
    _partnerId = null;
    _partnerKey = null;
    _cipher = null;
    _coupleData = const {};
    _messageCache.clear();
    if (id == null) {
      _couple.value = null;
      _messages.value = const [];
      _queue.value = const [];
      _playlists.value = const [];
      _memories.value = const [];
      _spark.value = null;
      _partnerLocation.value = null;
      _myShare.value = const LocationShare();
      _playback.value = null;
      _incoming.value = null;
      return;
    }
    _coupleSubs.add(_db.collection('couples').doc(id).snapshots().listen(_onCoupleDoc, onError: _ignore));
  }

  void _ignore(Object e) => debugPrint('Listener stopped: $e');

  Future<void> _onCoupleDoc(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    final uid = _user?.uid;
    if (data == null || uid == null || data['status'] != 'active') {
      if (_couple.value != null) _couple.value = null;
      return;
    }
    _coupleData = data;
    final members = List<String>.from(data['members'] as List? ?? const []);
    final partnerId = members.firstWhere((m) => m != uid, orElse: () => '');
    if (partnerId.isEmpty) return;
    final keys = Map<String, Object?>.from(data['keys'] as Map? ?? const {});
    final partnerKey = keys[partnerId] as String?;
    final myKey = _identity!.publicKeyBase64;
    if (keys[uid] != myKey) {
      // New phone or reinstall: publish this phone's key. The partner sees a
      // "check your safety emojis" warning.
      await snap.reference.update({'keys.$uid': myKey});
    }
    if (partnerKey == null) return;
    final firstLoad = _partnerId == null;
    if (partnerKey != _partnerKey) {
      _partnerKey = partnerKey;
      _cipher = await CoupleCipher.derive(mine: _identity!, partnerPublicKey: _b64(partnerKey), coupleId: snap.id);
      _messageCache.clear();
    }
    _partnerId = partnerId;
    final photos = Map<String, Object?>.from(data['photos'] as Map? ?? const {});
    final verified = Map<String, Object?>.from(data['verifiedKeys'] as Map? ?? const {});
    ImageProvider? photo(String id) => photos[id] is String ? NetworkImage(photos[id] as String) : null;
    _couple.value = Couple(
      id: snap.id,
      me: Person(id: uid, name: _name(uid), photo: photo(uid)),
      partner: Person(id: partnerId, name: _name(partnerId), photo: photo(partnerId)),
      since: _time(data['since']),
      safetyEmojis: await SafetyEmojis.derive(_identity!.publicKey, _b64(partnerKey)),
      keyChanged: verified[uid] != null && verified[uid] != partnerKey,
    );
    if (firstLoad) {
      _subscribeCouple(snap.id, uid, partnerId);
    } else {
      _emitMessages();
    }
  }

  static Uint8List _b64(String s) => Uint8List.fromList(base64Decode(s));

  void _subscribeCouple(String cid, String uid, String partnerId) {
    final ref = _db.collection('couples').doc(cid);
    _coupleSubs
      ..add(ref.collection('messages').orderBy('createdAt').limitToLast(300).snapshots(includeMetadataChanges: true).listen(_onMessages, onError: _ignore))
      ..add(ref.collection('queue').orderBy('order').snapshots().listen(_onQueue, onError: _ignore))
      ..add(ref.collection('playlists').orderBy('createdAt').snapshots().listen(_onPlaylists, onError: _ignore))
      ..add(ref.collection('memories').orderBy('date', descending: true).limit(300).snapshots().listen(_onMemories, onError: _ignore))
      ..add(ref.collection('locations').doc(partnerId).snapshots().listen(_onPartnerLocation, onError: _ignore))
      ..add(ref.collection('calls').where('state', isEqualTo: 'ringing').snapshots().listen(_onCalls, onError: _ignore))
      ..add(_live('playback').onValue.listen((e) => _playback.value = PlaybackState.fromJson(e.snapshot.value), onError: _ignore))
      ..add(_live('countdown').onValue.listen(_onCountdown, onError: _ignore))
      ..add(_live('presence/$partnerId').onValue.listen((e) => _onPresence(e.snapshot.value, null), onError: _ignore))
      ..add(_live('typing/$partnerId').onValue.listen((e) => _onPresence(null, e.snapshot.value == true), onError: _ignore))
      ..add(_rtdb.ref('.info/connected').onValue.listen((e) {
        if (e.snapshot.value == true) _setOnline(true);
      }, onError: _ignore));
    unawaited(_loadSpark());
  }

  @override
  Future<Invite> createInvite() async {
    final result = await _call('createInvite', {'publicKey': _identity?.publicKeyBase64});
    final code = result['code'] as String;
    final expires = DateTime.fromMillisecondsSinceEpoch((result['expiresAt'] as num).toInt());
    // The QR also carries the inviter's key, so scanning in person checks it.
    return Invite(code: code, expiresAt: expires, qrPayload: 'amour://pair?c=${code.replaceAll('-', '')}&k=${Uri.encodeComponent(_identity!.publicKeyBase64)}');
  }

  @override
  Future<void> acceptInvite(String codeOrPayload) async {
    var code = codeOrPayload.trim();
    String? expectedKey;
    final uri = Uri.tryParse(code);
    if (uri != null && uri.scheme == 'amour') {
      code = uri.queryParameters['c'] ?? '';
      expectedKey = uri.queryParameters['k'];
    }
    code = code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    if (code.length != 8) throw const BackendException('Invite codes have 8 letters and numbers.');
    await _call('acceptInvite', {
      'code': code,
      'publicKey': _identity!.publicKeyBase64,
      'expectedInviterKey': ?expectedKey,
    });
  }

  @override
  Future<void> unlink() async {
    await stopSharing();
    await _call('unlinkCouple');
  }

  @override
  Future<void> confirmSafetyEmojis() async {
    if (_partnerKey == null) return;
    await _coupleRef.update({'verifiedKeys.$_uid': _partnerKey});
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> get messages => _messages.stream;

  @override
  Stream<Presence> get partnerPresence => _presence.stream;

  QuerySnapshot<Map<String, dynamic>>? _messageSnap;
  final _messageCache = <String, ChatMessage>{};

  Future<void> _onMessages(QuerySnapshot<Map<String, dynamic>> snap) async {
    _messageSnap = snap;
    await _emitMessages();
  }

  Future<void> _emitMessages() async {
    final snap = _messageSnap;
    final cipher = _cipher;
    final uid = _user?.uid;
    if (snap == null || cipher == null || uid == null) return;
    final lastRead = (_coupleData['lastRead'] as Map?)?[_partnerId];
    final partnerRead = lastRead is Timestamp ? lastRead.toDate() : null;
    final out = <ChatMessage>[];
    for (final doc in snap.docs) {
      final base = _messageCache[doc.id] ?? await _decodeMessage(doc, cipher, uid);
      _messageCache[doc.id] = base;
      final data = doc.data();
      final hearts = (data['hearts'] as Map?)?.length ?? 0;
      final status = !base.mine
          ? MessageStatus.read
          : doc.metadata.hasPendingWrites
              ? MessageStatus.sending
              : partnerRead != null && !base.sentAt.isAfter(partnerRead)
                  ? MessageStatus.read
                  : MessageStatus.sent;
      out.add(base.copyWith(status: status, hearts: hearts));
    }
    _messages.value = out;
  }

  Future<ChatMessage> _decodeMessage(QueryDocumentSnapshot<Map<String, dynamic>> doc, CoupleCipher cipher, String uid) async {
    final data = doc.data();
    final sender = data['sender'] as String? ?? '';
    final mine = sender == uid;
    final sentAt = data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
    final sealed = Sealed.fromJson(data);
    try {
      if (sealed == null) throw const DecryptionFailed('missing');
      final p = await cipher.openJson(sealed, context: 'msg:${doc.id}:$sender');
      final kind = MessageKind.values.firstWhere((k) => k.name == p['kind'], orElse: () => MessageKind.text);
      final media = p['media'] as Map?;
      final mediaKey = MediaKey.fromJson(media);
      final path = media?['path'] as String?;
      return ChatMessage(
        id: doc.id,
        mine: mine,
        kind: kind,
        sentAt: sentAt,
        text: p['text'] as String?,
        image: kind != MessageKind.voice && path != null && mediaKey != null ? EncryptedImage(path: path, key: mediaKey, download: _download) : null,
        duration: p['durationMs'] is num ? Duration(milliseconds: (p['durationMs'] as num).toInt()) : null,
        audio: kind == MessageKind.voice && path != null && mediaKey != null ? () => _voiceFile(path, mediaKey) : null,
        riddle: p['riddle'] as String?,
        answer: p['answer'] as String?,
      );
    } on DecryptionFailed {
      return ChatMessage(id: doc.id, mine: mine, kind: MessageKind.text, sentAt: sentAt, text: '🔒 This message was sealed with an older key and can’t be opened on this phone.');
    }
  }

  Future<String?> _voiceFile(String path, MediaKey key) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${path.hashCode}.m4a');
    if (await file.exists()) return file.path;
    final data = await _download(path);
    if (data == null) return null;
    await file.writeAsBytes(await MediaCipher.decrypt(data, key), flush: true);
    return file.path;
  }

  Future<void> _sendMessage(Map<String, Object?> payload) async {
    final ref = _coupleRef.collection('messages').doc();
    final sealed = await _key.sealJson(payload, context: 'msg:${ref.id}:$_uid');
    await ref.set({...sealed.toJson(), 'sender': _uid, 'kind': payload['kind'], 'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> sendText(String text) => _sendMessage({'kind': MessageKind.text.name, 'text': text});

  @override
  Future<void> sendPhoto(String path) async {
    final storagePath = await _uploadEncrypted(await File(path).readAsBytes(), 'img');
    final key = _pendingKeys.remove(storagePath)!;
    await _sendMessage({
      'kind': MessageKind.photo.name,
      'media': {'path': storagePath, ...key.toJson(), 'mime': 'image/jpeg'},
    });
  }

  @override
  Future<void> sendVoice(String path, Duration length) async {
    if (path.isEmpty) throw const BackendException('The recording didn’t save. Try again.');
    final file = File(path);
    final storagePath = await _uploadEncrypted(await file.readAsBytes(), 'aud');
    final key = _pendingKeys.remove(storagePath)!;
    await _sendMessage({
      'kind': MessageKind.voice.name,
      'durationMs': length.inMilliseconds,
      'media': {'path': storagePath, ...key.toJson(), 'mime': 'audio/mp4'},
    });
    unawaited(file.delete().then((_) {}, onError: (Object _) {}));
  }

  @override
  Future<void> heartMessage(String id) async {
    final ref = _coupleRef.collection('messages').doc(id);
    final hearts = (await ref.get()).data()?['hearts'] as Map?;
    await ref.update({'hearts.$_uid': hearts?[_uid] == true ? FieldValue.delete() : true});
  }

  @override
  Future<void> setTyping(bool typing) async {
    if (_coupleId == null) return;
    final ref = _live('typing/$_uid');
    if (typing) {
      await ref.onDisconnect().remove();
      await ref.set(true);
    } else {
      await ref.remove();
    }
  }

  DateTime? _lastMarkedRead;

  @override
  Future<void> markRead() async {
    if (_coupleId == null) return;
    final now = DateTime.now();
    if (_lastMarkedRead != null && now.difference(_lastMarkedRead!) < const Duration(seconds: 2)) return;
    _lastMarkedRead = now;
    await _coupleRef.update({'lastRead.$_uid': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> sendLove() async => _call('sendNudge', {'kind': 'love'});

  bool _partnerOnline = false;
  DateTime? _partnerSeen;
  bool _partnerTyping = false;

  void _onPresence(Object? presence, bool? typing) {
    if (presence is Map) {
      _partnerOnline = presence['online'] == true;
      final seen = presence['lastSeen'];
      if (seen is num) _partnerSeen = DateTime.fromMillisecondsSinceEpoch(seen.toInt());
    } else if (presence == null && typing == null) {
      _partnerOnline = false;
    }
    if (typing != null) _partnerTyping = typing;
    _presence.value = Presence(online: _partnerOnline, lastSeen: _partnerSeen, typing: _partnerTyping && _partnerOnline);
  }

  Future<void> _setOnline(bool online) async {
    if (_coupleId == null || _user == null) return;
    final ref = _live('presence/$_uid');
    try {
      if (online) {
        await ref.onDisconnect().set({'online': false, 'lastSeen': ServerValue.timestamp});
        await ref.set({'online': true, 'lastSeen': ServerValue.timestamp});
      } else {
        await ref.set({'online': false, 'lastSeen': ServerValue.timestamp});
      }
    } on Exception catch (e) {
      debugPrint('Presence not updated: $e');
    }
  }

  // ── Together ─────────────────────────────────────────────────────────────

  @override
  Stream<List<QueueItem>> get queue => _queue.stream;

  Future<QueueItem?> _decodeItem(String id, Map<String, dynamic> data, String context) async {
    final sealed = Sealed.fromJson(data);
    if (sealed == null || _cipher == null) return null;
    try {
      final p = await _cipher!.openJson(sealed, context: context);
      final mediaId = data['mediaId'] as String? ?? '';
      return QueueItem(
        id: id,
        title: p['title'] as String? ?? 'Video',
        subtitle: p['subtitle'] as String? ?? '',
        duration: Duration(milliseconds: (p['durationMs'] as num?)?.toInt() ?? 0),
        addedBy: _name(data['addedBy'] as String?),
        mediaId: mediaId,
        thumbnail: mediaId.isEmpty ? null : NetworkImage('https://i.ytimg.com/vi/$mediaId/hqdefault.jpg'),
      );
    } on DecryptionFailed {
      return null;
    }
  }

  Future<void> _onQueue(QuerySnapshot<Map<String, dynamic>> snap) async {
    final items = <QueueItem>[];
    for (final d in snap.docs) {
      final item = await _decodeItem(d.id, d.data(), 'queue:${d.id}');
      if (item != null) items.add(item);
    }
    _queue.value = items;
  }

  @override
  Future<void> addToQueue({required String title, required String mediaId, String subtitle = '', Duration duration = Duration.zero, MediaProvider provider = MediaProvider.youtube}) async {
    final ref = _coupleRef.collection('queue').doc();
    final sealed = await _key.sealJson({'title': title, 'subtitle': subtitle, 'durationMs': duration.inMilliseconds}, context: 'queue:${ref.id}');
    await ref.set({
      ...sealed.toJson(),
      'mediaId': mediaId,
      'provider': provider.name,
      'addedBy': _uid,
      'order': DateTime.now().millisecondsSinceEpoch,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFromQueue(String id) => _coupleRef.collection('queue').doc(id).delete();

  @override
  Future<void> reorderQueue(List<String> orderedIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(_coupleRef.collection('queue').doc(orderedIds[i]), {'order': i});
    }
    await batch.commit();
  }

  @override
  Stream<PlaybackState?> get playback => _playback.stream;

  @override
  Future<void> updatePlayback(PlaybackState Function(PlaybackState? current) update) async {
    if (_coupleId == null) return;
    await _live('playback').runTransaction((current) {
      final now = PlaybackState.fromJson(current);
      final next = update(now);
      return PlaybackSync.isNewer(next, now) ? Transaction.success(next.toJson()) : Transaction.abort();
    });
  }

  @override
  Stream<List<Playlist>> get playlists => _playlists.stream;

  Future<void> _onPlaylists(QuerySnapshot<Map<String, dynamic>> snap) async {
    final lists = <Playlist>[];
    for (final d in snap.docs) {
      final data = d.data();
      final sealed = Sealed.fromJson(data);
      if (sealed == null || _cipher == null) continue;
      try {
        final p = await _cipher!.openJson(sealed, context: 'playlist:${d.id}');
        final items = <QueueItem>[];
        for (final raw in (data['items'] as List? ?? const [])) {
          if (raw is! Map) continue;
          final entry = Map<String, dynamic>.from(raw);
          final id = entry['id'] as String? ?? '';
          final item = await _decodeItem(id, entry, 'playlist:${d.id}:$id');
          if (item != null) items.add(item);
        }
        lists.add(Playlist(id: d.id, name: p['name'] as String? ?? 'Playlist', items: items));
      } on DecryptionFailed {
        continue;
      }
    }
    _playlists.value = lists;
  }

  @override
  Future<void> createPlaylist(String name) async {
    final ref = _coupleRef.collection('playlists').doc();
    final sealed = await _key.sealJson({'name': name}, context: 'playlist:${ref.id}');
    await ref.set({...sealed.toJson(), 'items': [], 'createdBy': _uid, 'createdAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> addToPlaylist(String playlistId, {required String title, required String mediaId, String subtitle = ''}) async {
    final id = _db.collection('_').doc().id;
    final sealed = await _key.sealJson({'title': title, 'subtitle': subtitle}, context: 'playlist:$playlistId:$id');
    await _coupleRef.collection('playlists').doc(playlistId).update({
      'items': FieldValue.arrayUnion([
        {'id': id, ...sealed.toJson(), 'mediaId': mediaId, 'provider': 'youtube', 'addedBy': _uid},
      ]),
    });
  }

  @override
  Future<void> removeFromPlaylist(String playlistId, String itemId) async {
    final ref = _coupleRef.collection('playlists').doc(playlistId);
    await _db.runTransaction((tx) async {
      final items = List<Object?>.from((await tx.get(ref)).data()?['items'] as List? ?? const []);
      items.removeWhere((i) => i is Map && i['id'] == itemId);
      tx.update(ref, {'items': items});
    });
  }

  @override
  Stream<MovieCountdown?> get countdown => _countdown.stream;

  void _onCountdown(DatabaseEvent e) {
    final v = e.snapshot.value;
    if (v is! Map || v['startAt'] is! num) return;
    final startServer = (v['startAt'] as num).toInt();
    _countdown.value = MovieCountdown(
      service: '${v['service'] ?? 'Movie'}',
      startAt: DateTime.fromMillisecondsSinceEpoch(startServer - clock.offsetMs),
      by: '${v['by'] ?? ''}',
    );
  }

  @override
  Future<void> startCountdown(String service) async {
    await _live('countdown').set({'service': service, 'startAt': clock.nowMs() + 4000, 'by': _uid});
  }

  // ── Daily question ───────────────────────────────────────────────────────

  @override
  Stream<DailySpark?> get todaySpark => _spark.stream;

  String? _sparkId;

  Future<void> _loadSpark() async {
    try {
      final result = await _call('ensureTodaySpark');
      final id = result['id'] as String?;
      if (id == null) return;
      _sparkId = id;
      final ref = _coupleRef.collection('sparks').doc(id);
      _coupleSubs.add(ref.snapshots().listen((_) => _refreshSpark(id), onError: _ignore));
    } on Exception catch (e) {
      debugPrint('Daily question unavailable: $e');
    }
  }

  Future<String?> _readAnswer(String sparkId, String uid) async {
    final doc = await _coupleRef.collection('sparks').doc(sparkId).collection('answers').doc(uid).get();
    final sealed = Sealed.fromJson(doc.data() ?? const {});
    if (sealed == null) return null;
    try {
      return utf8.decode(await _key.open(sealed, context: 'spark:$sparkId:$uid'));
    } on DecryptionFailed {
      return '🔒 (sealed with an older key)';
    }
  }

  Future<void> _refreshSpark(String id) async {
    final uid = _user?.uid;
    final partner = _partnerId;
    if (uid == null || partner == null || _sparkId != id) return;
    final doc = await _coupleRef.collection('sparks').doc(id).get();
    final data = doc.data();
    if (data == null) return;
    final answered = Map<String, Object?>.from(data['answered'] as Map? ?? const {});
    final mine = answered[uid] == true ? await _readAnswer(id, uid) : null;
    final partnerAnswered = answered[partner] == true;
    // The rules only let you read your partner's answer once yours exists.
    final theirs = mine != null && partnerAnswered ? await _readAnswer(id, partner) : null;
    _spark.value = DailySpark(id: id, prompt: data['prompt'] as String? ?? '', myAnswer: mine, partnerAnswered: partnerAnswered, partnerAnswer: theirs);
  }

  @override
  Future<void> answerSpark(String sparkId, String answer) async {
    final sealed = await _key.seal(utf8.encode(answer), context: 'spark:$sparkId:$_uid');
    await _coupleRef.collection('sparks').doc(sparkId).collection('answers').doc(_uid).set({...sealed.toJson(), 'createdAt': FieldValue.serverTimestamp()});
    // Show my answer right away; the server marks "answered" for both phones.
    final current = _spark.value;
    if (current != null) {
      _spark.value = DailySpark(id: current.id, prompt: current.prompt, myAnswer: answer, partnerAnswered: current.partnerAnswered, partnerAnswer: current.partnerAnswer);
    }
  }

  @override
  Future<List<DailySpark>> pastSparks() async {
    final uid = _uid;
    final partner = _partnerId;
    if (partner == null) return const [];
    final snap = await _coupleRef.collection('sparks').orderBy('createdAt', descending: true).limit(30).get();
    final out = <DailySpark>[];
    for (final d in snap.docs) {
      if (d.id == _sparkId) continue;
      final answered = Map<String, Object?>.from(d.data()['answered'] as Map? ?? const {});
      if (answered[uid] != true || answered[partner] != true) continue;
      out.add(DailySpark(
        id: d.id,
        prompt: d.data()['prompt'] as String? ?? '',
        myAnswer: await _readAnswer(d.id, uid),
        partnerAnswered: true,
        partnerAnswer: await _readAnswer(d.id, partner),
      ));
    }
    return out;
  }

  @override
  Future<List<String>> generateQuestions(String theme) async {
    final result = await _call('generateQuestions', {'theme': theme});
    return [for (final q in (result['questions'] as List? ?? const [])) if (q is String) q];
  }

  // ── Location ─────────────────────────────────────────────────────────────

  @override
  Stream<PartnerLocation?> get partnerLocation => _partnerLocation.stream;

  @override
  Stream<LocationShare> get myLocationShare => _myShare.stream;

  StreamSubscription<Position>? _locationSub;
  Timer? _shareEnd;
  GeoPoint? _myPoint;
  DocumentSnapshot<Map<String, dynamic>>? _partnerLocationDoc;

  Future<void> _onPartnerLocation(DocumentSnapshot<Map<String, dynamic>> doc) async {
    _partnerLocationDoc = doc;
    final data = doc.data();
    final sealed = data == null ? null : Sealed.fromJson(data);
    final expires = data?['expiresAt'];
    if (sealed == null || _cipher == null || (expires is Timestamp && expires.toDate().isBefore(DateTime.now()))) {
      _partnerLocation.value = null;
      return;
    }
    try {
      final p = await _cipher!.openJson(sealed, context: 'location:${doc.id}');
      final point = GeoPoint((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble());
      final me = _myPoint;
      _partnerLocation.value = PartnerLocation(
        point: point,
        updatedAt: _time(data!['updatedAt']),
        approximate: p['approx'] == true,
        distanceKm: me == null ? null : Geolocator.distanceBetween(me.lat, me.lng, point.lat, point.lng) / 1000,
      );
    } on DecryptionFailed {
      _partnerLocation.value = null;
    }
  }

  @override
  Future<void> startSharing({Duration? duration, bool approximate = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) throw const BackendException('Turn on location in your phone’s settings.');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const BackendException('Allow location access to share where you are.');
    }
    await _locationSub?.cancel();
    _shareEnd?.cancel();
    final until = duration == null ? null : DateTime.now().add(duration);
    final uid = _uid;
    final ref = _coupleRef.collection('locations').doc(uid);
    Future<void> publish(Position pos) async {
      // Approximate sharing rounds to about 1 km before encrypting.
      final lat = approximate ? (pos.latitude * 100).round() / 100 : pos.latitude;
      final lng = approximate ? (pos.longitude * 100).round() / 100 : pos.longitude;
      _myPoint = GeoPoint(pos.latitude, pos.longitude);
      _myShare.value = LocationShare(active: true, until: until, approximate: approximate, myPoint: _myPoint);
      final sealed = await _key.sealJson({'lat': lat, 'lng': lng, 'acc': pos.accuracy, 'approx': approximate}, context: 'location:$uid');
      // "Until I stop" renews a 2-hour expiry on every update, so a phone
      // that dies doesn't leave a location behind forever.
      final expires = until ?? DateTime.now().add(const Duration(hours: 2));
      await ref.set({...sealed.toJson(), 'updatedAt': FieldValue.serverTimestamp(), 'expiresAt': Timestamp.fromDate(expires)});
      final partnerDoc = _partnerLocationDoc;
      if (partnerDoc != null) unawaited(_onPartnerLocation(partnerDoc));
    }

    _myShare.value = LocationShare(active: true, until: until, approximate: approximate, myPoint: _myPoint);
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: approximate ? LocationAccuracy.low : LocationAccuracy.high,
            distanceFilter: 25,
            intervalDuration: const Duration(seconds: 20),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Sharing your location',
              notificationText: 'Your partner can see where you are. Open the app to stop.',
              enableWakeLock: false,
            ),
          )
        : const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 25);
    _locationSub = Geolocator.getPositionStream(locationSettings: settings).listen(publish, onError: (Object e) => debugPrint('Location: $e'));
    if (until != null) _shareEnd = Timer(duration!, stopSharing);
  }

  @override
  Future<void> stopSharing() async {
    _shareEnd?.cancel();
    await _locationSub?.cancel();
    _locationSub = null;
    _myShare.value = LocationShare(myPoint: _myPoint);
    if (_coupleId != null && _user != null) {
      try {
        await _coupleRef.collection('locations').doc(_uid).delete();
      } on Exception catch (e) {
        debugPrint('Location not removed: $e');
      }
    }
  }

  // ── Memories ─────────────────────────────────────────────────────────────

  @override
  Stream<List<Memory>> get memories => _memories.stream;

  Future<void> _onMemories(QuerySnapshot<Map<String, dynamic>> snap) async {
    final out = <Memory>[];
    for (final d in snap.docs) {
      final sealed = Sealed.fromJson(d.data());
      if (sealed == null || _cipher == null) continue;
      try {
        final p = await _cipher!.openJson(sealed, context: 'memory:${d.id}');
        final media = p['media'] as Map?;
        final key = MediaKey.fromJson(media);
        final path = media?['path'] as String?;
        out.add(Memory(
          id: d.id,
          title: p['title'] as String? ?? '',
          note: p['note'] as String? ?? '',
          date: _time(d.data()['date']),
          place: p['place'] as String?,
          locked: p['locked'] == true,
          image: path != null && key != null ? EncryptedImage(path: path, key: key, download: _download) : null,
        ));
      } on DecryptionFailed {
        continue;
      }
    }
    _memories.value = out;
  }

  @override
  Future<void> addMemory({required String title, String note = '', String? photoPath, bool locked = false}) async {
    final ref = _coupleRef.collection('memories').doc();
    Map<String, Object?>? media;
    if (photoPath != null) {
      final path = await _uploadEncrypted(await File(photoPath).readAsBytes(), 'img');
      media = {'path': path, ..._pendingKeys.remove(path)!.toJson()};
    }
    final sealed = await _key.sealJson({'title': title, 'note': note, 'locked': locked, 'media': ?media}, context: 'memory:${ref.id}');
    await ref.set({...sealed.toJson(), 'by': _uid, 'date': Timestamp.now(), 'createdAt': FieldValue.serverTimestamp()});
  }

  // ── Calls ────────────────────────────────────────────────────────────────

  @override
  Stream<CallInfo?> get incomingCall => _incoming.stream;

  void _onCalls(QuerySnapshot<Map<String, dynamic>> snap) {
    final uid = _user?.uid;
    CallInfo? ringing;
    for (final d in snap.docs) {
      final data = d.data();
      final created = _time(data['createdAt']);
      if (data['caller'] == uid || DateTime.now().difference(created) > const Duration(seconds: 60)) continue;
      ringing = CallInfo(id: d.id, video: data['video'] == true, incoming: true);
    }
    if (ringing?.id != _incoming.value?.id) _incoming.value = ringing;
  }

  Future<CallSession> _connect(CallInfo info, Map<String, Object?> grant) async {
    final url = grant['url'] as String?;
    final token = grant['token'] as String?;
    if (url == null || token == null) throw const BackendException('Calls aren’t set up on the server yet.');
    return LiveKitCallSession.connect(
      info: info,
      url: url,
      token: token,
      mediaKey: await _key.deriveSubKey('call-media'),
      onHangUp: () => _call('endCall', {'callId': info.id}),
    );
  }

  @override
  Future<CallSession> startCall({required bool video}) async {
    final grant = await _call('startCall', {'video': video});
    return _connect(CallInfo(id: grant['callId'] as String, video: video, incoming: false), grant);
  }

  @override
  Future<CallSession> answerCall(CallInfo call) async {
    _incoming.value = null;
    final grant = await _call('joinCall', {'callId': call.id});
    return _connect(call, grant);
  }

  @override
  Future<void> declineCall(CallInfo call) async {
    _incoming.value = null;
    await _call('endCall', {'callId': call.id, 'reason': 'declined'});
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _authSub?.cancel();
    for (final s in [..._userSubs, ..._coupleSubs]) {
      await s.cancel();
    }
    await _locationSub?.cancel();
    _shareEnd?.cancel();
  }
}
