import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/journal_events.dart';
import '../../widgets/confirm_delete_dialog.dart';
import '../../widgets/journal_entry_form.dart';
import '../../widgets/log_out_button.dart';

/// Landing tab of the main shell: pick today's mood + intensity, write a
/// journal entry, and save it. If today's entry already exists, its values
/// are loaded into the form and saving updates it in place instead of
/// inserting a second row (the table only allows one entry per user per
/// day).
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _checkTodayEntry();
    journalEntriesChanged.addListener(_checkTodayEntry);
  }

  @override
  void dispose() {
    journalEntriesChanged.removeListener(_checkTodayEntry);
    super.dispose();
  }

  String get _todayDateString {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
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
      journalEntriesChanged.notifyChanged();
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
    }
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
      journalEntriesChanged.notifyChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Deleted today's entry.")));
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
        title: const Text('Today'),
        actions: [
          if (_entryId != null)
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
          const LogOutButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              else ...[
                if (_entryId != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "You've already logged today — feel free to "
                              'update it below.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
    );
  }
}
