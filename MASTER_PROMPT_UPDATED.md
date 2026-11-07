# MASTER PROMPT — TWogether Class (Update 14 November 2026)

Continue the existing Twogether Class project. Do not rebuild it from scratch. Preserve all working features, data, authentication, finance records, and existing RLS rules. The project uses Vue 3, Vite, Supabase Auth/Database, and Cloudflare Pages. Frontend root is `frontend`; build command is `npm run build`; output is `dist`.

## Scope of this update

- Daily Discovery & Events, including rotating templates, Random Question, Class Polling and This-or-That.
- Discover Students with explicit student opt-in.
- Mini-games: Class Trivia, Fact or Myth, Word Scramble and Daily Word.
- T-Money wallet and a small cosmetic Reward Shop.
- PWA installation support for Android, desktop browsers and iPhone Safari instructions.
- No Dosman Mining Simulator / AFK Farming implementation. That is a separate deferred project. Anonymous Letters, Nomination & Appreciation, and the first-time interactive guide are also deferred until their detailed behavior is finalized.

## Important decisions

- Daily content rotates automatically by Bali local date (Asia/Makassar). The initial template bank is 30 announcements, 20 event prompts, 20 Random Questions, 15 polls and 15 This-or-That prompts.
- Active admin announcements and upcoming subject activities take priority over generic rotating fallback copy.
- Random Question is voluntary. Responses can be Private, submitted for Anonymous display, or submitted with Nickname. Public submissions are pending until an admin approves them. Never auto-publish unmoderated answers.
- Students appear in Discover Students only after explicitly enabling the opt-in switch in Profile > Privacy Settings. Never expose NIS/student number, address, or birth date in the directory.
- Games rotate one challenge per game each Bali local day. Server-side answer keys validate game reward claims. Each game pays at most 1 T-Money per student per day.
- First daily community response pays at most 1 T-Money per student per Bali local day. Each of the four mini-games can pay at most 1 T-Money per student per Bali local day after server-side answer validation (maximum 5 T-Money/day from these activities). No repeated reward farming.
- Reward Shop starts small with profile color, display-name color, and title color cosmetics. Cosmetics are visual only and do not affect academic or game advantage.
- T-Money and purchases are handled by database functions. Do not accept client-supplied wallet balances or prices as authoritative.
- PWA service worker caches only static app-shell assets. Do not cache Supabase auth, personal information, or database responses. Online features still need internet.
- Presensi is removed from the main navigation and remains accessible from the profile drawer. Do not delete the attendance page or its data.

## Database migration

Run `supabase/migrations/20261114_community_games_rewards_pwa.sql` after all earlier migrations. Do not assume deployment applies SQL automatically.

## Safety / security

- Never request or expose Supabase service-role keys.
- Preserve RLS and use security-definer RPCs with restricted grants for wallet rewards and purchases.
- Keep private responses private; only approved anonymous/nickname submissions may be returned for display.
- Keep T-Money rewards capped and prevent duplicate claims.
- Do not implement AFK/offline mining or passive currency in this project update.

## Working style

Make incremental changes, inspect existing source before editing, preserve existing behavior, and run build/tests when dependencies are available. Be transparent about unverified SQL execution, builds, deployments, or live Supabase behavior. Provide complete migration files and clear manual setup instructions when database changes are needed.
