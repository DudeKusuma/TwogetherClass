-- Username login support for the XI-B2 student accounts.
-- Apply after 20261109_finance_roster.sql.
alter table public.profiles
  add column if not exists username text,
  add column if not exists attendance_number integer;

create unique index if not exists profiles_username_unique_idx
  on public.profiles (lower(username))
  where username is not null;

create index if not exists profiles_attendance_number_idx
  on public.profiles (attendance_number)
  where attendance_number is not null;

-- Keep roster/profile links consistent for accounts provisioned by the Edge Function.
comment on column public.profiles.username is
  'Login username, e.g. siswa01. The matching Supabase Auth email is internal and synthetic.';
