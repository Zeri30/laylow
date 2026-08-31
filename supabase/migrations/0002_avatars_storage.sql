-- Laylow avatars: Storage bucket for profile pictures.
-- Run via `supabase db push`, or paste into the Supabase SQL editor.

-- ---------------------------------------------------------------------------
-- avatars — public-read bucket, one file per user at `{user_id}/avatar.*`
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Anyone can view avatars (they're rendered in the app UI), but only the
-- owning user can write to their own folder — enforced by matching the
-- first path segment against auth.uid(), same pattern as the table RLS
-- policies in 0001_initial_schema.sql.

create policy "avatars: public read" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "avatars: insert own" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars: update own" on storage.objects
  for update using (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "avatars: delete own" on storage.objects
  for delete using (
    bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]
  );
