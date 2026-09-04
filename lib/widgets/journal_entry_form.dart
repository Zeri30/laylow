import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mood_option.dart';
import '../utils/mood_color.dart';

/// Mood picker (chips + intensity slider) + journal text field + save
/// button, shared by the Today screen (create/update today's entry) and the
/// journal entry detail screen (edit a past entry).
class JournalEntryForm extends StatefulWidget {
  const JournalEntryForm({
    super.key,
    this.initialMood,
    this.initialMoodIntensity = 3,
    this.initialJournalText = '',
    required this.onSave,
    required this.saveLabel,
    required this.successMessage,
    this.onSaved,
  });

  final String? initialMood;
  final int initialMoodIntensity;
  final String initialJournalText;

  /// Performs the actual insert/update; should throw on failure.
  final Future<void> Function(
    String mood,
    int moodIntensity,
    String? journalText,
  )
  onSave;

  final String saveLabel;
  final String successMessage;

  /// Called after a successful save instead of showing [successMessage] —
  /// e.g. to pop the screen back to a list that should refresh.
  final VoidCallback? onSaved;

  @override
  State<JournalEntryForm> createState() => _JournalEntryFormState();
}

class _JournalEntryFormState extends State<JournalEntryForm> {
  late String? _selectedMood = widget.initialMood;
  late int _moodIntensity = widget.initialMoodIntensity;
  late final _journalController = TextEditingController(
    text: widget.initialJournalText,
  );

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(covariant JournalEntryForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent passes new initial values after a save/delete changes which
    // entry (if any) this form represents — e.g. deleting today's entry
    // resets these to blank. Re-sync so stale text doesn't linger.
    if (oldWidget.initialMood != widget.initialMood ||
        oldWidget.initialMoodIntensity != widget.initialMoodIntensity ||
        oldWidget.initialJournalText != widget.initialJournalText) {
      _selectedMood = widget.initialMood;
      _moodIntensity = widget.initialMoodIntensity;
      _journalController.text = widget.initialJournalText;
    }
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final mood = _selectedMood;
    if (mood == null) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final journalText = _journalController.text.trim();
      await widget.onSave(
        mood,
        _moodIntensity,
        journalText.isEmpty ? null : journalText,
      );

      if (!mounted) return;
      if (widget.onSaved != null) {
        widget.onSaved!();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.successMessage)));
      }
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Something went wrong. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _selectedMood != null && !_isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How are you feeling?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final mood in moodOptions)
              _MoodTile(
                mood: mood,
                selected: _selectedMood == mood.id,
                onTap: () => setState(
                  () =>
                      _selectedMood = _selectedMood == mood.id ? null : mood.id,
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Text('Intensity', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            _IntensityBadge(value: _moodIntensity),
          ],
        ),
        Row(
          children: [
            const Text('Mild'),
            Expanded(
              child: Slider(
                value: _moodIntensity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_moodIntensity',
                onChanged: _selectedMood == null
                    ? null
                    : (value) => setState(() => _moodIntensity = value.round()),
              ),
            ),
            const Text('Intense'),
          ],
        ),
        const SizedBox(height: 24),
        Text('Journal entry', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _journalController,
          minLines: 6,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Write about your day... (optional)',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: canSave ? _handleSave : null,
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.saveLabel),
        ),
      ],
    );
  }
}

/// A single tappable mood option, styled as a soft rounded tile rather than
/// a flat [ChoiceChip] — selection is shown with that mood's own accent
/// color ([moodColorFor]) instead of one generic selected color, so each
/// mood reads as visually distinct as well as textually.
class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final MoodOption mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = moodColorFor(mood.id);

    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      scale: selected ? 1.06 : 1.0,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.16)
            : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? accent : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mood.icon,
                  size: 18,
                  color: selected ? accent : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? accent : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill showing the current intensity value (1-5), mirroring the
/// slider so the number is legible without reading the thumb's tooltip.
class _IntensityBadge extends StatelessWidget {
  const _IntensityBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$value/5',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
