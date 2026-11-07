-- Twogether Class: Daily Community, Discover Students, Games and T-Money Shop
-- Run in Supabase Dashboard > SQL Editor after the existing migrations.

-- Student-controlled opt-in for the Discover Students directory.
alter table public.student_profile_details
  add column if not exists discover_opt_in boolean not null default false;


-- Include the new privacy preference in the existing student profile RPC.
create or replace function public.get_student_profile(target_profile_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare profile_data jsonb;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select jsonb_build_object(
    'profile_id', p.id,
    'full_name', r.full_name,
    'short_name', coalesce(nullif(d.short_name, ''), nullif(p.display_name, ''), r.full_name),
    'attendance_number', r.attendance_number,
    'student_number', case when auth.uid() = p.id or public.is_class_admin() or coalesce(d.show_student_number, false) then r.student_number else null end,
    'birth_place', coalesce(d.birth_place, ''),
    'birth_date', d.birth_date,
    'gender', coalesce(d.gender, r.gender),
    'address', coalesce(d.address, ''),
    'hobbies', coalesce(d.hobbies, '{}'::text[]),
    'about_me', coalesce(d.about_me, '{}'::text[]),
    'show_student_number', case when auth.uid() = p.id or public.is_class_admin() then coalesce(d.show_student_number, false) else null end,
    'discover_opt_in', case when auth.uid() = p.id or public.is_class_admin() then coalesce(d.discover_opt_in, false) else null end
  ) into profile_data
  from public.class_roster r
  join public.profiles p on p.id = r.profile_id
  left join public.student_profile_details d on d.profile_id = p.id
  where p.id = target_profile_id;
  return profile_data;
end;
$$;
revoke all on function public.get_student_profile(uuid) from public;
grant execute on function public.get_student_profile(uuid) to authenticated;

-- Daily answers, polls and This-or-That submissions. Responses are private by default.
create table if not exists public.daily_interactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  content_type text not null check (content_type in ('random_question','class_poll','this_or_that')),
  prompt text not null,
  response text not null,
  visibility text not null default 'private' check (visibility in ('private','anonymous','nickname')),
  status text not null default 'private' check (status in ('private','pending','approved','rejected')),
  created_at timestamptz not null default now()
);
-- A student can submit at most one response per content type per local day.
alter table public.daily_interactions add column if not exists activity_date date;
update public.daily_interactions set activity_date = (created_at at time zone 'Asia/Makassar')::date where activity_date is null;
alter table public.daily_interactions alter column activity_date set default ((now() at time zone 'Asia/Makassar')::date);
alter table public.daily_interactions alter column activity_date set not null;
create unique index if not exists daily_interactions_one_per_day_idx on public.daily_interactions(user_id, content_type, activity_date);

create index if not exists daily_interactions_user_created_idx on public.daily_interactions(user_id, created_at desc);
alter table public.daily_interactions enable row level security;
drop policy if exists "Students read own daily interactions" on public.daily_interactions;
create policy "Students read own daily interactions" on public.daily_interactions for select to authenticated using (user_id = (select auth.uid()) or public.is_class_admin());
drop policy if exists "Students submit own daily interactions" on public.daily_interactions;
create policy "Students submit own daily interactions" on public.daily_interactions for insert to authenticated with check (user_id = (select auth.uid()) and status in ('private','pending') and activity_date = ((now() at time zone 'Asia/Makassar')::date) and length(trim(response)) between 1 and 500);
grant select, insert on public.daily_interactions to authenticated;
drop policy if exists "Admins moderate daily interactions" on public.daily_interactions;
create policy "Admins moderate daily interactions" on public.daily_interactions for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());
grant update on public.daily_interactions to authenticated;

create or replace function public.get_approved_daily_answers(p_prompt text)
returns table(display_name text, response text)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case when i.visibility = 'anonymous' then 'Anonim' else coalesce(nullif(d.short_name,''),'Siswa') end,
         i.response
  from public.daily_interactions i
  join public.profiles p on p.id = i.user_id
  left join public.student_profile_details d on d.profile_id = i.user_id
  where auth.uid() is not null and i.content_type = 'random_question'
    and i.prompt = p_prompt and i.status = 'approved' and i.visibility in ('anonymous','nickname')
    and i.activity_date = (now() at time zone 'Asia/Makassar')::date
  order by i.created_at desc limit 5;
$$;
revoke all on function public.get_approved_daily_answers(text) from public;
grant execute on function public.get_approved_daily_answers(text) to authenticated;

create or replace function public.get_daily_poll_results(p_content_type text, p_prompt text)
returns table(response text, votes bigint)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select i.response, count(*)::bigint
  from public.daily_interactions i
  where auth.uid() is not null and i.content_type = p_content_type
    and p_content_type in ('class_poll','this_or_that') and i.prompt = p_prompt
    and i.activity_date = (now() at time zone 'Asia/Makassar')::date
  group by i.response order by count(*) desc, i.response;
