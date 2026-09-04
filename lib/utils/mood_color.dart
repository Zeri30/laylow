import 'package:flutter/material.dart';

/// A distinct accent color per mood, drawn from the same muted, pastel
/// family as the app's purple/yellow palette so a mood badge always reads
/// as "this app's colors", not a clashing rainbow. Purely decorative (badges
/// in history/playlist) — never the sole way a mood is conveyed, since the
/// icon + label always accompany it.
const Map<String, Color> moodColors = {
  'happy': Color(0xFFE0AC1F),
  'excited': Color(0xFFE0873F),
  'calm': Color(0xFF7B6EBD),
  'sad': Color(0xFF6E9BC4),
  'anxious': Color(0xFFC97BB0),
  'lonely': Color(0xFF8C8BA8),
  'angry': Color(0xFFBA4949),
  'nostalgic': Color(0xFFD98CA0),
  'tired': Color(0xFF9A8C78),
};

Color moodColorFor(String moodId) =>
    moodColors[moodId] ?? const Color(0xFF7B6EBD);
