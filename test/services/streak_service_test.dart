import 'package:flutter_test/flutter_test.dart';
import 'package:laylow/services/streak_service.dart';

void main() {
  final today = DateTime(2026, 9, 4);

  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('computeStreakStats', () {
    test('empty entries yields all zeros', () {
      final stats = computeStreakStats([], today: today);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 0);
      expect(stats.totalEntries, 0);
      expect(stats.entriesThisWeek, 0);
    });

    test('counts a run ending today', () {
      final stats = computeStreakStats([
        daysAgo(0),
        daysAgo(1),
        daysAgo(2),
      ], today: today);
      expect(stats.currentStreak, 3);
    });

    test('streak stays alive if yesterday was logged but today not yet', () {
      final stats = computeStreakStats([daysAgo(1), daysAgo(2)], today: today);
      expect(stats.currentStreak, 2);
    });

    test('streak is broken by a gap before yesterday', () {
      final stats = computeStreakStats([daysAgo(2), daysAgo(3)], today: today);
      expect(stats.currentStreak, 0);
    });

    test('best streak can exceed the current one', () {
      final stats = computeStreakStats([
        // A 4-day run a while back.
        daysAgo(20), daysAgo(19), daysAgo(18), daysAgo(17),
        // A shorter, still-active 2-day run.
        daysAgo(0), daysAgo(1),
      ], today: today);
      expect(stats.currentStreak, 2);
      expect(stats.bestStreak, 4);
    });

    test('duplicate same-day timestamps count once toward total', () {
      final stats = computeStreakStats([
        DateTime(2026, 9, 4, 8),
        DateTime(2026, 9, 4, 20),
      ], today: today);
      expect(stats.totalEntries, 1);
      expect(stats.currentStreak, 1);
    });

    test('entriesThisWeek covers the trailing 7 days, not before', () {
      final stats = computeStreakStats([
        daysAgo(0), daysAgo(6), // inside the 7-day window
        daysAgo(7), // just outside
      ], today: today);
      expect(stats.entriesThisWeek, 2);
      expect(stats.totalEntries, 3);
    });
  });
}
