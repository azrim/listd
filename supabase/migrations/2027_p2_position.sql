-- P2: position (real) + manuallyAddedToToday (is_my_day)
--
-- Run this migration BEFORE merging the Flutter PR so that the
-- Supabase schema matches the new Drift schema on first sync.

-- 1. Change position from integer to real for fractional insertion.
alter table public.tasks alter column position type real;

-- 2. Ensure is_my_day exists (maps to manuallyAddedToToday in Drift).
--    This column may already exist from the original schema.
alter table public.tasks add column if not exists is_my_day boolean not null default false;

-- 3. Backfill position for any rows still at 0 or null.
update public.tasks
set position = sub.new_pos
from (
  select id,
         1024.0 * row_number() over (
           partition by task_list_id
           order by created_at
         ) as new_pos
  from public.tasks
) sub
where public.tasks.id = sub.id
  and (public.tasks.position is null or public.tasks.position = 0);
