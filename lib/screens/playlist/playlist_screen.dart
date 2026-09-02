import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/playlist_track.dart';
import '../../services/youtube_service.dart';
import 'youtube_player_screen.dart';

/// Shows the playlist generated for a journal entry and lets the user play,
/// skip, and explore its tracks via Deezer's 30-second previews
/// (Requirements §3). Reached from the Today screen once an entry (and thus
/// its playlist) exists; showing it alongside a *past* entry is a Phase 4
/// checklist item.
class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key, required this.journalEntryId});

  final String journalEntryId;

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _player = AudioPlayer();

  bool _isLoading = true;
  String? _errorMessage;
  List<PlaylistTrack> _tracks = const [];

  int? _currentIndex;
  bool _isPlaying = false;
  int? _resolvingYoutubeIndex;

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
          .select('id')
          .eq('journal_entry_id', widget.journalEntryId)
          .maybeSingle();

      if (playlist == null) {
        if (!mounted) return;
        setState(() {
          _tracks = const [];
          _isLoading = false;
        });
        return;
      }

      final rows = await Supabase.instance.client
          .from('playlist_tracks')
          .select(
            'id, position, title, artist, preview_url, artwork_url, '
            'youtube_video_id',
          )
          .eq('playlist_id', playlist['id'] as String)
          .order('position');

      if (!mounted) return;
      setState(() {
        _tracks = [
          for (final row in rows) PlaylistTrack.fromRow(row),
        ];
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

  Future<void> _playTrackAt(int index) async {
    final track = _tracks[index];
    final previewUrl = track.previewUrl;
    if (previewUrl == null) return;

    setState(() => _currentIndex = index);
    await _player.play(UrlSource(previewUrl));
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final currentTrack = currentIndex == null ? null : _tracks[currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: SafeArea(
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
                  padding: EdgeInsets.only(
                    bottom: currentTrack == null ? 0 : 88,
                  ),
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
                          if (track.previewUrl != null)
                            Icon(
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
                      onTap: track.previewUrl == null
                          ? null
                          : () => isCurrent
                                ? _togglePlayPause()
                                : _playTrackAt(index),
                    );
                  },
                ),
        ),
      ),
      bottomNavigationBar: currentTrack == null
          ? null
          : _MiniPlayer(
              title: currentTrack.title,
              artist: currentTrack.artist,
              isPlaying: _isPlaying,
              hasPrevious: currentIndex! > 0,
              hasNext: currentIndex < _tracks.length - 1,
              onPlayPause: _togglePlayPause,
              onPrevious: _playPrevious,
              onNext: _playNext,
            ),
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
