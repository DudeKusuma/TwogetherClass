-- Twogether Class shared calendar
-- Run this migration in Supabase SQL Editor AFTER the original schema.sql.

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  location text not null default '',
  event_date date not null,
  start_time time,
  end_time time,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  event_id uuid references public.calendar_events(id) on delete set null,
  request_type text not null check (request_type in ('add', 'edit', 'delete')),
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.calendar_reactions (
  event_id uuid not null references public.calendar_events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  reaction text not null check (reaction in ('like', 'dislike')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create table if not exists public.personal_calendar_markers (
  user_id uuid not null references public.profiles(id) on delete cascade,
  marker_date date not null,
  emoji text not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, marker_date)
);

create index if not exists calendar_events_date_idx on public.calendar_events(event_date);
create index if not exists calendar_requests_status_created_idx on public.calendar_requests(status, created_at desc);
create index if not exists calendar_requests_requester_idx on public.calendar_requests(requester_id, created_at desc);
create index if not exists calendar_reactions_event_idx on public.calendar_reactions(event_id);

alter table public.calendar_events enable row level security;
alter table public.calendar_requests enable row level security;
alter table public.calendar_reactions enable row level security;
alter table public.personal_calendar_markers enable row level security;

-- Shared events are visible only after approval. Direct client writes are blocked.
drop policy if exists "Members read calendar events" on public.calendar_events;
create policy "Members read calendar events" on public.calendar_events
for select to authenticated using (true);
drop policy if exists "Admins manage calendar events" on public.calendar_events;
create policy "Admins manage calendar events" on public.calendar_events
for all to authenticated using (public.is_class_admin()) with check (public.is_class_admin());

-- Students can see their own requests; admins can see all requests.
drop policy if exists "Users read own calendar requests or admins read all" on public.calendar_requests;
create policy "Users read own calendar requests or admins read all" on public.calendar_requests
for select to authenticated using (requester_id = (select auth.uid()) or public.is_class_admin());
drop policy if exists "Members submit calendar requests" on public.calendar_requests;
create policy "Members submit calendar requests" on public.calendar_requests
for insert to authenticated with check (requester_id = (select auth.uid()) and status = 'pending');
drop policy if exists "Admins review calendar requests" on public.calendar_requests;
create policy "Admins review calendar requests" on public.calendar_requests
for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());

-- Each member has one vote per event and may switch or clear it.
drop policy if exists "Members read calendar reactions" on public.calendar_reactions;
create policy "Members read calendar reactions" on public.calendar_reactions
for select to authenticated using (true);
drop policy if exists "Members manage own calendar reaction" on public.calendar_reactions;
create policy "Members manage own calendar reaction" on public.calendar_reactions
for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Personal emoji markers are private to their owner.
drop policy if exists "Users manage own personal calendar markers" on public.personal_calendar_markers;
create policy "Users manage own personal calendar markers" on public.personal_calendar_markers
for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Applying an approved request is done inside the database, so students cannot
-- directly modify shared events and pending changes never leak into the calendar.
create or replace function public.apply_calendar_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id uuid;
begin
  if old.status = 'pending' and new.status = 'approved' then
    if new.request_type = 'add' then
      insert into public.calendar_events (title, description, location, event_date, start_time, end_time, created_by)
      values (
        coalesce(new.payload->>'title', ''),
        coalesce(new.payload->>'description', ''),
        coalesce(new.payload->>'location', ''),
        (new.payload->>'event_date')::date,
        nullif(new.payload->>'start_time', '')::time,
        nullif(new.payload->>'end_time', '')::time,
        new.requester_id
      );
    elsif new.request_type = 'edit' then
      update public.calendar_events
      set title = coalesce(new.payload->>'title', title),
          description = coalesce(new.payload->>'description', description),
          location = coalesce(new.payload->>'location', location),
          event_date = coalesce((new.payload->>'event_date')::date, event_date),
          start_time = case when new.payload ? 'start_time' then nullif(new.payload->>'start_time', '')::time else start_time end,
          end_time = case when new.payload ? 'end_time' then nullif(new.payload->>'end_time', '')::time else end_time end,
          updated_at = now()
      where id = new.event_id and created_by = new.requester_id;
      if not found then raise exception 'Only the event creator can submit an edit request'; end if;
    elsif new.request_type = 'delete' then
      delete from public.calendar_events where id = new.event_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists apply_approved_calendar_request on public.calendar_requests;
create trigger apply_approved_calendar_request
after update of status on public.calendar_requests
for each row execute function public.apply_calendar_request();

grant select, insert, update, delete on public.calendar_events to authenticated;
grant select, insert, update on public.calendar_requests to authenticated;
grant select, insert, update, delete on public.calendar_reactions to authenticated;
grant select, insert, update, delete on public.personal_calendar_markers to authenticated;

-- A rejection must always include an explanation.
alter table public.calendar_requests
  drop constraint if exists calendar_requests_rejection_reason_required;
alter table public.calendar_requests
  add constraint calendar_requests_rejection_reason_required
  check (status <> 'rejected' or length(trim(coalesce(rejection_reason, ''))) > 0);

-- Display names are class-visible; profiles contain no email or other private fields.
drop policy if exists "Members read class display names" on public.profiles;
create policy "Members read class display names" on public.profiles
for select to authenticated using (true);

-- Enforce creator-only edit requests at the database layer as well as in the UI.
drop policy if exists "Members submit calendar requests" on public.calendar_requests;
create policy "Members submit calendar requests" on public.calendar_requests
for insert to authenticated with check (
  requester_id = (select auth.uid())
  and status = 'pending'
  and (
    request_type <> 'edit'
    or exists (
      select 1 from public.calendar_events e
      where e.id = event_id and e.created_by = (select auth.uid())
    )
  )
);

-- Enable live admin badge updates when Supabase Realtime is available.
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'calendar_requests'
     ) then
    alter publication supabase_realtime add table public.calendar_requests;
  end if;
end;
$$;
