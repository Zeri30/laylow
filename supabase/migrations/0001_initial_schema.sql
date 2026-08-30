-- Laylow initial schema: profiles, journal_entries, playlists, playlist_tracks, track_feedback
-- Run via `supabase db push`, or paste into the Supabase SQL editor.

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- profiles — one row per user, basic account info
-- ---------------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles: select own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles: insert own" on public.profiles
  for insert with check (auth.uid() = id);

create policy "profiles: update own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "profiles: delete own" on public.profiles
  for delete using (auth.uid() = id);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row whenever a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- journal_entries — one entry per day per user: journal text, mood, rating
-- ---------------------------------------------------------------------------

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  entry_date date not null,
  mood text not null check (
    mood in (
      'happy', 'sad', 'anxious', 'lonely',
      'angry', 'calm', 'excited', 'nostalgic', 'tired'
    )
  ),
  mood_intensity smallint not null check (mood_intensity between 1 and 5),
  journal_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, entry_date)
);

create index journal_entries_user_date_idx
  on public.journal_entries (user_id, entry_date desc);

alter table public.journal_entries enable row level security;

create policy "journal_entries: select own" on public.journal_entries
  for select using (auth.uid() = user_id);

create policy "journal_entries: insert own" on public.journal_entries
  for insert with check (auth.uid() = user_id);

create policy "journal_entries: update own" on public.journal_entries
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "journal_entries: delete own" on public.journal_entries
  for delete using (auth.uid() = user_id);

create trigger journal_entries_set_updated_at
  before update on public.journal_entries
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- playlists — one generated playlist per journal entry
-- ---------------------------------------------------------------------------

create table public.playlists (
  id uuid primary key default gen_random_uuid(),
  journal_entry_id uuid not null unique references public.journal_entries (id) on delete cascade,
  -- denormalized from journal_entries so RLS policies here don't need a join
  user_id uuid not null references auth.users (id) on delete cascade,
  -- snapshot of the mood/intensity used to generate this playlist, so a later
  -- edit to the journal entry doesn't retroactively change playlist history
  mood text not null,
  mood_intensity smallint not null check (mood_intensity between 1 and 5),
  created_at timestamptz not null default now()
);

create index playlists_user_id_idx on public.playlists (user_id);

alter table public.playlists enable row level security;

create policy "playlists: select own" on public.playlists
  for select using (auth.uid() = user_id);

create policy "playlists: insert own" on public.playlists
  for insert with check (auth.uid() = user_id);

create policy "playlists: update own" on public.playlists
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "playlists: delete own" on public.playlists
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- playlist_tracks — individual Deezer/YouTube tracks within a playlist
-- ---------------------------------------------------------------------------

create table public.playlist_tracks (
  id uuid primary key default gen_random_uuid(),
  playlist_id uuid not null references public.playlists (id) on delete cascade,
  -- denormalized from playlists so RLS policies here don't need a join
  user_id uuid not null references auth.users (id) on delete cascade,
  position smallint not null,
  deezer_track_id bigint,
  title text not null,
  artist text not null,
  album text,
  preview_url text,
  artwork_url text,
  youtube_video_id text,
  created_at timestamptz not null default now(),
  unique (playlist_id, position)
);

create index playlist_tracks_playlist_id_idx on public.playlist_tracks (playlist_id);
create index playlist_tracks_user_id_idx on public.playlist_tracks (user_id);

alter table public.playlist_tracks enable row level security;

create policy "playlist_tracks: select own" on public.playlist_tracks
  for select using (auth.uid() = user_id);

create policy "playlist_tracks: insert own" on public.playlist_tracks
  for insert with check (auth.uid() = user_id);

create policy "playlist_tracks: update own" on public.playlist_tracks
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "playlist_tracks: delete own" on public.playlist_tracks
  for delete using (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- track_feedback — like/skip signal per track, for future personalization
-- ---------------------------------------------------------------------------

create table public.track_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  playlist_track_id uuid not null references public.playlist_tracks (id) on delete cascade,
  -- latest signal wins per (user, track) — upsert on conflict rather than
  -- accumulating a full play-event log, which the MVP doesn't need
  feedback text not null check (feedback in ('like', 'dislike', 'skip', 'played')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, playlist_track_id)
);

create index track_feedback_user_id_idx on public.track_feedback (user_id);

alter table public.track_feedback enable row level security;

create policy "track_feedback: select own" on public.track_feedback
  for select using (auth.uid() = user_id);

create policy "track_feedback: insert own" on public.track_feedback
  for insert with check (auth.uid() = user_id);

create policy "track_feedback: update own" on public.track_feedback
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "track_feedback: delete own" on public.track_feedback
  for delete using (auth.uid() = user_id);

create trigger track_feedback_set_updated_at
  before update on public.track_feedback
  for each row execute function public.set_updated_at();
