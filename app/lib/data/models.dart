import 'package:flutter/widgets.dart';

enum Sender { me, partner }

enum MessageKind { text, lockedMoment, voiceNote, photo }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.kind,
    required this.time,
    this.text,
    this.reactions = 0,
    this.seen = true,
    this.footnote,
    this.riddle,
    this.answer,
    this.transcript,
    this.duration,
    this.photoPath,
  });

  final String id;
  final Sender sender;
  final MessageKind kind;
  final String time;
  final String? text;
  final int reactions;
  final bool seen;
  final String? footnote;
  final String? riddle;
  final String? answer;
  final String? transcript;
  final Duration? duration;

  /// Local file path of a picked photo (before upload).
  final String? photoPath;
}

enum MediaSource { youtube, spotify }

class QueueItem {
  const QueueItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.image,
    required this.addedBy,
    this.source = MediaSource.youtube,
  });

  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final ImageProvider image;

  /// 'Camille', 'Julian' or 'Wishlist'.
  final String addedBy;
  final MediaSource source;
}

class Memory {
  const Memory({required this.title, required this.subtitle, required this.date, required this.image, this.locked = false, this.tag});

  final String title;
  final String subtitle;
  final String date;
  final ImageProvider image;
  final bool locked;
  final String? tag;
}

class SoulSpark {
  const SoulSpark({required this.number, required this.question, this.partnerAnswer, this.myAnswer, this.partnerAnsweredAgo});

  final int number;
  final String question;
  final String? partnerAnswer;
  final String? myAnswer;
  final String? partnerAnsweredAgo;

  SoulSpark withMyAnswer(String answer) =>
      SoulSpark(number: number, question: question, partnerAnswer: partnerAnswer, myAnswer: answer, partnerAnsweredAgo: partnerAnsweredAgo);
}
