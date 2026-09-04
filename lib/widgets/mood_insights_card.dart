import 'package:flutter/material.dart';

import '../models/mood_option.dart';
import '../utils/mood_color.dart';
import '../utils/mood_insights.dart';

/// A "your patterns" summary card: which mood shows up most, how intense
/// entries tend to be, and whether the last week has trended more or less
/// intense than usual — a simple overview of recorded moods/ratings that
/// helps the user notice patterns over time (Requirements §6), rather than
/// only ever seeing entries one at a time.
class MoodInsightsCard extends StatelessWidget {
  const MoodInsightsCard({super.key, required this.insights});

  final MoodInsights insights;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (insights.totalEntries == 0) return const SizedBox.shrink();

    final topMood = moodOptionFor(insights.topMood!);
    final topMoodColor = moodColorFor(insights.topMood!);
    final maxCount = insights.moodCounts.values.first;
    final trend = _trendFor(insights);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your patterns', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              "You've felt ${topMood.label.toLowerCase()} most often — "
              '${insights.moodCounts[insights.topMood]} of '
              '${insights.totalEntries} ${insights.totalEntries == 1 ? 'entry' : 'entries'}.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 14),
            for (final moodId in insights.moodCounts.keys.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MoodBar(
                  mood: moodOptionFor(moodId),
                  color: moodColorFor(moodId),
                  count: insights.moodCounts[moodId]!,
                  fraction: insights.moodCounts[moodId]! / maxCount,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Avg. intensity',
                    value: insights.averageIntensity.toStringAsFixed(1),
                    color: topMoodColor,
                  ),
                ),
                if (trend != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Last 7 days',
                      value: trend.label,
                      icon: trend.icon,
                      color: trend.color(scheme),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Trend {
  const _Trend(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color Function(ColorScheme) color;
}

/// Compares the trailing-7-day average intensity against the all-time
/// average, with a half-point deadband so ordinary noise doesn't flip the
/// indicator back and forth.
_Trend? _trendFor(MoodInsights insights) {
  final recent = insights.recentAverageIntensity;
  if (recent == null) return null;

  final delta = recent - insights.averageIntensity;
  if (delta > 0.5) {
    return _Trend(
      '${recent.toStringAsFixed(1)} ↑',
      Icons.trending_up_rounded,
      (scheme) => scheme.primary,
    );
  }
  if (delta < -0.5) {
    return _Trend(
      '${recent.toStringAsFixed(1)} ↓',
      Icons.trending_down_rounded,
      (scheme) => scheme.secondary,
    );
  }
  return _Trend(
    '${recent.toStringAsFixed(1)} →',
    Icons.trending_flat_rounded,
    (scheme) => scheme.onSurfaceVariant,
  );
}

class _MoodBar extends StatelessWidget {
  const _MoodBar({
    required this.mood,
    required this.color,
    required this.count,
    required this.fraction,
  });

  final MoodOption mood;
  final Color color;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(mood.icon, size: 15, color: color),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            mood.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 16,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
