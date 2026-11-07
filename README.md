# Twogether Class — Supabase-connected starter

## 1. Run locally

Requirements: Node.js 20.19+ or 22.12+.

```bash
cd frontend
npm install
npm run dev
```

Vite prints the local URL (normally http://localhost:5173).

## 2. Supabase setup (one-time)

The frontend `.env.local` is private and intentionally excluded from distributed ZIP files. Copy it from the previous working project or create it from `.env.example`. The publishable key is intended for browser use. Never add a database password, `service_role` key, or secret key to frontend environment variables.

1. Open the Supabase project dashboard.
2. Open **SQL Editor** and create a new query.
3. Copy and run all of `supabase/schema.sql` from this project.
4. Open **Authentication → Users** and create/invite accounts for students and administrators. Login uses email + password; there is no public sign-up form.
5. New accounts are students by default. To grant administrator access, find the user's UUID in Authentication → Users and run this query in SQL Editor, replacing the UUID:

```sql
update public.profiles
set role = 'admin'
where id = 'PASTE-USER-UUID-HERE';
```

Do not give students access to SQL Editor or the Supabase project dashboard.

## 3. What is connected

- Supabase Auth email/password sign-in and persistent sessions.
- `profiles` table for student/admin roles.
- Cloud-backed announcements (admin create/edit/activate/delete; members read active items).
- Cloud-backed subject descriptions and subject activities (admin writes; signed-in members read).
- Row Level Security policies are included in `supabase/schema.sql`.

The timetable is the confirmed weekly XI-B2 schedule. Tasks and class-finance features use Supabase after the additional migration below. Attendance remains a planned feature.

## 4. Environment variables

Use `frontend/.env.example` as the template. Copy it to `frontend/.env.local` only if you do not have the existing private environment file, then fill in:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_PUBLISHABLE_KEY`

Vite exposes `VITE_` variables to the browser, so only public/publishable values belong here.

## 5. Deployment

When deploying, add the same two environment variables in the hosting provider's project settings. Add the deployed website URL to Supabase **Authentication → URL Configuration → Site URL / Redirect URLs**.

## Important

- Keep `.env.local` private and do not commit it to Git. It is excluded by `.gitignore`.
- The publishable key alone does not secure data. The SQL policies are essential.
- Free Supabase projects have usage limits and may pause after inactivity. Check the current Supabase pricing page for current limits.


## Shared calendar migration

After the original `supabase/schema.sql` has been applied, run `supabase/migrations/20261105_calendar.sql` in Supabase SQL Editor to enable the shared calendar. This migration adds calendar events, moderation requests, reactions, and private personal date markers. It does not replace existing tables.

## Official XI-B2 timetable

The Home schedule now uses the confirmed recurring Monday-Saturday timetable. The class timetable is static in `frontend/src/data/items.js`; update that file only if the school timetable changes.

## Tasks and class finances migration

After the calendar migration has already been applied, run this migration once in Supabase SQL Editor:

`supabase/migrations/20261106_tasks_finance.sql`

It adds moderated class tasks, cash payment submissions and ledger, monthly cash allocations (Rp20,000/month, oldest unpaid month first), class expenses with an audit trail, campaign-based class contributions, and private storage for payment proofs. Do not rerun the original schema or the calendar migration.

The cash monthly table lists accounts currently present in `profiles`. The 43-person roster will be fully represented after all student accounts are created and mapped to their profiles. The frontend intentionally does not invent or seed student account identities.

## Environment file when moving to a fresh folder

`.env.local` is intentionally excluded from ZIP files. Copy `frontend/.env.local` from your previous working project into the new extracted project's `frontend/` folder. If you no longer have it, copy `.env.example` to `.env.local` and enter the same Supabase Project URL and publishable key. Never use a service-role or secret key in the frontend.

The QRIS image is expected at `frontend/public/assets/qris-payment.png`. Add the class QRIS image there. Student QRIS submissions also require an uploaded proof image; proof files are stored in the private `class-finance-proofs` Supabase Storage bucket.


### Update fitur tugas dan menu kelas

Migration `20261107_task_access_and_explore.sql` pernah menambahkan akses agar siswa bisa membuat tugas langsung. Untuk mengembalikan alur persetujuan admin, jalankan migration baru `supabase/migrations/20261108_task_approval_required.sql` satu kali di Supabase SQL Editor setelah migration sebelumnya. Setelah itu, pengajuan tugas baru dari siswa akan masuk ke antrean Admin Power dan baru diterbitkan setelah disetujui. Tugas yang dibuat admin tetap langsung tampil.

Menu Uang Kas dan Iuran Kelas kini tersedia langsung di menu profil. Piket Kelas, Arsip Kelas, serta Student Titles & Badges juga ditampilkan sebagai fitur yang akan datang. Halaman perantara Jelajahi sudah tidak digunakan.

## Community, mini-games, T-Money and PWA update

This project update adds Daily Discovery & Events, Discover Students, four mini-games, a starter Reward Shop with T-Money cosmetics, and PWA installation support. AFK Farming / Dosman Mining Simulator is intentionally not included.

After all previously required migrations have been applied, run this new migration once in Supabase SQL Editor:

`supabase/migrations/20261114_community_games_rewards_pwa.sql`

The migration adds opt-in Discover Students visibility, private/moderated daily responses, aggregate poll results, capped T-Money rewards, server-validated daily game answer rewards, and cosmetic shop purchases. Do not skip earlier migrations. The SQL migration is not applied automatically by Cloudflare Pages.

Daily content templates are in `frontend/src/data/dailyContent.js`. The initial template bank includes 30 announcement templates, 20 daily event prompts, 20 Random Questions, 15 polls and 15 This-or-That prompts. Daily content rotates using the Asia/Makassar date. Existing active announcements and upcoming subject activities are used when available.

The PWA manifest and service worker are included. The service worker caches only the app shell and static assets; personal information and Supabase responses are not cached. Online features still require an internet connection. iPhone/iPad users install through Safari Share → Add to Home Screen.

See `UPDATE_20261114_COMMUNITY_GAMES_REWARDS.md` for the detailed feature list and setup notes.
