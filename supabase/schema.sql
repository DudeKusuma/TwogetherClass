-- Together Class: initial Supabase schema
-- Run this entire file in Supabase Dashboard > SQL Editor > New query.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  role text not null default 'student' check (role in ('student', 'admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  active boolean not null default true,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.subject_descriptions (
  subject_key text primary key,
  description text not null default '',
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

create table if not exists public.subject_activities (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  type text not null check (type in ('tugas', 'kuis', 'ulangan', 'lainnya')),
  title text not null,
  notes text not null default '',
  date date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists announcements_active_created_idx on public.announcements(active, created_at desc);
create index if not exists subject_activities_date_idx on public.subject_activities(date);

-- Create a profile automatically for every new Auth user. All new users are students.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1)),
    'student'
  ) on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

create or replace function public.is_class_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

alter table public.profiles enable row level security;
alter table public.announcements enable row level security;
alter table public.subject_descriptions enable row level security;
alter table public.subject_activities enable row level security;

-- Users can read their own profile. Admin role changes must be made by a trusted project owner in SQL.
drop policy if exists "Users read own profile" on public.profiles;
create policy "Users read own profile" on public.profiles
for select to authenticated using (id = (select auth.uid()) or public.is_class_admin());

drop policy if exists "Admins update profiles" on public.profiles;
create policy "Admins update profiles" on public.profiles
for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());

-- Class members can read active announcements; admins can read and manage all.
drop policy if exists "Members read active announcements" on public.announcements;
create policy "Members read active announcements" on public.announcements
for select to authenticated using (active = true or public.is_class_admin());
drop policy if exists "Admins insert announcements" on public.announcements;
create policy "Admins insert announcements" on public.announcements
for insert to authenticated with check (public.is_class_admin());
drop policy if exists "Admins update announcements" on public.announcements;
create policy "Admins update announcements" on public.announcements
for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());
drop policy if exists "Admins delete announcements" on public.announcements;
create policy "Admins delete announcements" on public.announcements
for delete to authenticated using (public.is_class_admin());

-- All signed-in class members can read subject descriptions and activities; only admins write.
drop policy if exists "Members read subject descriptions" on public.subject_descriptions;
create policy "Members read subject descriptions" on public.subject_descriptions
for select to authenticated using (true);
drop policy if exists "Admins insert subject descriptions" on public.subject_descriptions;
create policy "Admins insert subject descriptions" on public.subject_descriptions
for insert to authenticated with check (public.is_class_admin());
drop policy if exists "Admins update subject descriptions" on public.subject_descriptions;
create policy "Admins update subject descriptions" on public.subject_descriptions
for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());
drop policy if exists "Admins delete subject descriptions" on public.subject_descriptions;
create policy "Admins delete subject descriptions" on public.subject_descriptions
for delete to authenticated using (public.is_class_admin());

drop policy if exists "Members read subject activities" on public.subject_activities;
create policy "Members read subject activities" on public.subject_activities
for select to authenticated using (true);
drop policy if exists "Admins insert subject activities" on public.subject_activities;
create policy "Admins insert subject activities" on public.subject_activities
for insert to authenticated with check (public.is_class_admin());
drop policy if exists "Admins update subject activities" on public.subject_activities;
create policy "Admins update subject activities" on public.subject_activities
for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());
drop policy if exists "Admins delete subject activities" on public.subject_activities;
create policy "Admins delete subject activities" on public.subject_activities
for delete to authenticated using (public.is_class_admin());

-- Explicit API privileges for the authenticated browser client.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.announcements to authenticated;
grant select, insert, update, delete on public.subject_descriptions to authenticated;
grant select, insert, update, delete on public.subject_activities to authenticated;
grant select, update on public.profiles to authenticated;
