-- Student profiles for Twogether Class.
-- Apply after 20261109_finance_roster.sql and 20261110_username_accounts.sql.

create table if not exists public.student_profile_details (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  short_name text not null default '' check (char_length(short_name) <= 40),
  birth_place text not null default '' check (char_length(birth_place) <= 80),
  birth_date date,
  gender text check (gender in ('L', 'P', 'Prefer not to say')),
  address text not null default '' check (char_length(address) <= 180),
  hobbies text[] not null default '{}',
  about_me text[] not null default '{}',
  show_student_number boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table public.student_profile_details enable row level security;

drop policy if exists "Students read own profile details or admin" on public.student_profile_details;
create policy "Students read own profile details or admin"
  on public.student_profile_details for select to authenticated
  using (profile_id = (select auth.uid()) or public.is_class_admin());

drop policy if exists "Students insert own profile details or admin" on public.student_profile_details;
create policy "Students insert own profile details or admin"
  on public.student_profile_details for insert to authenticated
  with check (profile_id = (select auth.uid()) or public.is_class_admin());

drop policy if exists "Students update own profile details or admin" on public.student_profile_details;
create policy "Students update own profile details or admin"
  on public.student_profile_details for update to authenticated
  using (profile_id = (select auth.uid()) or public.is_class_admin())
  with check (profile_id = (select auth.uid()) or public.is_class_admin());

grant select, insert, update on public.student_profile_details to authenticated;

-- class_roster contains the school student number. Do not expose the whole
-- roster row to every student through the table API. Students may read their
-- own row; admins retain full access through the admin policy.
drop policy if exists "Members read XI B2 roster" on public.class_roster;
drop policy if exists "Users read own roster row or admin" on public.class_roster;
create policy "Users read own roster row or admin"
  on public.class_roster for select to authenticated
  using (profile_id = (select auth.uid()) or public.is_class_admin());

-- The UI needs classmates' names/attendance numbers, but not their NISN.
-- This RPC returns a public roster projection and only includes the NISN for
-- the owner of that row or an administrator.
create or replace function public.get_class_roster_public()
returns table (
  attendance_number integer,
  student_number text,
  full_name text,
  gender text,
  profile_id uuid
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    r.attendance_number,
    case
      when auth.uid() = r.profile_id or public.is_class_admin() then r.student_number
      else null
    end as student_number,
    r.full_name,
    r.gender,
    r.profile_id
  from public.class_roster r
  where auth.uid() is not null
  order by r.attendance_number;
$$;

revoke all on function public.get_class_roster_public() from public;
grant execute on function public.get_class_roster_public() to authenticated;


-- Return only the fields needed by the profile card. NISN is returned only to
-- its owner, an administrator, or classmates when its owner opted in.
create or replace function public.get_student_profile(target_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  profile_data jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select jsonb_build_object(
    'profile_id', p.id,
    'full_name', r.full_name,
    'short_name', coalesce(nullif(d.short_name, ''), nullif(p.display_name, ''), r.full_name),
    'attendance_number', r.attendance_number,
    'student_number',
      case
        when auth.uid() = p.id or public.is_class_admin() or coalesce(d.show_student_number, false)
        then r.student_number
        else null
      end,
    'birth_place', coalesce(d.birth_place, ''),
    'birth_date', d.birth_date,
    'gender', coalesce(d.gender, r.gender),
    'address', coalesce(d.address, ''),
    'hobbies', coalesce(d.hobbies, '{}'::text[]),
    'about_me', coalesce(d.about_me, '{}'::text[]),
    'show_student_number',
      case when auth.uid() = p.id or public.is_class_admin()
        then coalesce(d.show_student_number, false)
        else null
      end
  )
  into profile_data
  from public.class_roster r
  join public.profiles p on p.id = r.profile_id
  left join public.student_profile_details d on d.profile_id = p.id
  where p.id = target_profile_id;

  return profile_data;
end;
$$;

revoke all on function public.get_student_profile(uuid) from public;
grant execute on function public.get_student_profile(uuid) to authenticated;
