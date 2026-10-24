import 'demo_images.dart';
import 'models.dart';

/// Demo content matching the Figma screens. Replaced by the encrypted sync
/// layer once the backend is wired up.
abstract final class Mock {
  static const me = 'Julian';
  static const partner = 'Camille';
  static const daysTogether = 428;

  static const messages = <ChatMessage>[
    ChatMessage(
      id: 'm1',
      sender: Sender.partner,
      kind: MessageKind.text,
      time: '9:32 PM',
      text: 'Are we still doing the YouTube watch party tonight? 🍿✨',
      reactions: 2,
    ),
    ChatMessage(
      id: 'm2',
      sender: Sender.me,
      kind: MessageKind.text,
      time: '9:34 PM',
      text: "Yes! Queued our favorite playlist already. Can't wait.",
    ),
    ChatMessage(
      id: 'm3',
      sender: Sender.partner,
      kind: MessageKind.lockedMoment,
      time: '9:36 PM',
      riddle: 'Answer the question to unlock: Where did we have our first gelato?',
      answer: 'rome',
      footnote: 'Sealed with Camille’s TouchID',
    ),
    ChatMessage(
      id: 'm4',
      sender: Sender.me,
      kind: MessageKind.voiceNote,
      time: '9:38 PM',
      duration: Duration(seconds: 24),
      transcript: '“Missing you tons today... Can’t wait to sink into the couch and listen to that retro synth playlist together.”',
    ),
  ];

  static const queue = <QueueItem>[
    QueueItem(
      id: 'q1',
      title: 'Apocalypse',
      subtitle: 'Cigarettes After Sex',
      duration: '04:50',
      image: DemoImages.queueApocalypse,
      addedBy: 'Camille',
    ),
    QueueItem(
      id: 'q2',
      title: 'Studio Ghibli Ambient Mix',
      subtitle: 'Joe Hisaishi & Orchestral',
      duration: '32:14',
      image: DemoImages.queueGhibli,
      addedBy: 'Julian',
    ),
    QueueItem(
      id: 'q3',
      title: 'Paris Sunset 4K Walk',
      subtitle: 'YouTube 4K Spatial Audio',
      duration: '45:00',
      image: DemoImages.queueParis,
      addedBy: 'Wishlist',
    ),
  ];

  static const spark = SoulSpark(
    number: 182,
    question: '“What song immediately takes you back to our very first trip?”',
    partnerAnswer: '“La Vie en Rose” — you hummed it the whole train ride to Lyon and I pretended to be annoyed 🥹',
    partnerAnsweredAgo: '2 hours ago',
  );

  static const pastSparks = <SoulSpark>[
    SoulSpark(
      number: 181,
      question: 'What tiny habit of mine secretly makes your day?',
      partnerAnswer: 'How you leave the last bite for me. Every. Single. Time.',
      myAnswer: 'Your 7am voice notes, even when you’re half asleep.',
    ),
    SoulSpark(
      number: 180,
      question: 'If we could teleport anywhere tonight, where would we go?',
      partnerAnswer: 'Kyoto in the rain, obviously ☔',
      myAnswer: 'Back to that rooftop in Lisbon.',
    ),
    SoulSpark(
      number: 179,
      question: 'Which memory of us would you replay forever?',
      partnerAnswer: 'Our first Big Sur sunrise ☕',
      myAnswer: 'Big Sur. Coffee, fog, you.',
    ),
  ];

  static const vault = <Memory>[
    Memory(title: 'Our Trip to Montmartre', subtitle: 'Shared café crèmes near Sacré-Cœur and our synchronized late night promenade along the cobblestones.', date: 'Oct 2025', image: DemoImages.montmartre, tag: 'Paris'),
    Memory(title: 'First Movie Night', subtitle: 'Synced playlist memory note & our digitized ticket', date: 'Aug 12', image: DemoImages.movieNight, tag: 'Sync Audio'),
    Memory(title: 'Midnight Stargazing', subtitle: '4-minute voice memo recording under the stars', date: 'Sep 03', image: DemoImages.stargazing, locked: true, tag: 'Locked Polaroid'),
    Memory(title: 'Rainy evening in Kyoto', subtitle: 'Oct 14 • Julian’s cam', date: 'Oct 14', image: DemoImages.kyoto),
    Memory(title: 'Big Sur sunrise coffee', subtitle: 'Sep 29 • Camille’s cam', date: 'Sep 29', image: DemoImages.bigSur),
  ];

  static const quiz = <QuizQuestion>[
    QuizQuestion('What’s Camille’s comfort movie?', ['Amélie', 'Spirited Away', 'Before Sunrise', 'La La Land'], 1),
    QuizQuestion('Her dream weekend getaway?', ['Kyoto in the rain', 'Lisbon rooftops', 'Big Sur camping', 'Paris museums'], 0),
    QuizQuestion('Her go-to late-night snack?', ['Popcorn', 'Gelato', 'Croissant', 'Ramen'], 1),
    QuizQuestion('Which love language speaks loudest to her?', ['Words of affirmation', 'Quality time', 'Physical touch', 'Acts of service'], 1),
  ];
}

class QuizQuestion {
  const QuizQuestion(this.question, this.options, this.correct);

  final String question;
  final List<String> options;
  final int correct;
}
