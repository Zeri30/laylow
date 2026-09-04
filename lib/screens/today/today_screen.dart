import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/playlist_service.dart';
import '../../services/streak_service.dart';
import '../../utils/date_format.dart';
import '../../utils/journal_events.dart';
import '../../utils/today_entry_status.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/gradient_blob_backdrop.dart';
import '../../widgets/journal_entry_form.dart';
import '../../widgets/log_out_button.dart';
import '../../widgets/streak_hero_card.dart';
import '../../widgets/today_flow_timeline.dart';
import '../playlist/playlist_screen.dart';

/// Landing tab of the main shell: a streak/stats hero, a summary of today's
/// entry once it exists, and the mood/intensity/journal form itself. If
/// today's entry already exists, its values are loaded into the form and
/// saving updates it in place instead of inserting a second row (the table
/// only allows one entry per user per day).
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, this.onViewHistory});

  /// Switches the main shell to the History tab — wired by [MainShell] so
  /// the hero card's "View history" action can jump straight there.
  final VoidCallback? onViewHistory;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  bool _isCheckingTodayEntry = true;
  String? _entryId;
  String? _initialMood;
  int _initialMoodIntensity = 3;
  String _initialJournalText = '';
  String? _checkErrorMessage;
  bool _isDeleting = false;
  StreakStats _streakStats = StreakStats.zero;

  @override
  void initState() {
    super.initState();
    _checkTodayEntry();
    _loadStreakStats();
    journalEntriesChanged.addListener(_checkTodayEntry);
    journalEntriesChanged.addListener(_loadStreakStats);
  }

  @override
  void dispose() {
    journalEntriesChanged.removeListener(_checkTodayEntry);
    journalEntriesChanged.removeListener(_loadStreakStats);
    super.dispose();
  }

  String get _todayDateString {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStreakStats() async {
    try {
      final stats = await fetchStreakStats();
      if (mounted) setState(() => _streakStats = stats);
    } catch (_) {
      // Non-critical — the hero card just keeps showing the last known
      // stats (or zero on first load) rather than surfacing an error.
    }
  }

  Future<void> _checkTodayEntry() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final row = await Supabase.instance.client
          .from('journal_entries')
          .select('id, mood, mood_intensity, journal_text')
          .eq('user_id', userId)
          .eq('entry_date', _todayDateString)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        if (row != null) {
          _entryId = row['id'] as String;
          _initialMood = row['mood'] as String;
          _initialMoodIntensity = row['mood_intensity'] as int;
          _initialJournalText = row['journal_text'] as String? ?? '';
        } else {
          _entryId = null;
          _initialMood = null;
          _initialMoodIntensity = 3;
          _initialJournalText = '';
        }
      });
      todayEntryLogged.value = _entryId != null;
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _checkErrorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _checkErrorMessage =
              "Couldn't check today's entry. Please retry.",
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingTodayEntry = false);
    }
  }

  Future<void> _saveEntry(
    String mood,
    int moodIntensity,
    String? journalText,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final entryId = _entryId;
    if (entryId == null) {
      final inserted = await Supabase.instance.client
          .from('journal_entries')
          .insert({
            'user_id': userId,
            'entry_date': _todayDateString,
            'mood': mood,
            'mood_intensity': moodIntensity,
            'journal_text': journalText,
          })
          .select('id')
          .single();

      if (!mounted) return;
      setState(() {
        _entryId = inserted['id'] as String;
        _initialMood = mood;
        _initialMoodIntensity = moodIntensity;
        _initialJournalText = journalText ?? '';
      });
      todayEntryLogged.value = true;
      journalEntriesChanged.notifyChanged();
      _generatePlaylist(inserted['id'] as String, mood, moodIntensity);
    } else {
      await Supabase.instance.client
          .from('journal_entries')
          .update({
            'mood': mood,
            'mood_intensity': moodIntensity,
            'journal_text': journalText,
          })
          .eq('id', entryId);

      if (!mounted) return;
      setState(() {
        _initialMood = mood;
        _initialMoodIntensity = moodIntensity;
        _initialJournalText = journalText ?? '';
      });
      journalEntriesChanged.notifyChanged();
      _generatePlaylist(entryId, mood, moodIntensity);
    }
  }

  /// Fire-and-forget: the journal entry is already saved by this point, so a
  /// Deezer/network hiccup here shouldn't block that save or surface as a
  /// save error. Errors are swallowed until the playlist screen (a later
  /// checklist item) has somewhere to show them.
  void _generatePlaylist(String entryId, String mood, int moodIntensity) {
    generatePlaylistForJournalEntry(
      journalEntryId: entryId,
      mood: mood,
      moodIntensity: moodIntensity,
    ).catchError((Object error) {
      debugPrint('Playlist generation failed for entry $entryId: $error');
      return '';
    });
  }

  Future<void> _deleteEntry() async {
    final entryId = _entryId;
    if (entryId == null) return;
    if (!await confirmDeleteEntry(context)) return;

    setState(() => _isDeleting = true);

    try {
      await Supabase.instance.client
          .from('journal_entries')
          .delete()
          .eq('id', entryId);

      if (!mounted) return;
      setState(() {
        _entryId = null;
        _initialMood = null;
        _initialMoodIntensity = 3;
        _initialJournalText = '';
      });
      todayEntryLogged.value = false;
      journalEntriesChanged.notifyChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Deleted today's entry.")));
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't delete this entry. Please retry."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Still up?';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Winding down?';
  }

  void _openPlaylist() {
    final entryId = _entryId;
    if (entryId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistScreen(journalEntryId: entryId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          if (_entryId != null) ...[
            IconButton(
              icon: const Icon(Icons.queue_music),
              tooltip: 'View playlist',
              onPressed: _openPlaylist,
            ),
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Delete entry',
              onPressed: _isDeleting ? null : _deleteEntry,
            ),
          ],
          const LogOutButton(),
        ],
      ),
      body: GradientBlobBackdrop(
        height: 200,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, kToolbarHeight + 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting, style: textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          Text(
                            formatFriendlyDate(DateTime.now()),
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 7, 13, 7),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 16,
                            color: scheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_streakStats.currentStreak}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                StreakHeroCard(
                  stats: _streakStats,
                  onViewHistory: widget.onViewHistory ?? () {},
                ),
                const SizedBox(height: 24),
                if (_isCheckingTodayEntry)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(),
                  )
                else if (_checkErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _checkErrorMessage!,
                      style: TextStyle(color: scheme.error),
                    ),
                  )
                else ...[
                  if (_entryId != null) ...[
                    TodayFlowTimeline(
                      mood: _initialMood!,
                      moodIntensity: _initialMoodIntensity,
                      journalText: _initialJournalText,
                      onOpenPlaylist: _openPlaylist,
                    ),
                    const SizedBox(height: 28),
                  ],
                  JournalEntryForm(
                    initialMood: _initialMood,
                    initialMoodIntensity: _initialMoodIntensity,
                    initialJournalText: _initialJournalText,
                    onSave: _saveEntry,
                    saveLabel: _entryId == null ? 'Save' : 'Update',
                    successMessage: _entryId == null
                        ? "Saved today's entry."
                        : "Updated today's entry.",
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
