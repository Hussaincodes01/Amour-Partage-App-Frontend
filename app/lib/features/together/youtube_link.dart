import 'dart:convert';
import 'dart:io';

/// Video id from any common YouTube link (watch, youtu.be, shorts, embed,
/// music), or a bare 11-character id. Null if it isn't a YouTube video link.
String? youtubeVideoId(String input) {
  final text = input.trim();
  final bare = RegExp(r'^[A-Za-z0-9_-]{11}$');
  if (bare.hasMatch(text)) return text;
  final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
  if (uri == null) return null;
  final host = uri.host.toLowerCase().replaceFirst('www.', '').replaceFirst('m.', '');
  String? candidate;
  if (host == 'youtu.be') {
    candidate = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if (host == 'youtube.com' || host == 'music.youtube.com' || host == 'youtube-nocookie.com') {
    if (uri.queryParameters['v'] != null) {
      candidate = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 && const ['shorts', 'embed', 'live', 'v'].contains(uri.pathSegments.first)) {
      candidate = uri.pathSegments[1];
    }
  }
  return candidate != null && bare.hasMatch(candidate) ? candidate : null;
}

class YoutubeInfo {
  const YoutubeInfo({required this.title, required this.channel});

  final String title;
  final String channel;
}

/// Title and channel via YouTube's public oEmbed endpoint (no API key).
Future<YoutubeInfo?> fetchYoutubeInfo(String videoId) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final url = Uri.https('www.youtube.com', '/oembed', {'url': 'https://www.youtube.com/watch?v=$videoId', 'format': 'json'});
    final response = await (await client.getUrl(url)).close().timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final body = jsonDecode(await response.transform(utf8.decoder).join());
    if (body is! Map) return null;
    return YoutubeInfo(title: '${body['title'] ?? 'YouTube video'}', channel: '${body['author_name'] ?? 'YouTube'}');
  } on Exception {
    return null;
  } finally {
    client.close();
  }
}

String youtubeThumbnail(String videoId) => 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
