-- Twogether Class: allow students to publish newly created tasks immediately.
-- Existing student edit/delete requests still require admin review.

drop policy if exists "Members create own class tasks" on public.class_tasks;
create policy "Members create own class tasks"
on public.class_tasks
for insert to authenticated
with check (created_by = (select auth.uid()));

grant insert on public.class_tasks to authenticated;
