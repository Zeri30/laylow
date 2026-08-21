# Laylow

Laylow is a daily mood-journaling app that turns your entry into a personalized
soundtrack. Record how you're feeling, write about your day if you want to, and get a
playlist of real, recognizable music that matches your mood — not generic ambient
sounds — as a reason to keep coming back and journaling.

## How it works

1. **Mood** — pick how you're feeling and how intensely (Happy, Sad, Anxious, Lonely,
   Angry, Calm, Excited, Nostalgic, Tired).
2. **Journal** — optionally write about your day alongside your mood.
3. **Playlist** — get a personalized set of tracks matched to your mood for that entry.
4. **Reflect** — look back at past entries together with the mood and music tied to them,
   and spot patterns over time.

## Tech stack

Built with a zero-budget stack — no paid APIs, hosting, or AI services:

- **Flutter** — the app itself
- **Supabase** — auth, Postgres database, and storage
- **Deezer API** — free music search and previews
- **YouTube embedded player** — full-song playback

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full reasoning behind these
choices (this file isn't tracked in git — it's local project notes).

## Status

Early development. See `docs/CHECKLIST.md` (local notes) for current progress.

## Running the project

```
flutter pub get
flutter run
```

Requires a `lib/config/supabase_config.dart` file with your own Supabase project URL and
publishable (anon) key. This key is safe to commit — it only works within the
permissions granted by this project's Row Level Security policies. The separate secret
(`service_role`) key must never be placed here or committed anywhere.
