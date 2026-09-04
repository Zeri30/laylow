// Computes the journaling-streak stats shown on the Today screen's hero
// card: current streak, best streak ever, total entries, and entries in
// the last 7 days — all derived from `journal_entries.entry_date`.

import 'package:supabase_flutter/supabase_flutter.dart';

class StreakStats {
  const StreakStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalEntries,
    required this.entriesThisWeek,
  });

  final int currentStreak;
  final int bestStreak;
  final int totalEntries;
  final int entriesThisWeek;

  static const zero = StreakStats(
    currentStreak: 0,
    bestStreak: 0,
    totalEntries: 0,
    entriesThisWeek: 0,
  );
}

/// Pure so it's testable without a live Supabase call — [entryDates] need
/// not be sorted or deduplicated. [today] defaults to [DateTime.now] and
/// exists so tests can pin "today".
StreakStats computeStreakStats(List<DateTime> entryDates, {DateTime? today}) {
  final now = today ?? DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);

  final days = entryDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
  if (days.isEmpty) return StreakStats.zero;

  // A streak still counts as "current" if today hasn't been logged yet but
  // yesterday was — the user still has today to keep it alive.
  var currentStreak = 0;
  var cursor = days.contains(todayDate)
      ? todayDate
      : todayDate.subtract(const Duration(days: 1));
  while (days.contains(cursor)) {
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final sortedDays = days.toList()..sort();
  var bestStreak = 0;
  var run = 0;
  DateTime? previous;
  for (final day in sortedDays) {
    run = (previous != null && day.difference(previous).inDays == 1)
        ? run + 1
        : 1;
    if (run > bestStreak) bestStreak = run;
    previous = day;
  }

  final weekStart = todayDate.subtract(const Duration(days: 6));
  final entriesThisWeek = days
      .where((d) => !d.isBefore(weekStart) && !d.isAfter(todayDate))
      .length;

  return StreakStats(
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    totalEntries: days.length,
    entriesThisWeek: entriesThisWeek,
  );
}

/// Fetches every entry date for the signed-in user and reduces it to
/// [StreakStats]. Returns [StreakStats.zero] when signed out.
Future<StreakStats> fetchStreakStats() async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return StreakStats.zero;

  final rows = await Supabase.instance.client
      .from('journal_entries')
      .select('entry_date')
      .eq('user_id', userId);

  final dates = [
    for (final row in rows as List) DateTime.parse(row['entry_date'] as String),
  ];

  return computeStreakStats(dates);
}
