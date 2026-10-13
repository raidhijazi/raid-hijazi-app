-- إعداد قاعدة بيانات تطبيق «حكايا رائد حجازي»
-- يُلصق هذا النص كاملاً في Supabase ← SQL Editor ← New query ← Run

-- 1) جدول المحتوى: المعجم والأمثال والكلمات المستبعدة والتسجيلات والفيديوهات
create table if not exists public.kv (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

-- 2) قائمة المحرّرين المسموح لهم بالتعديل (أضف بريد كل محرّر هنا)
create table if not exists public.editors (email text primary key);
insert into public.editors (email) values ('geetawi4@gmail.com') on conflict do nothing;

create or replace function public.is_editor() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.editors where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

alter table public.kv enable row level security;
alter table public.editors enable row level security;

drop policy if exists "kv read" on public.kv;
drop policy if exists "kv insert" on public.kv;
drop policy if exists "kv update" on public.kv;
create policy "kv read"   on public.kv for select using (true);
create policy "kv insert" on public.kv for insert to authenticated with check (public.is_editor());
create policy "kv update" on public.kv for update to authenticated using (public.is_editor()) with check (public.is_editor());

-- 3) مخزن الملفات الصوتية والفيديو (عام للقراءة، حتى 50 ميغابايت للملف)
insert into storage.buckets (id, name, public, file_size_limit)
values ('media', 'media', true, 52428800)
on conflict (id) do update set public = true, file_size_limit = 52428800;

drop policy if exists "media read"   on storage.objects;
drop policy if exists "media insert" on storage.objects;
drop policy if exists "media update" on storage.objects;
drop policy if exists "media delete" on storage.objects;
create policy "media read"   on storage.objects for select using (bucket_id = 'media');
create policy "media insert" on storage.objects for insert to authenticated with check (bucket_id = 'media' and public.is_editor());
create policy "media update" on storage.objects for update to authenticated using (bucket_id = 'media' and public.is_editor());
create policy "media delete" on storage.objects for delete to authenticated using (bucket_id = 'media' and public.is_editor());
