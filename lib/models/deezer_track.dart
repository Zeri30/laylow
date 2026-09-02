/// A single track result from the Deezer search API.
class DeezerTrack {
  const DeezerTrack({
    required this.deezerId,
    required this.title,
    required this.artist,
    required this.previewUrl,
    required this.albumCoverUrl,
  });

  factory DeezerTrack.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    final album = json['album'] as Map<String, dynamic>?;
    return DeezerTrack(
      deezerId: json['id'] as int,
      title: json['title'] as String,
      artist: artist?['name'] as String? ?? 'Unknown artist',
      previewUrl: json['preview'] as String,
      albumCoverUrl: album?['cover_medium'] as String?,
    );
  }

  /// Deezer's own track id — stable, used to de-duplicate results and to
  /// key `playlist_tracks` rows.
  final int deezerId;
  final String title;
  final String artist;

  /// 30-second MP3 preview, no auth needed (see ARCHITECTURE.md).
  final String previewUrl;
  final String? albumCoverUrl;
}
