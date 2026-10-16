-- عدّاد تنزيل التطبيق «حكايا رائد حجازي»
-- يُلصق هذا النص كاملاً في Supabase ← SQL Editor ← New query ← Run (مرة واحدة فقط)

-- جدول يُسجَّل فيه كل جهاز ثبّت التطبيق مرة واحدة
create table if not exists public.installs (
  device text primary key,
  platform text,
  created_at timestamptz not null default now()
);
alter table public.installs enable row level security;

-- أي زائر يستطيع تسجيل جهازه فقط، ولا يستطيع أحد قراءة الجدول مباشرة
drop policy if exists "installs insert" on public.installs;
create policy "installs insert" on public.installs for insert to anon, authenticated
  with check (length(device) between 8 and 64 and coalesce(platform,'') in ('android','ios','desktop','other'));

-- الأرقام تُقرأ عبر دالة مخصّصة للمحرّر فقط
create or replace function public.install_stats() returns json
language sql stable security definer set search_path = public as $$
  select case when public.is_editor() then json_build_object(
    'total',   (select count(*) from public.installs),
    'android', (select count(*) from public.installs where platform = 'android'),
    'ios',     (select count(*) from public.installs where platform = 'ios'),
    'desktop', (select count(*) from public.installs where platform in ('desktop','other')),
    'week',    (select count(*) from public.installs where created_at > now() - interval '7 days')
  ) else null end;
$$;
revoke all on function public.install_stats() from public, anon;
grant execute on function public.install_stats() to authenticated;
