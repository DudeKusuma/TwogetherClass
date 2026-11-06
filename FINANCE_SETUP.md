# Twogether Class — Uang Kas & Iuran Kelas

## Implemented in this update

- Uang Kas monthly ledger for the 43 XI B2 students, with a horizontally scrollable table and sticky student identity column.
- Monthly dues default to Rp20.000; partial payments accumulate and approved excess is allocated oldest-month-first by the existing database trigger.
- QRIS and cash payment submissions remain pending until an administrator approves them. QRIS proof uploads use the private `class-finance-proofs` storage bucket.
- Cash balance and transaction history use the database ledger. Admin expense create/edit/delete is retained with the existing audit trigger.
- Iuran Kelas campaigns can be created and closed by admins. Students can submit QRIS/cash payments; approved totals drive campaign progress and each campaign shows all 43 roster rows.
- Closed campaigns remain available in the history view.
- Admins can link each class roster entry to its student's existing Supabase profile. This is necessary because payment rows use authenticated profile UUIDs, while the attendance sheet contains school student numbers and attendance numbers.

## Supabase migration

New migration: `supabase/migrations/20261109_finance_roster.sql`.

It creates and seeds `public.class_roster` with the 43 names and school student numbers transcribed from the supplied attendance photos. It also adds the profile link field and changes the Iuran payment read policy so all class members can see **approved** contributions for accurate shared progress, while pending/rejected submissions remain visible only to their owner and admins.

Before applying it, verify that the existing finance migration has already created `cash_payments`, `cash_monthly_allocations`, `cash_settings`, `class_contributions`, and `contribution_payments`. Do not rerun the entire migration folder blindly. If these tables are missing, check the Supabase migration history and apply the missing earlier migration(s) in order before this one.

Apply only `20261109_finance_roster.sql` in Supabase SQL Editor after confirming its prerequisites exist.

## Account linking

After the migration is applied, sign in with an administrator account and open either Uang Kas or Iuran Kelas. In **Hubungkan akun siswa**, select the correct existing student account for each attendance number. One profile can only be linked to one roster row. This does not create accounts or change passwords.

Students can then submit payments with their own authenticated account; payment ownership is enforced by RLS. A payment affects the ledger/progress only after admin approval.

## QRIS image

The UI includes a placeholder because the actual class QRIS image has not been supplied yet. When ready, place it at `frontend/public/assets/qris-payment.png` and update the placeholder to display it.
