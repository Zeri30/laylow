// Reduces a list of journal entries into a simple "your patterns" overview:
// which mood shows up most, how intense entries tend to be, and how the
// last 7 days compare to the user's overall average — the trend signal
// that helps someone notice "I've been more anxious than usual lately"
// (Requirements §6).

import '../models/journal_entry_summary.dart';

class MoodInsights {
  const MoodInsights({
    required this.moodCounts,
    required this.totalEntries,
    required this.topMood,
    required this.averageIntensity,
    required this.recentAverageIntensity,
  });

  /// Entry count per mood id, present only for moods that were actually
  /// recorded — ordered highest-count first.
  final Map<String, int> moodCounts;
  final int totalEntries;

  /// The most-recorded mood, or null when there are no entries.
  final String? topMood;

  /// Average `mood_intensity` across every entry, or 0 when there are none.
  final double averageIntensity;

  /// Average `mood_intensity` across the trailing 7 days (by entry date),
  /// or null when none of the entries fall in that window.
  final double? recentAverageIntensity;

  static const empty = MoodInsights(
    moodCounts: {},
    totalEntries: 0,
    topMood: null,
    averageIntensity: 0,
    recentAverageIntensity: null,
  );
}

/// Pure so it's testable without a live Supabase call. [today] defaults to
/// [DateTime.now] and exists so tests can pin "today".
MoodInsights computeMoodInsights(
  List<JournalEntrySummary> entries, {
  DateTime? today,
}) {
  if (entries.isEmpty) return MoodInsights.empty;

  final counts = <String, int>{};
  var intensitySum = 0;
  for (final entry in entries) {
    counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    intensitySum += entry.moodIntensity;
  }

  final sortedMoods = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  final now = today ?? DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);
  final weekStart = todayDate.subtract(const Duration(days: 6));
  final recent = entries.where((e) {
    final day = DateTime(e.entryDate.year, e.entryDate.month, e.entryDate.day);
    return !day.isBefore(weekStart) && !day.isAfter(todayDate);
  });
  final recentCount = recent.length;
  final recentSum = recent.fold<int>(0, (sum, e) => sum + e.moodIntensity);

  return MoodInsights(
    moodCounts: {for (final mood in sortedMoods) mood: counts[mood]!},
    totalEntries: entries.length,
    topMood: sortedMoods.first,
    averageIntensity: intensitySum / entries.length,
    recentAverageIntensity: recentCount == 0 ? null : recentSum / recentCount,
  );
}
