import 'package:amour_partage/features/together/youtube_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads video ids from common YouTube links', () {
    const id = 'dQw4w9WgXcQ';
    for (final link in [
      'https://www.youtube.com/watch?v=$id',
      'https://youtube.com/watch?v=$id&t=42s',
      'https://m.youtube.com/watch?v=$id',
      'https://youtu.be/$id',
      'https://youtu.be/$id?si=abc',
      'https://www.youtube.com/shorts/$id',
      'https://www.youtube.com/embed/$id',
      'https://music.youtube.com/watch?v=$id&list=RD',
      'youtube.com/watch?v=$id',
      id,
    ]) {
      expect(youtubeVideoId(link), id, reason: link);
    }
  });

  test('rejects other links', () {
    expect(youtubeVideoId('https://open.spotify.com/track/abc'), isNull);
    expect(youtubeVideoId('https://www.youtube.com/@channel'), isNull);
    expect(youtubeVideoId('hello'), isNull);
    expect(youtubeVideoId('https://evil.com/watch?v=dQw4w9WgXcQ'), isNull);
  });
}
