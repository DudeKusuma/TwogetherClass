-- Twogether Class: tasks, cash fund, class contributions
-- Run once in Supabase SQL Editor after 20261105_calendar.sql.

create table if not exists public.class_tasks (
  id uuid primary key default gen_random_uuid(),
  subject_key text not null,
  title text not null,
  description text not null default '',
  assigned_date date not null default current_date,
  deadline date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.task_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid references public.class_tasks(id) on delete set null,
  request_type text not null check (request_type in ('add','edit','delete')),
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  rejection_reason text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  check (status <> 'rejected' or length(trim(coalesce(rejection_reason,''))) > 0)
);
create index if not exists class_tasks_subject_deadline_idx on public.class_tasks(subject_key, deadline);
create index if not exists task_requests_status_idx on public.task_requests(status, created_at desc);
alter table public.class_tasks enable row level security;
alter table public.task_requests enable row level security;
drop policy if exists "Members read class tasks" on public.class_tasks;
create policy "Members read class tasks" on public.class_tasks for select to authenticated using (true);
drop policy if exists "Admins manage class tasks" on public.class_tasks;
create policy "Admins manage class tasks" on public.class_tasks for all to authenticated using (public.is_class_admin()) with check (public.is_class_admin());
drop policy if exists "Read own task requests or admin" on public.task_requests;
create policy "Read own task requests or admin" on public.task_requests for select to authenticated using (requester_id = (select auth.uid()) or public.is_class_admin());
drop policy if exists "Submit own task requests" on public.task_requests;
create policy "Submit own task requests" on public.task_requests for insert to authenticated with check (requester_id = (select auth.uid()) and status = 'pending');
drop policy if exists "Admins review task requests" on public.task_requests;
create policy "Admins review task requests" on public.task_requests for update to authenticated using (public.is_class_admin()) with check (public.is_class_admin());

create or replace function public.apply_task_request()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if old.status = 'pending' and new.status = 'approved' then
  if new.request_type = 'add' then
   insert into public.class_tasks(subject_key,title,description,assigned_date,deadline,created_by)
   values(new.payload->>'subject_key',new.payload->>'title',coalesce(new.payload->>'description',''),coalesce(nullif(new.payload->>'assigned_date','')::date,current_date),nullif(new.payload->>'deadline','')::date,new.requester_id);
  elsif new.request_type = 'edit' then
   update public.class_tasks set subject_key=new.payload->>'subject_key',title=new.payload->>'title',description=coalesce(new.payload->>'description',''),assigned_date=coalesce(nullif(new.payload->>'assigned_date','')::date,assigned_date),deadline=nullif(new.payload->>'deadline','')::date,updated_at=now()
   where id=new.task_id and created_by=new.requester_id;
   if not found then raise exception 'Only the task creator can request edits'; end if;
  elsif new.request_type = 'delete' then
   delete from public.class_tasks where id=new.task_id and created_by=new.requester_id;
   if not found then raise exception 'Only the task creator can request deletion'; end if;
  end if;
 end if;
 return new;
end; $$;
drop trigger if exists apply_approved_task_request on public.task_requests;
create trigger apply_approved_task_request after update of status on public.task_requests for each row execute function public.apply_task_request();
grant select, insert, update, delete on public.class_tasks to authenticated;
grant select, insert, update on public.task_requests to authenticated;

do $$ begin
 if exists (select 1 from pg_publication where pubname='supabase_realtime') then
  if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='task_requests') then alter publication supabase_realtime add table public.task_requests; end if;
 end if;
end $$;

