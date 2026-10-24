import 'package:flutter/widgets.dart';

/// Signed-in account (before or after pairing).
class Account {
  const Account({required this.uid, required this.name, this.email, this.photo});

  final String uid;
  final String name;
  final String? email;
  final ImageProvider? photo;
}

class Person {
  const Person({required this.id, required this.name, this.photo});

  final String id;
  final String name;
  final ImageProvider? photo;
}

/// The paired couple.
class Couple {
  const Couple({required this.id, required this.me, required this.partner, required this.since, required this.safetyEmojis, this.keyChanged = false});

  final String id;
  final Person me;
  final Person partner;
  final DateTime since;

  /// Four emojis derived from both public keys; equal on both phones.
  final List<String> safetyEmojis;

  /// The partner's key changed since it was last verified (new phone?).
  final bool keyChanged;

  int get daysTogether => DateTime.now().difference(since).inDays;
}

/// Pairing invite shown as a code and a QR.
class Invite {
  const Invite({required this.code, required this.expiresAt, required this.qrPayload});

  final String code;
  final DateTime expiresAt;
  final String qrPayload;
}

class Presence {
  const Presence({this.online = false, this.lastSeen, this.typing = false});

  final bool online;
  final DateTime? lastSeen;
  final bool typing;
}

enum MessageKind { text, photo, voice, lockedMoment }

enum MessageStatus { sending, sent, read, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    required this.kind,
    required this.sentAt,
    this.text,
    this.image,
    this.duration,
    this.audio,
    this.riddle,
    this.answer,
    this.status = MessageStatus.sent,
    this.hearts = 0,
  });

  final String id;
  final bool mine;
  final MessageKind kind;
  final DateTime sentAt;
  final String? text;

  /// Photo (decrypted bytes, local file or demo asset).
  final ImageProvider? image;

  /// Voice note length.
  final Duration? duration;

  /// Fetches (and decrypts) the voice note; returns a local file path.
  /// Null in the demo, where playback is simulated.
  final Future<String?> Function()? audio;

  /// Locked moment riddle and its expected answer (lower-case).
  final String? riddle;
  final String? answer;

  final MessageStatus status;
  final int hearts;

  ChatMessage copyWith({MessageStatus? status, int? hearts}) => ChatMessage(
        id: id,
        mine: mine,
        kind: kind,
        sentAt: sentAt,
        text: text,
        image: image,
        duration: duration,
        audio: audio,
        riddle: riddle,
        answer: answer,
        status: status ?? this.status,
        hearts: hearts ?? this.hearts,
      );
}

enum MediaProvider { youtube, spotify, link }

class QueueItem {
  const QueueItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.addedBy,
    this.provider = MediaProvider.youtube,
    this.mediaId = '',
    this.thumbnail,
  });

  final String id;
  final String title;
  final String subtitle;
  final Duration duration;

  /// First name of whoever added it.
  final String addedBy;
  final MediaProvider provider;

  /// YouTube video id (or the link for other providers).
  final String mediaId;
  final ImageProvider? thumbnail;

  String get durationLabel {
    final h = duration.inHours, m = duration.inMinutes % 60, s = duration.inSeconds % 60;
    final mm = h > 0 ? m.toString().padLeft(2, '0') : '$m';
    return '${h > 0 ? '$h:' : ''}$mm:${s.toString().padLeft(2, '0')}';
  }
}

class Playlist {
  const Playlist({required this.id, required this.name, this.items = const []});

  final String id;
  final String name;
  final List<QueueItem> items;
}

/// Movie Night: both phones count down to [startAt] (server time).
class MovieCountdown {
  const MovieCountdown({required this.service, required this.startAt, required this.by});

  final String service;
  final DateTime startAt;
  final String by;
}

/// Daily question. The partner's answer is only revealed after you answer.
class DailySpark {
  const DailySpark({required this.id, required this.prompt, this.myAnswer, this.partnerAnswered = false, this.partnerAnswer});

  final String id;
  final String prompt;
  final String? myAnswer;
  final bool partnerAnswered;
  final String? partnerAnswer;

  bool get answered => myAnswer != null;
  bool get revealed => myAnswer != null && partnerAnswer != null;
}

class Memory {
  const Memory({required this.id, required this.title, required this.date, this.note = '', this.image, this.locked = false, this.place});

  final String id;
  final String title;
  final String note;
  final DateTime date;
  final ImageProvider? image;
  final bool locked;
  final String? place;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

class PartnerLocation {
  const PartnerLocation({required this.point, required this.updatedAt, this.approximate = false, this.distanceKm});

  final GeoPoint point;
  final DateTime updatedAt;
  final bool approximate;

  /// Distance from me, when my own position is known.
  final double? distanceKm;
}

/// My own location sharing state.
class LocationShare {
  const LocationShare({this.active = false, this.until, this.approximate = false, this.myPoint});

  final bool active;

  /// My last known position (while sharing).
  final GeoPoint? myPoint;

  /// Null while active means "until I stop".
  final DateTime? until;
  final bool approximate;
}

enum CallState { ringing, connecting, active, ended }

class CallInfo {
  const CallInfo({required this.id, required this.video, required this.incoming, this.state = CallState.ringing});

  final String id;
  final bool video;
  final bool incoming;
  final CallState state;
}
