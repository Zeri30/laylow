import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/mood_option.dart';
import '../../models/playlist_track.dart';
import '../../services/deezer_service.dart';
import '../../services/youtube_service.dart';
import 'youtube_player_screen.dart';

/// Full-screen wrapper around [PlaylistView] — used when the playlist is its
/// own destination, e.g. the queue-music button on the Today screen.
class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key, required this.journalEntryId});

  final String journalEntryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: SafeArea(child: PlaylistView(journalEntryId: journalEntryId)),
    );
  }
}

/// Shows the playlist generated for a journal entry and lets the user play,
/// skip, and explore its tracks via Deezer's 30-second previews
/// (Requirements §3). Scaffold-free so it can be embedded either as its own
/// screen ([PlaylistScreen], from Today) or as a tab alongside the journal
/// entry itself (`JournalEntryDetailScreen`, Requirements §4) — the mood
/// header above the track list is what ties "this playlist" back to "this
/// feeling" for that reflection view.
class PlaylistView extends StatefulWidget {
  const PlaylistView({super.key, required this.journalEntryId});

  final String journalEntryId;

  @override
  State<PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<PlaylistView> {
  final _player = AudioPlayer();

  bool _isLoading = true;
  String? _errorMessage;
  List<PlaylistTrack> _tracks = const [];

  // Snapshotted on the `playlists` row itself (not read live from the
  // journal entry), so this always reflects the mood this specific playlist
  // was actually generated for — see docs/SCHEMA.md.
  String? _playlistMood;
  int? _playlistMoodIntensity;

  int? _currentIndex;
  bool _isPlaying = false;
  int? _resolvingYoutubeIndex;
  int? _resolvingPreviewIndex;

  @override
  void initState() {
    super.initState();
    _load();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPlayerComplete.listen((_) => _playNext());
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final playlist = await Supabase.instance.client
          .from('playlists')
          .select('id, mood, mood_intensity')
          .eq('journal_entry_id', widget.journalEntryId)
          .maybeSingle();

      if (playlist == null) {
        if (!mounted) return;
        setState(() {
          _tracks = const [];
          _playlistMood = null;
          _playlistMoodIntensity = null;
          _isLoading = false;
        });
        return;
      }

      final rows = await Supabase.instance.client
          .from('playlist_tracks')
          .select(
            'id, position, title, artist, preview_url, artwork_url, '
            'youtube_video_id, deezer_track_id',
          )
          .eq('playlist_id', playlist['id'] as String)
          .order('position');

      if (!mounted) return;
      setState(() {
        _tracks = [
          for (final row in rows) PlaylistTrack.fromRow(row),
        ];
        _playlistMood = playlist['mood'] as String;
        _playlistMoodIntensity = playlist['mood_intensity'] as int;
      });
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = "Couldn't load this playlist. Please retry.",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Plays the track at [index]. Deezer signs preview URLs with a short
  /// (~1 hour) expiry, so the `preview_url` stored on the track at playlist
  /// generation time is often already stale — this re-fetches a fresh one
  /// by the track's Deezer id first, falling back to the stored URL only
  /// if that lookup fails (e.g. no network).
  Future<void> _playTrackAt(int index) async {
    final track = _tracks[index];
    if (track.previewUrl == null && track.deezerTrackId == null) return;

    setState(() {
      _currentIndex = index;
      _resolvingPreviewIndex = index;
    });

    String? urlToPlay;
    final deezerTrackId = track.deezerTrackId;
    if (deezerTrackId != null) {
      try {
        urlToPlay = await fetchFreshPreviewUrl(deezerTrackId);
      } catch (_) {
        urlToPlay = null;
      }
    }
    urlToPlay ??= track.previewUrl;

    if (mounted) setState(() => _resolvingPreviewIndex = null);
    if (!mounted) return;

    if (urlToPlay == null) {
      setState(() => _currentIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load a preview for this track."),
        ),
      );
      return;
    }

    try {
      await _player.play(UrlSource(urlToPlay));
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't play this track. Please retry.")),
      );
    }
  }

