import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/journal_entry_summary.dart';
import '../../utils/date_format.dart';
import '../../utils/journal_events.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/journal_entry_form.dart';
import '../playlist/playlist_screen.dart';

/// View, edit, or delete a single past journal entry, alongside the
/// playlist generated for it. The "Journal" and "Playlist" tabs put both
/// halves of that day's reflection on one screen — its mood and the music
/// picked for that mood — rather than treating them as separate features
/// (Requirements §4).
class JournalEntryDetailScreen extends StatefulWidget {
  const JournalEntryDetailScreen({super.key, required this.entry});

  final JournalEntrySummary entry;

  @override
  State<JournalEntryDetailScreen> createState() =>
      _JournalEntryDetailScreenState();
}

class _JournalEntryDetailScreenState extends State<JournalEntryDetailScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this);
  bool _isDeleting = false;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry(
    String mood,
    int moodIntensity,
    String? journalText,
  ) async {
    await Supabase.instance.client
        .from('journal_entries')
        .update({
          'mood': mood,
          'mood_intensity': moodIntensity,
          'journal_text': journalText,
        })
        .eq('id', widget.entry.id);
    journalEntriesChanged.notifyChanged();
  }

  Future<void> _delete() async {
    if (!await confirmDeleteEntry(context)) return;

    setState(() => _isDeleting = true);

    try {
      await Supabase.instance.client
          .from('journal_entries')
          .delete()
          .eq('id', widget.entry.id);

      journalEntriesChanged.notifyChanged();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formatFriendlyDate(widget.entry.entryDate)),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            tooltip: 'Delete entry',
            onPressed: _isDeleting ? null : _delete,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'Playlist'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: JournalEntryForm(
                initialMood: widget.entry.mood,
                initialMoodIntensity: widget.entry.moodIntensity,
                initialJournalText: widget.entry.journalText ?? '',
                onSave: _saveEntry,
                saveLabel: 'Update',
                successMessage: 'Entry updated.',
                // Pop back to History with a signal to refresh, rather than
                // showing a snackbar on a screen the user is about to leave.
                onSaved: () => Navigator.of(context).pop(true),
              ),
            ),
            PlaylistView(journalEntryId: widget.entry.id),
          ],
        ),
      ),
    );
  }
}
