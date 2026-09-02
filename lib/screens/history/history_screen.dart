import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/journal_entry_summary.dart';
import '../../models/mood_option.dart';
import '../../utils/date_format.dart';
import '../../utils/journal_events.dart';
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
            .map((row) => JournalEntrySummary.fromRow(row as Map<String, dynamic>))
            .toList();
      });
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(
        () => _errorMessage =
            "Couldn't load your journal entries. Please retry.",
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
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final mood = moodOptionFor(entry.mood);
        final hasJournalText = entry.journalText?.isNotEmpty ?? false;

        return Card(
          child: ListTile(
            leading: Text(mood.emoji, style: const TextStyle(fontSize: 28)),
            title: Text(formatFriendlyDate(entry.entryDate)),
            subtitle: Text(
              hasJournalText
                  ? '${mood.label} · Intensity ${entry.moodIntensity}/5\n'
                        '${entry.journalText}'
                  : '${mood.label} · Intensity ${entry.moodIntensity}/5',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: hasJournalText,
            onTap: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => JournalEntryDetailScreen(entry: entry),
                ),
              );
              if (updated == true) await _loadEntries();
            },
          ),
        );
      },
    );
  }
}
