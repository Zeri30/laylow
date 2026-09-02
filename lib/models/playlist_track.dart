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
    );
  }

  final String id;
  final int position;
  final String title;
  final String artist;

  /// 30-second Deezer preview. Nullable defensively (the column allows
  /// null), though `playlist_service.dart` only ever writes tracks that
  /// already had one.
  final String? previewUrl;
  final String? artworkUrl;

  /// Resolved lazily (see `youtube_service.dart`) the first time the user
  /// asks for full-song playback on this track, then cached here.
  final String? youtubeVideoId;

  PlaylistTrack withYoutubeVideoId(String videoId) {
    return PlaylistTrack(
      id: id,
      position: position,
      title: title,
      artist: artist,
      previewUrl: previewUrl,
      artworkUrl: artworkUrl,
      youtubeVideoId: videoId,
    );
  }
}
