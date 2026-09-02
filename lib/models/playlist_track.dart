/// A single track within a generated playlist (`playlist_tracks` row).
class PlaylistTrack {
  const PlaylistTrack({
    required this.id,
    required this.position,
    required this.title,
    required this.artist,
    required this.previewUrl,
    required this.artworkUrl,
    required this.youtubeVideoId,
    required this.deezerTrackId,
  });

  factory PlaylistTrack.fromRow(Map<String, dynamic> row) {
    return PlaylistTrack(
      id: row['id'] as String,
      position: row['position'] as int,
      title: row['title'] as String,
      artist: row['artist'] as String,
      previewUrl: row['preview_url'] as String?,
      artworkUrl: row['artwork_url'] as String?,
      youtubeVideoId: row['youtube_video_id'] as String?,
      deezerTrackId: row['deezer_track_id'] as int?,
    );
  }

  final String id;
  final int position;
  final String title;
  final String artist;

  /// A 30-second Deezer preview URL, signed with a short expiry (~1 hour).
  /// Stale as soon as it's more than an hour old, so it's only ever used as
  /// a last-resort fallback — playback re-fetches a fresh one via
  /// [deezerTrackId] instead. Nullable defensively (the column allows
  /// null), though `playlist_service.dart` only ever writes tracks that
  /// already had one.
  final String? previewUrl;
  final String? artworkUrl;

  /// Resolved lazily (see `youtube_service.dart`) the first time the user
  /// asks for full-song playback on this track, then cached here.
  final String? youtubeVideoId;

  /// Deezer's numeric track id, used to re-fetch a fresh (unexpired)
  /// preview URL at playback time — see `deezer_service.dart`.
  final int? deezerTrackId;

  PlaylistTrack withYoutubeVideoId(String videoId) {
    return PlaylistTrack(
      id: id,
      position: position,
      title: title,
      artist: artist,
      previewUrl: previewUrl,
      artworkUrl: artworkUrl,
      youtubeVideoId: videoId,
      deezerTrackId: deezerTrackId,
    );
  }
}
