// Finds a full-song YouTube video for a track, supplementing Deezer's
// 30-second preview with full playback (ARCHITECTURE.md's "YouTube
// embedded player"). Uses youtube_explode_dart, which scrapes YouTube's
// public search page rather than calling the quota-limited YouTube Data
// API — no API key needed, matching the app's zero-budget stack.

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Search query for a track's full song — split out so it's testable
/// without a network call.
String youtubeSearchQuery(String title, String artist) => '$title $artist';

/// Returns the video id of the top YouTube search result for [title] by
/// [artist], or null if the search failed or found nothing.
Future<String?> findYoutubeVideoId(String title, String artist) async {
  final yt = YoutubeExplode();
  try {
    final results = await yt.search.search(youtubeSearchQuery(title, artist));
    return results.isEmpty ? null : results.first.id.value;
  } finally {
    yt.close();
  }
}
