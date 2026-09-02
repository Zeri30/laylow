class JournalEntrySummary {
  const JournalEntrySummary({
    required this.id,
    required this.entryDate,
    required this.mood,
    required this.moodIntensity,
    required this.journalText,
  });

  factory JournalEntrySummary.fromRow(Map<String, dynamic> row) {
    return JournalEntrySummary(
      id: row['id'] as String,
      entryDate: DateTime.parse(row['entry_date'] as String),
      mood: row['mood'] as String,
      moodIntensity: row['mood_intensity'] as int,
      journalText: row['journal_text'] as String?,
    );
  }

  final String id;
  final DateTime entryDate;
  final String mood;
  final int moodIntensity;
  final String? journalText;
}
