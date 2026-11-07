# Twogether Class — Update Community, Games, Rewards & PWA

This update extends the existing Vue 3 + Vite + Supabase project. It does not include Dosman Mining Simulator / AFK Farming.

## Included

- Daily Discovery & Events page (`/daily`): date-based rotation of 20 Random Questions, 15 Class Polls, 15 This-or-That prompts, 30 announcement templates and 20 event prompts. Existing active admin announcements and upcoming subject activities take priority over fallback templates.
- Random Question responses: optional, max 500 characters, with Private / Submit Anonymously / Submit With Nickname choices. Public submissions remain pending until an admin approves them. Private answers are not shown publicly.
- Admin moderation page (`/admin-power/daily-moderation`).
- Discover Students page (`/discover`): searchable and interest-filtered directory. Students must opt in from Profile > Privacy Settings. The directory does not expose student numbers, addresses, or birth dates.
- Four daily mini-games (`/games`): Class Trivia, Fact or Myth, Word Scramble and Daily Word. Challenge selection rotates by the Bali local date. Server-side answer keys validate reward claims. Each game can grant at most 1 T-Money per student per day.
- First daily community submission can grant 1 T-Money per student per Bali local day. Each of the four mini-games can grant 1 additional T-Money per day after server-side answer validation (maximum 5 T-Money/day from these activities). A database unique key prevents repeated daily participation rewards.
- Initial Reward Shop (`/shop`): profile color, display-name color and title color cosmetics. Six starter items. Purchases are processed in a database function with wallet locking and purchase history.
- T-Money balance card on Home and wallet balance on Reward Shop.
- PWA installation support: manifest, icons, service worker, Android/Desktop install prompt and iPhone Safari Add to Home Screen instructions.
- Main navigation replaces Presensi with Discover. Presensi remains accessible from the profile drawer.
- About page updated with the general project description.

## Supabase setup required

Before using the new community, game rewards, and shop features, run:

`supabase/migrations/20261114_community_games_rewards_pwa.sql`

in Supabase Dashboard → SQL Editor. Existing migrations must already have been applied. The new migration does not replace previous schema migrations.

The frontend uses only the existing `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` environment variables. Never put a service-role key in frontend code.

## Notes / limitations

- The new UI expects the migration to be applied. If it is not applied, the new pages display setup messages rather than silently pretending data was saved.
- PWA caching is limited to the app shell and static same-origin assets. Supabase data, auth sessions and personal information are not cached by the service worker. Features that need Supabase still require an internet connection.
- On iPhone/iPad, installation is a manual Safari Share → Add to Home Screen flow; iOS does not use the same browser install prompt as Chromium.
- Daily templates are stored in `frontend/src/data/dailyContent.js` and can be expanded later. The initial bank is intentionally moderate because student-generated responses create much of the interaction.
- T-Money rewards are deliberately small and capped. No AFK Farming, passive offline currency, paid random rewards or pay-to-win shop items are included. Anonymous Letters, Nomination & Appreciation, and the first-time interactive guide remain outside this implementation batch and should be added only after their final interaction/moderation details are agreed.
- Random Question public responses are not published automatically. An admin must approve them first.

## Build / deploy

- Frontend root: `frontend`
- Build command: `npm run build`
- Build output: `dist`
- Cloudflare Pages root directory: `frontend`
- Supabase SQL migrations are run separately; deployment does not apply them automatically.


## Validation status

- Vue single-file component parsing/template compilation passed for all 44 `.vue` files in the source tree.
- JavaScript syntax checks and manifest/package JSON parsing passed.
- The full Vite production build could not be completed in the preparation environment because the supplied `node_modules` snapshot is missing the platform-specific Rolldown native binding. The ZIP intentionally excludes `node_modules`; after extracting, run `npm install` inside `frontend`, then `npm run build`.
- The Supabase migration has not been executed against the live project database. Run it in the Supabase SQL Editor and verify the new pages while logged in before deploying.
