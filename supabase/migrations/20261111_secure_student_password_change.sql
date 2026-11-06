-- Server-controlled first-login password requirement.
-- Apply only after 20261110_username_accounts.sql.

alter table public.profiles
  add column if not exists must_change_password boolean not null default false;

-- Carry forward the old flag for accounts provisioned by the previous Edge Function.
-- The database column becomes the source of truth; user-editable Auth metadata is not trusted.
update public.profiles as p
set must_change_password = true
from auth.users as u
where u.id = p.id
  and u.raw_user_meta_data ->> 'must_change_password' = 'true';

-- One profile may be linked to at most one attendance number.
-- This intentionally fails instead of silently choosing a winner if old data has duplicates.
do $$
begin
  if exists (
    select attendance_number
    from public.profiles
    where attendance_number is not null
    group by attendance_number
    having count(*) > 1
  ) then
    raise exception 'Ada profiles dengan attendance_number duplikat. Periksa dan rapikan data sebelum menjalankan migration ini.';
  end if;
end;
$$;

create unique index if not exists profiles_attendance_number_unique_idx
  on public.profiles (attendance_number)
  where attendance_number is not null;

comment on column public.profiles.must_change_password is
  'Server-controlled flag. Students may read it but cannot update it directly; the password-change Edge Function clears it.';
