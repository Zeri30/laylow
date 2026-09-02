const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a date as e.g. "Aug 31, 2026", without pulling in `intl` for
/// just this.
String formatFriendlyDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
