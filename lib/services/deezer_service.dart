// Calls the Deezer search API (free, unauthenticated — see ARCHITECTURE.md)
// to fetch tracks for the search terms produced by `mood_music_mapping.dart`.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/deezer_track.dart';
import 'mood_music_mapping.dart';

const _searchEndpoint = 'https://api.deezer.com/search';

Future<http.Response> _get(Uri uri, http.Client? client) {
  return client == null ? http.get(uri) : client.get(uri);
}

/// Searches Deezer for [query], returning up to [limit] tracks.
///
/// Some Deezer results have no preview available; those are filtered out
/// since the app's player (Requirements §3) depends on `previewUrl`.
/// Pass [client] to inject a test double — a real request is made by
/// default.
Future<List<DeezerTrack>> searchDeezerTracks(
  String query, {
  int limit = 10,
  http.Client? client,
}) async {
  final uri = Uri.parse(_searchEndpoint).replace(
    queryParameters: {'q': query, 'limit': '$limit'},
  );
  final response = await _get(uri, client);
  if (response.statusCode != 200) {
    throw Exception(
      'Deezer search failed (${response.statusCode}) for "$query"',
    );
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final data = body['data'] as List<dynamic>? ?? const [];
  return [
    for (final entry in data.cast<Map<String, dynamic>>())
      if ((entry['preview'] as String?)?.isNotEmpty ?? false)
        DeezerTrack.fromJson(entry),
  ];
}

/// Fetches candidate tracks for a mood + intensity: runs every rule-based
/// search term from [deezerSearchTermsFor] against Deezer in parallel and
/// merges the results, de-duplicated by Deezer track id (the same track
/// can surface under more than one search term).
Future<List<DeezerTrack>> fetchTracksForMood(
  String mood,
  int intensity, {
  int perTerm = 10,
  http.Client? client,
}) async {
  final terms = deezerSearchTermsFor(mood, intensity);
  final results = await Future.wait([
    for (final term in terms)
      searchDeezerTracks(term, limit: perTerm, client: client),
  ]);

  final seenIds = <int>{};
  final tracks = <DeezerTrack>[];
  for (final batch in results) {
    for (final track in batch) {
      if (seenIds.add(track.deezerId)) {
        tracks.add(track);
      }
    }
  }
  return tracks;
}
