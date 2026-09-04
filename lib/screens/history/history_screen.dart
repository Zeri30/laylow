import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/journal_entry_summary.dart';
import '../../models/mood_option.dart';
import '../../utils/date_format.dart';
import '../../utils/journal_events.dart';
import '../../utils/mood_color.dart';
import '../../widgets/gradient_icon_button.dart';
import '../../widgets/intensity_meter.dart';
import '../../widgets/log_out_button.dart';
import 'journal_entry_detail_screen.dart';

/// Browse-past-entries tab of the main shell: a reverse-chronological list
/// of journal entries. Deleting an entry and richer mood-history views
/// (calendar, trends) are later checklist items.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<JournalEntrySummary> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
    journalEntriesChanged.addListener(_loadEntries);
  }

  @override
  void dispose() {
    journalEntriesChanged.removeListener(_loadEntries);
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rows = await Supabase.instance.client
          .from('journal_entries')
          .select('id, entry_date, mood, mood_intensity, journal_text')
          .eq('user_id', userId)
          .order('entry_date', ascending: false);

      if (!mounted) return;
      setState(() {
        _entries = (rows as List)
            .map(
              (row) => JournalEntrySummary.fromRow(row as Map<String, dynamic>),
            )
            .toList();
      });
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () =>
            _errorMessage = "Couldn't load your journal entries. Please retry.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: const [LogOutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    if (_entries.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "No journal entries yet. Log today's mood on the Today tab "
              'to get started.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = _entries[index];

        Future<void> openDetail(int initialTabIndex) async {
          final updated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => JournalEntryDetailScreen(
                entry: entry,
                initialTabIndex: initialTabIndex,
              ),
            ),
          );
          if (updated == true) await _loadEntries();
        }

        return _HistoryEntryCard(
          entry: entry,
          onTap: () => openDetail(0),
          onOpenPlaylist: () => openDetail(1),
        );
      },
    );
  }
}

/// A journal entry row styled as a card with a mood-colored icon badge,
/// rather than a plain [ListTile] — the badge color ([moodColorFor]) gives
/// a scannable visual cue for mood before reading any text, matching the
/// same accent used on the Today and playlist mood indicators.
class _HistoryEntryCard extends StatelessWidget {
  const _HistoryEntryCard({
    required this.entry,
    required this.onTap,
    required this.onOpenPlaylist,
  });

  final JournalEntrySummary entry;
  final VoidCallback onTap;

  /// Jumps straight to this entry's Playlist tab — a direct path from
  /// History to its music, rather than opening on Journal every time.
  final VoidCallback onOpenPlaylist;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mood = moodOptionFor(entry.mood);
    final accent = moodColorFor(entry.mood);
    final hasJournalText = entry.journalText?.isNotEmpty ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(mood.icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatFriendlyDate(entry.entryDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          mood.label,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IntensityMeter(
                          value: entry.moodIntensity,
                          color: accent,
                        ),
                      ],
                    ),
                    if (hasJournalText) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.journalText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GradientIconButton(
                icon: Icons.queue_music_rounded,
                iconSize: 20,
                padding: const EdgeInsets.all(8),
                tooltip: "Play this entry's music",
                onPressed: onOpenPlaylist,
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
