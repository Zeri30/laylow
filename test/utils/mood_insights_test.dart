import 'package:flutter_test/flutter_test.dart';
import 'package:laylow/models/journal_entry_summary.dart';
import 'package:laylow/utils/mood_insights.dart';

void main() {
  final today = DateTime(2026, 9, 4);

  JournalEntrySummary entry({
    required DateTime date,
    required String mood,
    required int intensity,
  }) {
    return JournalEntrySummary(
      id: '${date.toIso8601String()}-$mood',
      entryDate: date,
      mood: mood,
      moodIntensity: intensity,
      journalText: null,
    );
  }

  group('computeMoodInsights', () {
    test('empty entries yields the empty insights', () {
      final insights = computeMoodInsights([], today: today);
      expect(insights.totalEntries, 0);
      expect(insights.topMood, isNull);
      expect(insights.averageIntensity, 0);
      expect(insights.recentAverageIntensity, isNull);
    });

    test('counts entries per mood and ranks the most frequent first', () {
      final insights = computeMoodInsights([
        entry(date: today, mood: 'happy', intensity: 3),
        entry(date: today.subtract(const Duration(days: 1)), mood: 'happy', intensity: 4),
        entry(date: today.subtract(const Duration(days: 2)), mood: 'sad', intensity: 2),
      ], today: today);

      expect(insights.totalEntries, 3);
      expect(insights.topMood, 'happy');
      expect(insights.moodCounts, {'happy': 2, 'sad': 1});
      expect(insights.moodCounts.keys.first, 'happy');
    });

    test('averageIntensity is the mean across all entries', () {
      final insights = computeMoodInsights([
        entry(date: today, mood: 'happy', intensity: 2),
        entry(date: today, mood: 'sad', intensity: 4),
      ], today: today);

      expect(insights.averageIntensity, 3);
    });

    test('recentAverageIntensity only covers the trailing 7 days', () {
      final insights = computeMoodInsights([
        entry(date: today, mood: 'happy', intensity: 5), // in window
        entry(
          date: today.subtract(const Duration(days: 6)),
          mood: 'happy',
          intensity: 3,
        ), // in window
        entry(
          date: today.subtract(const Duration(days: 7)),
          mood: 'sad',
          intensity: 1,
        ), // just outside
      ], today: today);

      expect(insights.recentAverageIntensity, 4);
      expect(insights.averageIntensity, 3);
    });

    test('recentAverageIntensity is null when nothing falls in the window', () {
      final insights = computeMoodInsights([
        entry(date: today.subtract(const Duration(days: 30)), mood: 'sad', intensity: 1),
      ], today: today);

      expect(insights.recentAverageIntensity, isNull);
    });
  });
}
