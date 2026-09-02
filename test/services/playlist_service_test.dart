import 'package:flutter_test/flutter_test.dart';
import 'package:laylow/models/deezer_track.dart';
import 'package:laylow/services/playlist_service.dart';

void main() {
  group('playlistTrackRow', () {
    test('maps a DeezerTrack into a playlist_tracks row shape', () {
      const track = DeezerTrack(
        deezerId: 42,
        title: 'Track Title',
        artist: 'Track Artist',
        previewUrl: 'https://preview.example/42.mp3',
        albumCoverUrl: 'https://cover.example/42.jpg',
      );

      final row = playlistTrackRow(
        playlistId: 'playlist-1',
        userId: 'user-1',
        position: 3,
        track: track,
      );

      expect(row, {
        'playlist_id': 'playlist-1',
        'user_id': 'user-1',
        'position': 3,
        'deezer_track_id': 42,
        'title': 'Track Title',
        'artist': 'Track Artist',
        'preview_url': 'https://preview.example/42.mp3',
        'artwork_url': 'https://cover.example/42.jpg',
      });
    });

    test('carries a null album cover through as null artwork_url', () {
      const track = DeezerTrack(
        deezerId: 1,
        title: 'T',
        artist: 'A',
        previewUrl: 'https://preview.example/1.mp3',
        albumCoverUrl: null,
      );

      final row = playlistTrackRow(
        playlistId: 'p',
        userId: 'u',
        position: 0,
        track: track,
      );

      expect(row['artwork_url'], isNull);
    });
  });
}
