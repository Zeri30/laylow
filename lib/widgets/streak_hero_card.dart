import 'package:flutter/material.dart';

import '../services/streak_service.dart';

/// The Today screen's hero card: a bold gradient surface leading with the
/// user's current journaling streak, plus total-entries/best-streak/this-week
/// stats and a shortcut into History. Deliberately contained to this one
/// card rather than washing the whole screen in gradient, so the calmer
/// mood-picker/journal sections below stay easy to read.
class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({
    super.key,
    required this.stats,
    required this.onViewHistory,
  });

  final StreakStats stats;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onGradient = Colors.white;
    final onGradientMuted = Colors.white.withValues(alpha: 0.75);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.35)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _glowCircle(140, onGradient.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: _glowCircle(120, onGradient.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JOURNALING STREAK',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: onGradientMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${stats.currentStreak}',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: onGradient,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      stats.currentStreak == 1 ? 'day' : 'days in a row',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: onGradientMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _statChip(
                      '${stats.totalEntries}',
                      'Total entries',
                      onGradient,
                      onGradientMuted,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      '${stats.bestStreak}',
                      'Best streak',
                      onGradient,
                      onGradientMuted,
                    ),
                    const SizedBox(width: 8),
                    _statChip(
                      '${stats.entriesThisWeek}',
                      'This week',
                      onGradient,
                      onGradientMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Material(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onViewHistory,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(
                        'View history',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: onGradient,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _statChip(
    String value,
    String label,
    Color onGradient,
    Color onGradientMuted,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: onGradient,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, color: onGradientMuted),
            ),
          ],
        ),
      ),
    );
  }
}
