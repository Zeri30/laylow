// Rule-based mapping from a journal entry's mood + intensity to Deezer
// search terms (Requirements §3, ARCHITECTURE.md "Mood detection" — no
// AI/NLP, just user-selected mood + intensity driving a lookup table).
//
// Search terms are real, well-known modern artist names rather than
// generic genre words ("upbeat pop", "energetic funk") — a bare genre
// query mostly surfaces anonymous stock/production-library tracks on
// Deezer (e.g. "PremiumTraX", "Sinakho Dance Band"), which defeats
// ARCHITECTURE.md's "real, recognizable music" goal. Searching an actual
// artist's name returns their real, popular catalog instead.
//
// Keep the mood keys in sync with `journal_entries.mood` in
// supabase/migrations/0001_initial_schema.sql and `lib/models/mood_option.dart`.

const _windowSize = 4;

/// A pool of 8 modern, well-known artists per mood, loosely ordered from a
/// milder/softer take on the mood to a bigger/more intense one. Intensity
/// (1-5) slides a 4-artist window across the pool — 5 possible start
/// positions (0-4) for an 8-artist pool with a 4-artist window — so
/// different intensities surface a different (and, at the extremes,
/// entirely disjoint) set of real artists rather than the same few every
/// time.
const Map<String, List<String>> _moodArtists = {
  'happy': [
    'Jason Mraz',
    'Colbie Caillat',
    'Jack Johnson',
    'Ed Sheeran',
    'Bruno Mars',
    'Katy Perry',
    'Pharrell Williams',
    'Dua Lipa',
  ],
  'sad': [
    'Norah Jones',
    'Sam Smith',
    'Adele',
    'Lewis Capaldi',
    'Billie Eilish',
    'Olivia Rodrigo',
    'Rihanna',
    'Evanescence',
  ],
  // Ordered mild -> deeply calming, since the goal is to soothe anxiety
  // rather than musically match it — more intense anxiety gets more
  // grounding music, not more anxious-sounding music.
  'anxious': [
    'Jack Johnson',
    'John Mayer',
    'Norah Jones',
    'Bon Iver',
    'Phoebe Bridgers',
    'Billie Eilish',
    'Enya',
    'Ludovico Einaudi',
  ],
  'lonely': [
    'James Bay',
    'Sam Smith',
    'Lewis Capaldi',
    'Frank Ocean',
    'Billie Eilish',
    'LANY',
    'Rex Orange County',
    'Bon Iver',
  ],
  'angry': [
    'Twenty One Pilots',
    'Imagine Dragons',
    'Linkin Park',
    'Eminem',
    'Bring Me the Horizon',
    'Rage Against the Machine',
    'Limp Bizkit',
    'Slipknot',
  ],
  'calm': [
    'Jack Johnson',
    'Norah Jones',
    'Ed Sheeran',
    'John Mayer',
    'Bon Iver',
    'Alexandra Stréliski',
    'Ludovico Einaudi',
    'Enya',
  ],
  'excited': [
    'Bruno Mars',
    'Dua Lipa',
    'Ariana Grande',
    'The Weeknd',
    'Calvin Harris',
    'David Guetta',
    'Doja Cat',
    'Marshmello',
  ],
  // Kept to 2000s-2010s crossover hits rather than genuine oldies, so
  // "nostalgic" still reads as modern per the app's own goals.
  'nostalgic': [
    'John Mayer',
    'Coldplay',
    'Maroon 5',
    'OneRepublic',
    'Katy Perry',
    'Taylor Swift',
    'Backstreet Boys',
    'Britney Spears',
  ],
  'tired': [
    'Norah Jones',
    'Jack Johnson',
    'Bon Iver',
    'Billie Eilish',
    'Lord Huron',
    'The Paper Kites',
    'Enya',
    'Ludovico Einaudi',
  ],
};

const _fallbackTerms = ['Ed Sheeran'];

/// Returns the Deezer search query strings (real artist names) for a given
/// `mood` (one of `journal_entries.mood`'s allowed values) and `intensity`
/// (1-5), e.g. `deezerSearchTermsFor('happy', 1)` -> `['Jason Mraz',
/// 'Colbie Caillat', 'Jack Johnson', 'Ed Sheeran']`.
///
/// Falls back to a generic well-known artist for an unrecognized mood
/// rather than throwing, since this only drives a search query, not a data
/// constraint.
List<String> deezerSearchTermsFor(String mood, int intensity) {
  final artists = _moodArtists[mood];
  if (artists == null) return _fallbackTerms;

  final tier = intensity.clamp(1, 5) - 1;
  return artists.sublist(tier, tier + _windowSize);
}