$$;
revoke all on function public.get_daily_poll_results(text,text) from public;
grant execute on function public.get_daily_poll_results(text,text) to authenticated;

-- Discover Students returns only opted-in, non-sensitive profile fields.
create or replace function public.get_discover_students()
returns table (
  profile_id uuid,
  display_name text,
  hobbies text[],
  about_me text[]
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.id, nullif(trim(d.short_name),''),
    coalesce(d.hobbies, '{}'::text[]), coalesce(d.about_me, '{}'::text[])
  from public.profiles p
  join public.class_roster r on r.profile_id = p.id
  join public.student_profile_details d on d.profile_id = p.id
  where auth.uid() is not null
    and d.discover_opt_in = true
    and nullif(trim(d.short_name),'') is not null
    and (cardinality(coalesce(d.hobbies, '{}'::text[])) > 0 or cardinality(coalesce(d.about_me, '{}'::text[])) > 0)
  order by nullif(trim(d.short_name),'');
$$;
revoke all on function public.get_discover_students() from public;
grant execute on function public.get_discover_students() to authenticated;

-- T-Money wallet and transaction history.
create table if not exists public.class_wallets (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  t_money integer not null default 0 check (t_money >= 0),
  updated_at timestamptz not null default now()
);
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  amount integer not null,
  transaction_type text not null check (transaction_type in ('earn','spend')),
  reason text not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);
create index if not exists wallet_transactions_profile_created_idx on public.wallet_transactions(profile_id, created_at desc);

-- First meaningful daily community response earns one small T-Money reward per day.
create table if not exists public.daily_participation_rewards (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reward_date date not null,
  created_at timestamptz not null default now(),
  primary key(profile_id, reward_date)
);
alter table public.daily_participation_rewards enable row level security;
drop policy if exists "Students read own participation rewards" on public.daily_participation_rewards;
create policy "Students read own participation rewards" on public.daily_participation_rewards for select to authenticated using (profile_id = (select auth.uid()) or public.is_class_admin());
grant select on public.daily_participation_rewards to authenticated;

create or replace function public.reward_daily_participation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare reward_id date := (now() at time zone 'Asia/Makassar')::date;
begin
  insert into public.class_wallets(profile_id) values (new.user_id) on conflict (profile_id) do nothing;
  insert into public.daily_participation_rewards(profile_id,reward_date)
    values (new.user_id,reward_id) on conflict (profile_id,reward_date) do nothing;
  if found then
    update public.class_wallets set t_money = t_money + 1, updated_at = now() where profile_id = new.user_id;
    insert into public.wallet_transactions(profile_id,amount,transaction_type,reason)
      values (new.user_id,1,'earn','daily_participation');
  end if;
  return new;
end;
$$;
drop trigger if exists on_daily_interaction_reward on public.daily_interactions;
create trigger on_daily_interaction_reward after insert on public.daily_interactions
for each row execute function public.reward_daily_participation();
alter table public.class_wallets enable row level security;
alter table public.wallet_transactions enable row level security;
drop policy if exists "Students read own wallet" on public.class_wallets;
create policy "Students read own wallet" on public.class_wallets for select to authenticated using (profile_id = (select auth.uid()) or public.is_class_admin());
drop policy if exists "Students read own wallet transactions" on public.wallet_transactions;
create policy "Students read own wallet transactions" on public.wallet_transactions for select to authenticated using (profile_id = (select auth.uid()) or public.is_class_admin());
grant select on public.class_wallets, public.wallet_transactions to authenticated;

create or replace function public.get_my_t_money()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare current_balance integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  insert into public.class_wallets(profile_id) values (auth.uid()) on conflict (profile_id) do nothing;
  select t_money into current_balance from public.class_wallets where profile_id = auth.uid();
  return jsonb_build_object('balance', coalesce(current_balance,0));
end;
$$;
revoke all on function public.get_my_t_money() from public;
grant execute on function public.get_my_t_money() to authenticated;

-- One small reward per game type per student per local calendar date (Asia/Makassar).
create table if not exists public.game_reward_claims (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  game_key text not null check (game_key in ('trivia','fact','words','wordle')),
  reward_date date not null,
  amount integer not null default 1 check (amount > 0),
  created_at timestamptz not null default now(),
  unique(profile_id, game_key, reward_date)
);
alter table public.game_reward_claims enable row level security;
drop policy if exists "Students read own game reward claims" on public.game_reward_claims;
create policy "Students read own game reward claims" on public.game_reward_claims for select to authenticated using (profile_id = (select auth.uid()) or public.is_class_admin());
grant select on public.game_reward_claims to authenticated;

