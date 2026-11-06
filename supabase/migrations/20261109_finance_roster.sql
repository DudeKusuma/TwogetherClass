-- XI B2 finance roster and student-visible approved contribution totals.
-- Safe to apply after 20261106_tasks_finance.sql; this migration is idempotent.
create table if not exists public.class_roster (
  attendance_number integer primary key check (attendance_number between 1 and 43),
  student_number text not null unique,
  full_name text not null,
  gender text not null check (gender in ('L','P')),
  profile_id uuid unique references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table public.class_roster enable row level security;
drop policy if exists "Members read XI B2 roster" on public.class_roster;
create policy "Members read XI B2 roster" on public.class_roster
  for select to authenticated using (true);
drop policy if exists "Admins manage XI B2 roster" on public.class_roster;
create policy "Admins manage XI B2 roster" on public.class_roster
  for all to authenticated using (public.is_class_admin()) with check (public.is_class_admin());
grant select, insert, update, delete on public.class_roster to authenticated;

insert into public.class_roster (attendance_number, student_number, full_name, gender) values
(1,'16267','Anak Agung Gde Rai Surya Maha Natha','L'),
(2,'16618','Anak Agung Istri Candra Prameswari','P'),
(3,'16463','Ayu Amira Pita Loka','P'),
(4,'16385','Dandy Varenza Hendrawan','L'),
(5,'16465','Dewa Ayu Indira Laksmidewi','P'),
(6,'16388','Dewa Ayu Indira Parameswari','P'),
(7,'16427','Dewa Ayu Sevia Ecy Dela Putri','P'),
(8,'16428','Dewa Gede Askara Wahyu','L'),
(9,'16504','Dewa Made Satria Riski','L'),
(10,'16622','Dude Kusuma Putra','L'),
(11,'16506','I Dewa Nyoman Wahyu Pratyahara Putra','L'),
(12,'16509','I Gusti Agung Gde Advira Narayana','L'),
(13,'16593','I Gusti Ayu Anindya Praba','P'),
(14,'16393','I Gusti Bagus Dias Devananda','L'),
(15,'16550','I Kadek Arie Widiantara Putra','L'),
(16,'16629','I Made Ary Kusuma Wardana','L'),
(17,'16630','I Made Teja Puspa Anom','L'),
(18,'16631','Ida Ayu Anggita Adi Laksmi','P'),
(19,'16561','Kadek Cantika Astari Ningsih','P'),
(20,'16331','Kadek Dea Aprilia Santi','P'),
(21,'16445','Luh Putu Aprilia Cahyanti','P'),
(22,'16636','Ni Kadek Davina Anandika Kumara','P'),
(23,'16608','Ni Kadek Reifa Anjani','P'),
(24,'16296','Ni Kadek Widya Priyani','P'),
(25,'16532','Ni Komang Risma Ariyanti','P'),
(26,'16370','Ni Made Anggita Febrianti','P'),
(27,'16489','Ni Made Bunga Khania Wijaya','P'),
(28,'16570','Ni Made Jyotisa Indah Kirani','P'),
(29,'16490','Ni Nyoman Ayu Pramesti Savitriani Dewi','P'),
(30,'16536','Ni Nyoman Wilasitha Ari Komala','P'),
(31,'16613','Ni Putu Calista Putri','P'),
(32,'16372','Ni Putu Gex Sintya Wulandari','P'),
(33,'16373','Ni Putu Louisa Anastasya Maheswari','P'),
(34,'16615','Ni Putu Nadiana Sasmita','P'),
(35,'16574','Ni Wayan Rania Cahya Kumari','P'),
(36,'16300','Pande Komang Bella Sriastarini','P'),
(37,'16301','Pande Made Alea Kamallapatra Kezia S.','P'),
(38,'16576','Pande Putu Agus Cahya Nugraha','L'),
(39,'16495','Pande Putu Ratih Widya Paramitha','P'),
(40,'16458','Putu Ayu Elsa Komala Dewi','P'),
(41,'16500','Putu Sadhu Namarupa Ananta Wiguna','L'),
(42,'16578','Putu Tania Devita Putri','P'),
(43,'16344','Putu Vania Ayu Indirasari','P')
on conflict (attendance_number) do update set
  student_number=excluded.student_number,
  full_name=excluded.full_name,
  gender=excluded.gender,
  updated_at=now();

-- Preserve any existing attendance-number links, and automatically link accounts already tagged.
update public.class_roster r set profile_id=p.id
from public.profiles p
where p.attendance_number=r.attendance_number and p.role='student' and r.profile_id is null;

-- Students may see approved payments from classmates for accurate shared progress,
-- but pending/rejected submissions remain private to their owner and administrators.
drop policy if exists "Read own contribution payments or admin" on public.contribution_payments;
create policy "Read approved contribution payments or own or admin" on public.contribution_payments
  for select to authenticated
  using (status='approved' or student_id=(select auth.uid()) or public.is_class_admin());
