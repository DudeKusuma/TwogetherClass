-- Twogether Class: student-created tasks must be approved by an admin before publication.
-- Admins retain insert access through the existing "Admins manage class tasks" policy.

drop policy if exists "Members create own class tasks" on public.class_tasks;
