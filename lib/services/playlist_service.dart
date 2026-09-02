// Generates the playlist tied to a specific journal entry: fetch candidate
// tracks via `deezer_service.dart`, then persist a `playlists` row plus its
// `playlist_tracks` rows (Requirements §3/§4, schema in docs/SCHEMA.md).

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/deezer_track.dart';
import 'deezer_service.dart';

const _defaultTrackCount = 15;

/// Generates (or regenerates) the playlist for [journalEntryId].
///
/// `playlists.journal_entry_id` is unique (one playlist per entry), so this
/// upserts the playlist row and replaces its tracks outright — re-saving an
/// entry with a changed mood produces a fresh playlist rather than growing
/// a stale one.
///
/// Returns the playlist's id. Throws a [StateError] if no user is signed in
/// or Deezer returns no usable tracks for this mood/intensity.
Future<String> generatePlaylistForJournalEntry({
  required String journalEntryId,
  required String mood,
  required int moodIntensity,
  int trackCount = _defaultTrackCount,
}) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    throw StateError('Cannot generate a playlist without a signed-in user.');
  }

  final candidates = await fetchTracksForMood(mood, moodIntensity);
  if (candidates.isEmpty) {
    throw StateError(
      'No Deezer tracks found for mood "$mood" at intensity $moodIntensity.',
    );
  }
  candidates.shuffle();
  final selected = candidates.take(trackCount).toList();

  final playlist = await client
      .from('playlists')
      .upsert({
        'journal_entry_id': journalEntryId,
        'user_id': userId,
        'mood': mood,
        'mood_intensity': moodIntensity,
      }, onConflict: 'journal_entry_id')
      .select('id')
      .single();
  final playlistId = playlist['id'] as String;

  await client.from('playlist_tracks').delete().eq('playlist_id', playlistId);
  await client
      .from('playlist_tracks')
      .insert([
        for (var i = 0; i < selected.length; i++)
          playlistTrackRow(
            playlistId: playlistId,
            userId: userId,
            position: i,
            track: selected[i],
          ),
      ]);

  return playlistId;
}

/// Row shape for a `playlist_tracks` insert — a pure function so it's
/// testable without a live Supabase call.
Map<String, dynamic> playlistTrackRow({
  required String playlistId,
  required String userId,
  required int position,
  required DeezerTrack track,
}) {
  return {
    'playlist_id': playlistId,
    'user_id': userId,
    'position': position,
    'deezer_track_id': track.deezerId,
    'title': track.title,
    'artist': track.artist,
    'preview_url': track.previewUrl,
    'artwork_url': track.albumCoverUrl,
  };
}