  Future<void> _togglePlayPause() async {
    if (_currentIndex == null) {
      if (_tracks.isNotEmpty) await _playTrackAt(0);
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> _playNext() async {
    final current = _currentIndex;
    if (current == null) return;
    final next = current + 1;
    if (next < _tracks.length) {
      await _playTrackAt(next);
    } else {
      await _player.stop();
      if (mounted) setState(() => _currentIndex = null);
    }
  }

  Future<void> _playPrevious() async {
    final current = _currentIndex;
    if (current == null || current == 0) return;
    await _playTrackAt(current - 1);
  }

  /// Opens full-song playback for the track at [index]. Resolves and caches
  /// its YouTube video id on first use (see `youtube_service.dart`), so a
  /// later look at this same track skips straight to the player.
  Future<void> _openFullSong(int index) async {
    final track = _tracks[index];
    var videoId = track.youtubeVideoId;

    if (videoId == null) {
      setState(() => _resolvingYoutubeIndex = index);
      try {
        videoId = await findYoutubeVideoId(track.title, track.artist);
      } catch (_) {
        videoId = null;
      }
      if (mounted) setState(() => _resolvingYoutubeIndex = null);

      if (videoId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't find a full song for this track."),
            ),
          );
        }
        return;
      }

      await Supabase.instance.client
          .from('playlist_tracks')
          .update({'youtube_video_id': videoId})
          .eq('id', track.id);

      if (!mounted) return;
      setState(() => _tracks[index] = track.withYoutubeVideoId(videoId!));
    }

    if (_currentIndex == index && _isPlaying) await _player.pause();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YoutubePlayerScreen(
          videoId: videoId!,
          title: track.title,
          artist: track.artist,
        ),
      ),
    );
  }

  Widget _buildMoodHeader(BuildContext context) {
    final mood = _playlistMood;
    final intensity = _playlistMoodIntensity;
    if (mood == null || intensity == null) return const SizedBox.shrink();

    final option = moodOptionFor(mood);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(option.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Picked for feeling ${option.label.toLowerCase()} '
              '(intensity $intensity/5)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final currentTrack = currentIndex == null ? null : _tracks[currentIndex];
    final hasContent = !_isLoading && _errorMessage == null && _tracks.isNotEmpty;

    return Column(
      children: [
        if (hasContent) _buildMoodHeader(context),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _CenteredMessage(
                    message: _errorMessage!,
                    color: Theme.of(context).colorScheme.error,
                  )
                : _tracks.isEmpty
                ? const _CenteredMessage(
                    message:
                        "This entry's playlist isn't ready yet — pull to "
                        'refresh, or check back in a moment.',
                  )
                : ListView.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      final isCurrent = index == currentIndex;
                      return ListTile(
                        leading: track.artworkUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  track.artworkUrl!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.music_note),
                        title: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: isCurrent,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (track.previewUrl != null ||
                                track.deezerTrackId != null)
                              _resolvingPreviewIndex == index
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      isCurrent && _isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                    ),
                            IconButton(
                              icon: _resolvingYoutubeIndex == index
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.smart_display_outlined),
                              tooltip: 'Play full song',
                              onPressed: _resolvingYoutubeIndex != null
                                  ? null
                                  : () => _openFullSong(index),
                            ),
                          ],
                        ),
                        onTap:
                            (track.previewUrl == null &&
                                    track.deezerTrackId == null) ||
                                _resolvingPreviewIndex != null
                            ? null
                            : () => isCurrent
                                  ? _togglePlayPause()
                                  : _playTrackAt(index),
                      );
                    },
                  ),
          ),
        ),
        if (currentTrack != null)
          _MiniPlayer(
            title: currentTrack.title,
            artist: currentTrack.artist,
            isPlaying: _isPlaying,
            hasPrevious: currentIndex! > 0,
            hasNext: currentIndex < _tracks.length - 1,
            onPlayPause: _togglePlayPause,
            onPrevious: _playPrevious,
            onNext: _playNext,
          ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, this.color});

  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer({
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String artist;
  final bool isPlaying;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: hasPrevious ? onPrevious : null,
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 36,
                onPressed: onPlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: hasNext ? onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
