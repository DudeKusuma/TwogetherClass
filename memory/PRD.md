# Twogether Class — PRD

## Original problem statement
Frontend-only class portal "Twogether Class" for XI-B2, SMA Negeri 1 Gianyar. Vue 3 + Vite + JS + Composition API (`<script setup>`) + Vue Router + Pinia + plain CSS. localStorage/sessionStorage only. Demo auth (student/123, admin/123) in sessionStorage `tc_auth`. Home: exactly 3 sections (greeting, subject cards, horizontal staggered timeline). 16:00 rollover, Saturday→Monday. Admin announcements (localStorage), student popup + dismissals (sessionStorage `tc_dismissed_announcements`). Admin Power only in profile drawer for admin. Placeholders for schedule/tasks/attendance/profile/explore/detail; About page. Light mode only.

## User choices
- UI language: full Bahasa Indonesia (nav label "Home" kept)
- Greeting names: "Student" / "Admin"
- Logo: supplied (`logo XI B2.jpeg`) — used

## Architecture
- /app/frontend = Vite + Vue 3 app (`yarn start` → vite dev on :3000). No backend used.
- Stores: useAuthStore, useAnnouncementStore, useScheduleStore (+ minimal unused useFavoritesStore)
- Composables: useSchoolDay, useGreeting (+ minimal unused useItemFilter)
- Data: src/data/items.js (`dummyTimetable`, DUMMY label), src/data/subjects.js (icon mapping)

## Implemented (2026-06)
- All routes + auth guards, redirect handling, 404
- Header, notification panel/badge, profile drawer w/ admin-only Admin Power, bottom nav / desktop rail
- Home 3 sections, timeline (time-accurate positioning, breaks, now line, current highlight, auto-scroll)
- Admin announcement CRUD + activation; student popup + dismissal
- Tested via testing agent (iteration_1: 100% pass), build passes

## Revision 2 (2026-06)
- Subject cards redesigned: pastel header only, white body; clickable -> SubjectDetailModal (description + activities)
- Admin Power landing (/admin-power) with Pengumuman, Jadwal Besok, Deskripsi Mapel
- useSubjectStore: tc_subject_descriptions, tc_subject_activities (localStorage)
- Tested: iteration_2 100% pass

## Backlog
- P0: Official XI-B2 timetable, teacher names, assignment data
- P1: Schedule calendar, Tasks, Attendance (43-seat plan) features
- P2: Profile page content, Explore content
