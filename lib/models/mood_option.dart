import 'package:flutter/material.dart';

class MoodOption {
  const MoodOption(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

// Icons are abstract symbols (sun, flame, moon...) rather than emoji faces,
// so mood is read through the app's own color/shape language instead of the
// OS's emoji set. Keep in sync with the `journal_entries.mood` check
// constraint in supabase/migrations/0001_initial_schema.sql.
const moodOptions = [
  MoodOption('happy', 'Happy', Icons.wb_sunny_rounded),
  MoodOption('sad', 'Sad', Icons.water_drop_rounded),
  MoodOption('anxious', 'Anxious', Icons.bolt_rounded),
  MoodOption('lonely', 'Lonely', Icons.person_outline_rounded),
  MoodOption('angry', 'Angry', Icons.local_fire_department_rounded),
  MoodOption('calm', 'Calm', Icons.spa_rounded),
  MoodOption('excited', 'Excited', Icons.auto_awesome_rounded),
  MoodOption('nostalgic', 'Nostalgic', Icons.hourglass_bottom_rounded),
  MoodOption('tired', 'Tired', Icons.bedtime_rounded),
];

MoodOption moodOptionFor(String id) => moodOptions.firstWhere(
  (mood) => mood.id == id,
  orElse: () => MoodOption(id, id, Icons.help_outline_rounded),
);
