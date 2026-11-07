-- Enforce one shared daily spotlight response per student per Bali calendar day.
-- The daily spotlight itself is selected deterministically by the frontend from the same date,
-- so all students see the same content type and prompt. This trigger prevents submitting
-- multiple different daily content types on the same date.

create or replace function public.enforce_one_daily_spotlight_response()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.activity_date is null then
    new.activity_date := (now() at time zone 'Asia/Makassar')::date;
  end if;

  -- Serialize submissions for the same student/date to prevent concurrent double submits.
  perform pg_advisory_xact_lock(hashtext(new.user_id::text), hashtext(new.activity_date::text));

  if exists (
    select 1
    from public.daily_interactions existing
    where existing.user_id = new.user_id
      and existing.activity_date = new.activity_date
  ) then
    raise exception 'one daily interaction per student per day is allowed';
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_one_daily_spotlight_response() from public;

drop trigger if exists enforce_one_daily_spotlight_response on public.daily_interactions;
create trigger enforce_one_daily_spotlight_response
before insert on public.daily_interactions
for each row execute function public.enforce_one_daily_spotlight_response();