-- Server-side answer keys prevent clients from minting T-Money by calling a reward RPC directly.
create table if not exists public.game_challenge_answers (
  game_key text not null check (game_key in ('trivia','fact','words','wordle')),
  challenge_index integer not null,
  correct_answer text not null,
  primary key (game_key, challenge_index)
);
alter table public.game_challenge_answers enable row level security;
revoke all on public.game_challenge_answers from anon, authenticated;
insert into public.game_challenge_answers(game_key,challenge_index,correct_answer) values
('trivia',0,'1'),('trivia',1,'2'),('trivia',2,'1'),('trivia',3,'2'),('trivia',4,'2'),('trivia',5,'1'),('trivia',6,'0'),('trivia',7,'1'),
('fact',0,'true'),('fact',1,'false'),('fact',2,'true'),('fact',3,'true'),('fact',4,'false'),('fact',5,'true'),('fact',6,'false'),('fact',7,'true'),
('words',0,'JADWAL'),('words',1,'KELAS'),('words',2,'TEMAN'),('words',3,'TUGAS'),('words',4,'DISKUSI'),('words',5,'KARYA'),('words',6,'ACARA'),('words',7,'DATA'),
('wordle',0,'KELAS'),('wordle',1,'BUKU'),('wordle',2,'KARYA'),('wordle',3,'TEMAN')
on conflict (game_key,challenge_index) do update set correct_answer = excluded.correct_answer;

create or replace function public.submit_daily_game_answer(p_game_key text, p_challenge_index integer, p_answer text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare local_day date := (now() at time zone 'Asia/Makassar')::date;
  expected_index integer;
  claim_id uuid;
  current_balance integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_game_key not in ('trivia','fact','words','wordle') then raise exception 'Invalid game'; end if;
  expected_index := case p_game_key
    when 'trivia' then ((local_day - date '1970-01-01') + 18) % 8
    when 'fact' then ((local_day - date '1970-01-01') + 12) % 8
    when 'words' then ((local_day - date '1970-01-01') + 15) % 8
    when 'wordle' then ((local_day - date '1970-01-01') + 18) % 4
  end;
  if p_challenge_index <> expected_index then raise exception 'Challenge sudah berganti'; end if;
  if not exists (select 1 from public.game_challenge_answers a where a.game_key = p_game_key and a.challenge_index = p_challenge_index and upper(trim(a.correct_answer)) = upper(trim(coalesce(p_answer,'')))) then
    raise exception 'Jawaban belum benar';
  end if;
  insert into public.class_wallets(profile_id) values (auth.uid()) on conflict (profile_id) do nothing;
  insert into public.game_reward_claims(profile_id, game_key, reward_date, amount)
    values (auth.uid(), p_game_key, local_day, 1)
    on conflict (profile_id, game_key, reward_date) do nothing
    returning id into claim_id;
  if claim_id is null then
    select t_money into current_balance from public.class_wallets where profile_id = auth.uid();
    return jsonb_build_object('already_claimed', true, 'balance', current_balance, 'amount', 0);
  end if;
  update public.class_wallets set t_money = t_money + 1, updated_at = now() where profile_id = auth.uid() returning t_money into current_balance;
  insert into public.wallet_transactions(profile_id, amount, transaction_type, reason, reference_id)
    values (auth.uid(), 1, 'earn', 'game:' || p_game_key, claim_id);
  return jsonb_build_object('already_claimed', false, 'balance', current_balance, 'amount', 1);
end;
$$;
revoke all on function public.submit_daily_game_answer(text, integer, text) from public;
grant execute on function public.submit_daily_game_answer(text, integer, text) to authenticated;
drop function if exists public.claim_game_reward(text);

-- Small initial cosmetic catalogue. No pay-to-win items.
create table if not exists public.shop_catalog (
  id text primary key,
  name text not null,
  description text not null default '',
  category text not null check (category in ('profile_color','name_color','title_color')),
  price integer not null check (price > 0),
  preview_color text not null,
  text_color text not null,
  preview_label text not null default 'Aa',
  active boolean not null default true
);
insert into public.shop_catalog(id,name,description,category,price,preview_color,text_color,preview_label) values
('profile-mint','Mint Profile','Warna lembut untuk avatar dan aksen profil.','profile_color',8,'#dff7ed','#16734c','M'),
('profile-lavender','Lavender Profile','Nuansa lavender untuk tampilan profil.','profile_color',8,'#eee8ff','#6d4ac2','L'),
('name-ocean','Ocean Name','Warna biru untuk nama tampilan.','name_color',10,'#e5f2ff','#1769c2','Aa'),
('name-rose','Rose Name','Warna rose untuk nama tampilan.','name_color',10,'#fff0f4','#c04470','Aa'),
('title-gold','Golden Title','Aksen emas untuk label profil.','title_color',12,'#fff5d8','#9b6a12','TITLE'),
('title-forest','Forest Title','Aksen hijau untuk label profil.','title_color',12,'#e7f3e7','#326b3e','TITLE')
on conflict (id) do nothing;
alter table public.shop_catalog enable row level security;
drop policy if exists "Members read active shop catalogue" on public.shop_catalog;
create policy "Members read active shop catalogue" on public.shop_catalog for select to authenticated using (active = true or public.is_class_admin());
grant select on public.shop_catalog to authenticated;

create table if not exists public.shop_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  item_id text not null references public.shop_catalog(id),
  price_paid integer not null,
  purchased_at timestamptz not null default now(),
  unique(user_id, item_id)
);
create table if not exists public.student_cosmetics (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  profile_color text,
  name_color text,
  title_color text,
  updated_at timestamptz not null default now()
);
alter table public.shop_purchases enable row level security;
alter table public.student_cosmetics enable row level security;
drop policy if exists "Students read own shop purchases" on public.shop_purchases;
create policy "Students read own shop purchases" on public.shop_purchases for select to authenticated using (user_id = (select auth.uid()) or public.is_class_admin());
drop policy if exists "Students read own cosmetics" on public.student_cosmetics;
create policy "Students read own cosmetics" on public.student_cosmetics for select to authenticated using (profile_id = (select auth.uid()) or public.is_class_admin());
grant select on public.shop_purchases, public.student_cosmetics to authenticated;

