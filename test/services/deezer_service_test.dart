import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:laylow/services/deezer_service.dart';

Map<String, dynamic> _track(int id, {String? preview}) {
  return {
    'id': id,
    'title': 'Track $id',
    'preview': preview,
    'artist': {'name': 'Artist $id'},
    'album': {'cover_medium': 'https://cover.example/$id.jpg'},
  };
}

void main() {
  group('searchDeezerTracks', () {
    test('parses tracks from a successful response', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['q'], 'energetic pop');
        return http.Response(
          jsonEncode({
            'data': [
              _track(1, preview: 'https://preview.example/1.mp3'),
              _track(2, preview: 'https://preview.example/2.mp3'),
            ],
          }),
          200,
        );
      });

      final tracks = await searchDeezerTracks('energetic pop', client: client);

      expect(tracks, hasLength(2));
      expect(tracks[0].deezerId, 1);
      expect(tracks[0].title, 'Track 1');
      expect(tracks[0].artist, 'Artist 1');
      expect(tracks[0].previewUrl, 'https://preview.example/1.mp3');
    });

    test('filters out tracks with no preview', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'data': [
              _track(1, preview: 'https://preview.example/1.mp3'),
              _track(2, preview: null),
              _track(3, preview: ''),
            ],
          }),
          200,
        );
      });

      final tracks = await searchDeezerTracks('sad songs', client: client);

      expect(tracks.map((t) => t.deezerId), [1]);
    });

    test('throws on a non-200 response', () async {
      final client = MockClient((request) async => http.Response('', 500));

      expect(
        () => searchDeezerTracks('chill', client: client),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('fetchTracksForMood', () {
    test('merges and de-duplicates tracks across search terms', () async {
      final client = MockClient((request) async {
        // Every term for 'happy' at intensity 3 returns overlapping track 1
        // plus a term-specific track, to exercise de-duplication.
        final query = request.url.queryParameters['q']!;
        final termSpecificId = query.hashCode.abs() % 1000 + 100;
        return http.Response(
          jsonEncode({
            'data': [
              _track(1, preview: 'https://preview.example/1.mp3'),
              _track(termSpecificId, preview: 'https://preview.example/$termSpecificId.mp3'),
            ],
          }),
          200,
        );
      });

      final tracks = await fetchTracksForMood('happy', 3, client: client);

      final ids = tracks.map((t) => t.deezerId).toList();
      expect(ids.toSet().length, ids.length, reason: 'no duplicate ids');
      expect(ids.where((id) => id == 1).length, 1);
      expect(tracks.length, greaterThan(1));
    });
  });
}
