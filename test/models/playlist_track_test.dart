import 'package:flutter_test/flutter_test.dart';
import 'package:laylow/models/playlist_track.dart';

void main() {
  group('PlaylistTrack', () {
    test('fromRow parses a playlist_tracks row', () {
      final track = PlaylistTrack.fromRow({
        'id': 't1',
        'position': 2,
        'title': 'Title',
        'artist': 'Artist',
        'preview_url': 'https://preview.example/1.mp3',
        'artwork_url': 'https://cover.example/1.jpg',
        'youtube_video_id': null,
        'deezer_track_id': 42,
      });

      expect(track.id, 't1');
      expect(track.position, 2);
      expect(track.youtubeVideoId, isNull);
      expect(track.deezerTrackId, 42);
    });

    test('withYoutubeVideoId returns a copy with only that field changed', () {
      const track = PlaylistTrack(
        id: 't1',
        position: 0,
        title: 'Title',
        artist: 'Artist',
        previewUrl: 'https://preview.example/1.mp3',
        artworkUrl: null,
        youtubeVideoId: null,
        deezerTrackId: 42,
      );

      final updated = track.withYoutubeVideoId('abc123');

      expect(updated.youtubeVideoId, 'abc123');
      expect(updated.id, track.id);
      expect(updated.title, track.title);
      expect(updated.previewUrl, track.previewUrl);
    });
  });
}