create or replace function public.purchase_shop_item(p_item_id text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare item_row public.shop_catalog%rowtype;
  balance_now integer;
  purchase_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select * into item_row from public.shop_catalog where id = p_item_id and active = true;
  if not found then raise exception 'Item tidak tersedia'; end if;
  insert into public.class_wallets(profile_id) values (auth.uid()) on conflict (profile_id) do nothing;
  select t_money into balance_now from public.class_wallets where profile_id = auth.uid() for update;
  if exists(select 1 from public.shop_purchases where user_id = auth.uid() and item_id = p_item_id) then
    raise exception 'Item sudah dimiliki';
  end if;
  if balance_now < item_row.price then raise exception 'T-Money tidak cukup'; end if;
  update public.class_wallets set t_money = t_money - item_row.price, updated_at = now() where profile_id = auth.uid() returning t_money into balance_now;
  insert into public.shop_purchases(user_id,item_id,price_paid) values (auth.uid(),p_item_id,item_row.price) returning id into purchase_id;
  insert into public.wallet_transactions(profile_id,amount,transaction_type,reason,reference_id)
    values (auth.uid(),item_row.price,'spend','shop:' || p_item_id,purchase_id);
  insert into public.student_cosmetics(profile_id) values (auth.uid()) on conflict (profile_id) do nothing;
  if item_row.category = 'profile_color' then
    update public.student_cosmetics set profile_color = item_row.preview_color, updated_at = now() where profile_id = auth.uid();
  elsif item_row.category = 'name_color' then
    update public.student_cosmetics set name_color = item_row.text_color, updated_at = now() where profile_id = auth.uid();
  elsif item_row.category = 'title_color' then
    update public.student_cosmetics set title_color = item_row.text_color, updated_at = now() where profile_id = auth.uid();
  end if;
  return jsonb_build_object('success',true,'message','Item berhasil dibeli. Tampilan kosmetik sudah diperbarui.','balance',balance_now);
end;
$$;
revoke all on function public.purchase_shop_item(text) from public;
grant execute on function public.purchase_shop_item(text) to authenticated;

create or replace function public.equip_shop_item(p_item_id text)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare item_row public.shop_catalog%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select c.* into item_row from public.shop_catalog c
    join public.shop_purchases p on p.item_id = c.id
    where c.id = p_item_id and p.user_id = auth.uid() and c.active = true;
  if not found then raise exception 'Item belum dimiliki atau tidak tersedia'; end if;
  insert into public.student_cosmetics(profile_id) values (auth.uid()) on conflict (profile_id) do nothing;
  if item_row.category = 'profile_color' then
    update public.student_cosmetics set profile_color = item_row.preview_color, updated_at = now() where profile_id = auth.uid();
  elsif item_row.category = 'name_color' then
    update public.student_cosmetics set name_color = item_row.text_color, updated_at = now() where profile_id = auth.uid();
  elsif item_row.category = 'title_color' then
    update public.student_cosmetics set title_color = item_row.text_color, updated_at = now() where profile_id = auth.uid();
  end if;
  return jsonb_build_object('success',true,'message','Kosmetik berhasil dipasang.');
end;
$$;
revoke all on function public.equip_shop_item(text) from public;
grant execute on function public.equip_shop_item(text) to authenticated;
