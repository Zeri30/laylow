class MoodOption {
  const MoodOption(this.id, this.label, this.emoji);

  final String id;
  final String label;
  final String emoji;
}

// Keep in sync with the `journal_entries.mood` check constraint in
// supabase/migrations/0001_initial_schema.sql.
const moodOptions = [
  MoodOption('happy', 'Happy', '😊'),
  MoodOption('sad', 'Sad', '😢'),
  MoodOption('anxious', 'Anxious', '😰'),
  MoodOption('lonely', 'Lonely', '😔'),
  MoodOption('angry', 'Angry', '😠'),
  MoodOption('calm', 'Calm', '😌'),
  MoodOption('excited', 'Excited', '🤩'),
  MoodOption('nostalgic', 'Nostalgic', '🥹'),
  MoodOption('tired', 'Tired', '😴'),
];

MoodOption moodOptionFor(String id) => moodOptions.firstWhere(
  (mood) => mood.id == id,
  orElse: () => MoodOption(id, id, '❓'),
);