-- Cash fund: payment submissions are pending until admin approval. Approved money movements
-- are recorded as immutable ledger rows; expense edits/deletes are represented by audit rows.
create table if not exists public.cash_payments (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id), amount bigint not null check(amount > 0), method text not null check(method in ('qris','cash')), paid_at timestamptz not null default now(), proof_path text, status text not null default 'pending' check(status in ('pending','approved','rejected')), submitted_at timestamptz not null default now(), reviewed_by uuid references public.profiles(id), reviewed_at timestamptz, rejection_reason text,
 check(status <> 'rejected' or length(trim(coalesce(rejection_reason,''))) > 0)
);
create table if not exists public.cash_expenses (
 id uuid primary key default gen_random_uuid(), title text not null, amount bigint not null check(amount > 0), description text not null default '', spent_at date not null default current_date, receipt_path text, created_by uuid references public.profiles(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.cash_ledger (
 id uuid primary key default gen_random_uuid(), entry_type text not null check(entry_type in ('income','expense')), payment_id uuid references public.cash_payments(id), expense_id uuid references public.cash_expenses(id), student_id uuid references public.profiles(id), amount bigint not null check(amount > 0), description text not null, occurred_at timestamptz not null default now(), created_at timestamptz not null default now()
);
create table if not exists public.cash_expense_audit (
 id uuid primary key default gen_random_uuid(), expense_id uuid, action text not null check(action in ('create','update','delete')), before_data jsonb, after_data jsonb, actor_id uuid references public.profiles(id), created_at timestamptz not null default now()
);
alter table public.cash_payments enable row level security;
alter table public.cash_expenses enable row level security;
alter table public.cash_ledger enable row level security;
alter table public.cash_expense_audit enable row level security;
drop policy if exists "Students read own cash payments and admins all" on public.cash_payments;
create policy "Students read own cash payments and admins all" on public.cash_payments for select to authenticated using(student_id=(select auth.uid()) or public.is_class_admin());
drop policy if exists "Students submit own cash payments" on public.cash_payments;
create policy "Students submit own cash payments" on public.cash_payments for insert to authenticated with check(student_id=(select auth.uid()) and status='pending');
drop policy if exists "Admins review cash payments" on public.cash_payments;
create policy "Admins review cash payments" on public.cash_payments for update to authenticated using(public.is_class_admin()) with check(public.is_class_admin());
drop policy if exists "Members read cash expenses" on public.cash_expenses;
create policy "Members read cash expenses" on public.cash_expenses for select to authenticated using(true);
drop policy if exists "Admins manage cash expenses" on public.cash_expenses;
create policy "Admins manage cash expenses" on public.cash_expenses for all to authenticated using(public.is_class_admin()) with check(public.is_class_admin());
drop policy if exists "Members read cash ledger" on public.cash_ledger;
create policy "Members read cash ledger" on public.cash_ledger for select to authenticated using(true);
drop policy if exists "Admins read expense audit" on public.cash_expense_audit;
create policy "Admins read expense audit" on public.cash_expense_audit for select to authenticated using(public.is_class_admin());

grant select, insert, update on public.cash_payments to authenticated;
grant select, insert, update, delete on public.cash_expenses to authenticated;
grant select on public.cash_ledger, public.cash_expense_audit to authenticated;

create or replace function public.record_approved_cash_payment()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if old.status <> 'approved' and new.status = 'approved' then
  insert into public.cash_ledger(entry_type,payment_id,student_id,amount,description,occurred_at)
  values('income',new.id,new.student_id,new.amount,case when new.method='cash' then 'Pembayaran kas tunai' else 'Pembayaran kas QRIS' end,new.paid_at);
 end if;
 return new;
end; $$;
drop trigger if exists record_cash_payment_approval on public.cash_payments;
create trigger record_cash_payment_approval after update of status on public.cash_payments for each row execute function public.record_approved_cash_payment();

create or replace function public.audit_cash_expense()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if tg_op='INSERT' then
  insert into public.cash_ledger(entry_type,expense_id,amount,description,occurred_at) values('expense',new.id,new.amount,new.title,new.spent_at::timestamptz);
  insert into public.cash_expense_audit(expense_id,action,after_data,actor_id) values(new.id,'create',to_jsonb(new),auth.uid()); return new;
 elsif tg_op='UPDATE' then
  update public.cash_ledger set amount=new.amount,description=new.title,occurred_at=new.spent_at::timestamptz where expense_id=new.id;
  insert into public.cash_expense_audit(expense_id,action,before_data,after_data,actor_id) values(new.id,'update',to_jsonb(old),to_jsonb(new),auth.uid()); return new;
 else
  delete from public.cash_ledger where expense_id=old.id;
  insert into public.cash_expense_audit(expense_id,action,before_data,actor_id) values(old.id,'delete',to_jsonb(old),auth.uid()); return old;
 end if;
end; $$;
drop trigger if exists audit_cash_expense_changes on public.cash_expenses;
create trigger audit_cash_expense_changes after insert or update or delete on public.cash_expenses for each row execute function public.audit_cash_expense();

-- Class contributions are campaign-based and remain queryable after a campaign closes.
create table if not exists public.class_contributions (
 id uuid primary key default gen_random_uuid(), title text not null, description text not null default '', period_label text not null, target_amount bigint not null check(target_amount>0), deadline date, status text not null default 'active' check(status in ('active','closed')), created_by uuid references public.profiles(id), created_at timestamptz not null default now()
);
create table if not exists public.contribution_payments (
 id uuid primary key default gen_random_uuid(), contribution_id uuid not null references public.class_contributions(id), student_id uuid not null references public.profiles(id), amount bigint not null check(amount>0), method text not null check(method in ('qris','cash')), proof_path text, paid_at timestamptz not null default now(), status text not null default 'pending' check(status in ('pending','approved','rejected')), submitted_at timestamptz not null default now(), reviewed_by uuid references public.profiles(id), reviewed_at timestamptz, rejection_reason text, check(status<>'rejected' or length(trim(coalesce(rejection_reason,'')))>0)
);
alter table public.class_contributions enable row level security;
alter table public.contribution_payments enable row level security;
drop policy if exists "Members read class contributions" on public.class_contributions;
create policy "Members read class contributions" on public.class_contributions for select to authenticated using(true);
drop policy if exists "Admins manage class contributions" on public.class_contributions;
create policy "Admins manage class contributions" on public.class_contributions for all to authenticated using(public.is_class_admin()) with check(public.is_class_admin());
drop policy if exists "Read own contribution payments or admin" on public.contribution_payments;
create policy "Read own contribution payments or admin" on public.contribution_payments for select to authenticated using(student_id=(select auth.uid()) or public.is_class_admin());
drop policy if exists "Submit own contribution payments" on public.contribution_payments;
create policy "Submit own contribution payments" on public.contribution_payments for insert to authenticated with check(student_id=(select auth.uid()) and status='pending');
drop policy if exists "Admins review contribution payments" on public.contribution_payments;
create policy "Admins review contribution payments" on public.contribution_payments for update to authenticated using(public.is_class_admin()) with check(public.is_class_admin());
grant select, insert, update, delete on public.class_contributions to authenticated;
grant select, insert, update on public.contribution_payments to authenticated;

-- Monthly cash allocation: partial payments accumulate, and excess rolls forward
-- into the oldest unpaid month first. The class can change start_month if needed.
create table if not exists public.cash_settings (
 id boolean primary key default true check(id),
 start_month date not null default date_trunc('month', current_date)::date,
 monthly_due bigint not null default 20000 check(monthly_due>0)
);
insert into public.cash_settings(id) values(true) on conflict(id) do nothing;
create table if not exists public.cash_monthly_allocations (
 id uuid primary key default gen_random_uuid(), payment_id uuid not null references public.cash_payments(id) on delete cascade,
 student_id uuid not null references public.profiles(id) on delete cascade, month_start date not null, amount bigint not null check(amount>0), created_at timestamptz not null default now(), unique(payment_id,month_start)
);
create index if not exists cash_monthly_student_month_idx on public.cash_monthly_allocations(student_id,month_start);
alter table public.cash_settings enable row level security;
alter table public.cash_monthly_allocations enable row level security;
drop policy if exists "Members read cash settings" on public.cash_settings;
create policy "Members read cash settings" on public.cash_settings for select to authenticated using(true);
drop policy if exists "Members read monthly cash allocations" on public.cash_monthly_allocations;
create policy "Members read monthly cash allocations" on public.cash_monthly_allocations for select to authenticated using(true);
grant select on public.cash_settings, public.cash_monthly_allocations to authenticated;

create or replace function public.record_approved_cash_payment()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
 v_remaining bigint;
 v_month date;
 v_due bigint;
 v_paid bigint;
 v_chunk bigint;
 v_i integer := 0;
begin
 if old.status <> 'approved' and new.status = 'approved' then
  insert into public.cash_ledger(entry_type,payment_id,student_id,amount,description,occurred_at)
  values('income',new.id,new.student_id,new.amount,case when new.method='cash' then 'Pembayaran kas tunai' else 'Pembayaran kas QRIS' end,new.paid_at);
  select start_month,monthly_due into v_month,v_due from public.cash_settings where id=true;
  v_remaining := new.amount;
  while v_remaining > 0 and v_i < 120 loop
   select coalesce(sum(amount),0) into v_paid from public.cash_monthly_allocations where student_id=new.student_id and month_start=v_month;
   if v_paid < v_due then
    v_chunk := least(v_remaining, v_due-v_paid);
    insert into public.cash_monthly_allocations(payment_id,student_id,month_start,amount) values(new.id,new.student_id,v_month,v_chunk);
    v_remaining := v_remaining-v_chunk;
   end if;
   v_month := (v_month + interval '1 month')::date;
   v_i := v_i+1;
  end loop;
 end if;
 return new;
end; $$;

-- Private receipt storage for QRIS payment proofs and optional expense receipts.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('class-finance-proofs','class-finance-proofs',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
drop policy if exists "Members upload own finance proofs" on storage.objects;
create policy "Members upload own finance proofs" on storage.objects for insert to authenticated
with check(bucket_id='class-finance-proofs' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "Owners and admins read finance proofs" on storage.objects;
create policy "Owners and admins read finance proofs" on storage.objects for select to authenticated
using(bucket_id='class-finance-proofs' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_class_admin()));
drop policy if exists "Owners and admins delete finance proofs" on storage.objects;
create policy "Owners and admins delete finance proofs" on storage.objects for delete to authenticated
using(bucket_id='class-finance-proofs' and ((storage.foldername(name))[1]=auth.uid()::text or public.is_class_admin()));

-- Optional class attendance number used by finance rosters.
alter table public.profiles add column if not exists attendance_number integer;
create unique index if not exists profiles_attendance_number_unique on public.profiles(attendance_number) where attendance_number is not null;
