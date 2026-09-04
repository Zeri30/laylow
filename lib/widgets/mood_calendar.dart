import 'package:flutter/material.dart';

import '../models/journal_entry_summary.dart';
import '../utils/mood_color.dart';

const _weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// A month grid where each logged day is a dot in that day's mood color —
/// "mood history over time" at a glance, rather than only as a flat
/// chronological list (Requirements §6). Tapping a logged day opens that
/// entry; tapping an empty day does nothing.
class MoodCalendar extends StatefulWidget {
  const MoodCalendar({
    super.key,
    required this.entries,
    required this.onDayTap,
  });

  /// Need not be sorted — grouped internally by calendar day.
  final List<JournalEntrySummary> entries;
  final ValueChanged<JournalEntrySummary> onDayTap;

  @override
  State<MoodCalendar> createState() => _MoodCalendarState();
}

class _MoodCalendarState extends State<MoodCalendar> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final anchor = widget.entries.isEmpty
        ? DateTime.now()
        : widget.entries
              .map((e) => e.entryDate)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    _visibleMonth = DateTime(anchor.year, anchor.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _visibleMonth.year == now.year && _visibleMonth.month == now.month;
  }

  void _shiftMonth(int delta) {
    setState(
      () => _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final entriesByDay = <int, JournalEntrySummary>{
      for (final entry in widget.entries)
        if (entry.entryDate.year == _visibleMonth.year &&
            entry.entryDate.month == _visibleMonth.month)
          entry.entryDate.day: entry,
    };

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    ).weekday % 7; // Sunday-first grid.

    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                  onPressed: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                  onPressed: _isCurrentMonth ? null : () => _shiftMonth(1),
                ),
              ],
            ),
            Row(
              children: [
                for (final label in _weekdayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingBlanks + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemBuilder: (context, index) {
                if (index < leadingBlanks) return const SizedBox.shrink();

                final day = index - leadingBlanks + 1;
                final entry = entriesByDay[day];
                final isToday =
                    _isCurrentMonth && day == now.day;

                return _DayCell(
                  day: day,
                  color: entry == null ? null : moodColorFor(entry.mood),
                  isToday: isToday,
                  onTap: entry == null ? null : () => widget.onDayTap(entry),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.color,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final Color? color;
  final bool isToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color?.withValues(alpha: 0.85),
              border: isToday
                  ? Border.all(color: scheme.primary, width: 1.6)
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: color != null ? FontWeight.w700 : FontWeight.w500,
                color: color != null ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
