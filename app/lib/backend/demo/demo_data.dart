import '../../data/demo_images.dart';
import '../../data/models.dart';

/// Sample content for the demo build (no server configured) and tests.
abstract final class DemoData {
  static const me = Person(id: 'demo-julian', name: 'Julian', photo: DemoImages.julian);
  static const partner = Person(id: 'demo-camille', name: 'Camille', photo: DemoImages.camille);
  static const safetyEmojis = ['🦊', '🌙', '🎧', '🍓'];

  static DateTime get since => DateTime.now().subtract(const Duration(days: 428));

  static List<ChatMessage> messages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'm1',
        mine: false,
        kind: MessageKind.text,
        sentAt: now.subtract(const Duration(minutes: 42)),
        text: 'Are we still doing the watch party tonight? 🍿',
        hearts: 1,
      ),
      ChatMessage(
        id: 'm2',
        mine: true,
        kind: MessageKind.text,
        sentAt: now.subtract(const Duration(minutes: 40)),
        text: 'Yes! I queued our favourite playlist already.',
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: 'm3',
        mine: false,
        kind: MessageKind.lockedMoment,
        sentAt: now.subtract(const Duration(minutes: 38)),
        image: DemoImages.lockedTeaser,
        riddle: 'Where did we have our first gelato?',
        answer: 'rome',
      ),
      ChatMessage(
        id: 'm4',
        mine: true,
        kind: MessageKind.voice,
        sentAt: now.subtract(const Duration(minutes: 36)),
        duration: const Duration(seconds: 24),
        status: MessageStatus.read,
      ),
    ];
  }

  static const replies = ['Aww 🥹 you’re the best', 'Can’t wait!! 💞', 'Popcorn’s on me 🍿', 'Haha stop it 😂❤️', 'Counting the minutes ✨'];

  static const queue = <QueueItem>[
    QueueItem(
      id: 'q0',
      title: 'Lo-fi beats to relax to',
      subtitle: 'Late night session',
      duration: Duration(minutes: 6, seconds: 18),
      addedBy: 'Julian',
      mediaId: 'jfKfPfyJRdk',
      thumbnail: DemoImages.neonStreet,
    ),
    QueueItem(
      id: 'q1',
      title: 'Apocalypse',
      subtitle: 'Cigarettes After Sex',
      duration: Duration(minutes: 4, seconds: 50),
      addedBy: 'Camille',
      mediaId: 'sElE_BfQ67s',
      thumbnail: DemoImages.queueApocalypse,
    ),
    QueueItem(
      id: 'q2',
      title: 'Studio Ghibli ambient mix',
      subtitle: 'Joe Hisaishi',
      duration: Duration(minutes: 32, seconds: 14),
      addedBy: 'Julian',
      mediaId: '3jWRrafhO7M',
      thumbnail: DemoImages.queueGhibli,
    ),
    QueueItem(
      id: 'q3',
      title: 'Paris sunset walk',
      subtitle: '4K walking tour',
      duration: Duration(minutes: 45),
      addedBy: 'Camille',
      mediaId: 'wOGVnN0jwNk',
      thumbnail: DemoImages.queueParis,
    ),
  ];

  static final playlists = <Playlist>[
    Playlist(id: 'p1', name: 'Our songs', items: [queue[1], queue[0]]),
    Playlist(id: 'p2', name: 'Watch later', items: [queue[3]]),
    const Playlist(id: 'p3', name: 'Movie night'),
  ];

  static const spark = DailySpark(
    id: 'today',
    prompt: 'What song takes you straight back to our first trip?',
    partnerAnswered: true,
  );

  static const aiQuestions = {
    'fun': ['What would our couple superhero name be?', 'Which snack best describes our relationship?', 'What song would play when we walk into a room?'],
    'deep': ['When do you feel most at home with me?', 'What’s something you’re learning about yourself lately?', 'What does a good day together feel like to you?'],
    'future': ['What’s one trip we should take before we’re 40?', 'What tradition do you want us to keep forever?', 'What would our dream weekend home look like?'],
    'memories': ['What’s a small moment with me you still think about?', 'Which photo of us makes you smile the most?', 'What did you think of me the first time we met?'],
  };

  static const sparkPartnerAnswer = '“La Vie en Rose”. You hummed it the whole train ride to Lyon 🥹';

  static const pastSparks = <DailySpark>[
    DailySpark(
      id: 'd1',
      prompt: 'What tiny habit of mine secretly makes your day?',
      myAnswer: 'Your 7am voice notes, even half asleep.',
      partnerAnswered: true,
      partnerAnswer: 'How you always leave me the last bite.',
    ),
    DailySpark(
      id: 'd2',
      prompt: 'If we could teleport anywhere tonight, where would we go?',
      myAnswer: 'Back to that rooftop in Lisbon.',
      partnerAnswered: true,
      partnerAnswer: 'Kyoto in the rain, obviously ☔',
    ),
    DailySpark(
      id: 'd3',
      prompt: 'Which memory of us would you replay forever?',
      myAnswer: 'Big Sur. Coffee, fog, you.',
      partnerAnswered: true,
      partnerAnswer: 'Our first Big Sur sunrise ☕',
    ),
  ];

  static List<Memory> memories() => [
        Memory(id: 'v1', title: 'Montmartre', note: 'Café crèmes near Sacré-Cœur and a late walk on the cobblestones.', date: DateTime(2025, 10, 12), image: DemoImages.montmartre, place: 'Paris'),
        Memory(id: 'v2', title: 'Rainy Kyoto evening', date: DateTime(2025, 10, 14), image: DemoImages.kyoto, place: 'Kyoto'),
        Memory(id: 'v3', title: 'Big Sur sunrise', date: DateTime(2025, 9, 29), image: DemoImages.bigSur, place: 'California'),
        Memory(id: 'v4', title: 'First movie night', date: DateTime(2025, 8, 12), image: DemoImages.movieNight),
        Memory(id: 'v5', title: 'Midnight stargazing', note: 'A voice memo under the stars.', date: DateTime(2025, 9, 3), image: DemoImages.stargazing, locked: true),
      ];

  /// Le Marais (partner) and near Gare de l'Est (me), about 2.4 miles apart.
  static const partnerPoint = GeoPoint(48.8590, 2.3622);
  static const myPoint = GeoPoint(48.8862, 2.3330);

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
