import 'package:flutter/material.dart';

import '../models/mood_option.dart';
import '../utils/mood_color.dart';

/// A connected 3-step checklist — mood, journal, playlist — summarizing
/// today's entry, shown once it exists (replacing a plain "already logged"
/// banner). Each step reflects real state rather than a fake gated wizard:
/// the journal step is only "done" if text was actually written (it's
/// optional on the form), and tapping the playlist step opens it.
class TodayFlowTimeline extends StatelessWidget {
  const TodayFlowTimeline({
    super.key,
    required this.mood,
    required this.moodIntensity,
    required this.journalText,
    required this.onOpenPlaylist,
  });

  final String mood;
  final int moodIntensity;
  final String journalText;
  final VoidCallback onOpenPlaylist;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final option = moodOptionFor(mood);
    final accent = moodColorFor(mood);
    final hasJournalText = journalText.trim().isNotEmpty;
    final doneCount = 2 + (hasJournalText ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              "Today's flow",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$doneCount/3',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Stack(
          children: [
            Positioned(
              left: 19,
              top: 22,
              bottom: 22,
              child: Container(width: 2, color: scheme.outlineVariant),
            ),
            Column(
              children: [
                _FlowStep(
                  icon: option.icon,
                  accent: accent,
                  done: true,
                  title: 'Mood logged',
                  subtitle: '${option.label}, intensity $moodIntensity/5',
                ),
                const SizedBox(height: 10),
                _FlowStep(
                  icon: Icons.edit_note_rounded,
                  accent: scheme.primary,
                  done: hasJournalText,
                  title: 'Journal written',
                  subtitle: hasJournalText
                      ? '"$journalText"'
                      : 'Optional — add a note below',
                ),
                const SizedBox(height: 10),
                _FlowStep(
                  icon: Icons.queue_music_rounded,
                  accent: scheme.primary,
                  done: true,
                  title: 'Playlist ready',
                  subtitle: 'Music picked for how you feel',
                  onTap: onOpenPlaylist,
                  showChevron: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.icon,
    required this.accent,
    required this.done,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = false,
  });

  final IconData icon;
  final Color accent;
  final bool done;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? accent : scheme.surface,
            border: done
                ? null
                : Border.all(color: scheme.outlineVariant, width: 1.5),
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
              : Icon(icon, color: scheme.onSurfaceVariant, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Material(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: accent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showChevron)
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurfaceVariant,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
