-- Fix: ensure chat_rooms.room_id is populated so roommates (same room) can access chat
-- and make access resilient.

-- 1) Backfill chat_rooms.room_id/dormitory_id from repairs or dormitory_members when missing
update public.chat_rooms cr
set room_id = r.room_id
from public.repairs r
where cr.room_id is null
  and r.id = cr.repair_id
  and r.room_id is not null;

update public.chat_rooms cr
set room_id = dm.room_id,
    dormitory_id = coalesce(cr.dormitory_id, dm.dormitory_id)
from public.dormitory_members dm
where cr.room_id is null
  and dm.user_id = (
    select r.user_id from public.repairs r where r.id = cr.repair_id limit 1
  )
  and dm.status = 'approved';

-- 2) Replace access function/policies to also allow any approved member in same room_id
create or replace function public.can_access_chat_room(p_chat_room_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from chat_rooms cr
    where cr.id = p_chat_room_id
      and (
        exists (
          select 1 from dormitory_members dm
          where dm.user_id = auth.uid()
            and dm.room_id is not null
            and dm.room_id = cr.room_id
            and dm.status = 'approved'
        )
        or exists (
          select 1 from dormitories d
          where d.id = cr.dormitory_id
            and d.created_by = auth.uid()
        )
      )
  );
$$;

revoke all on function public.can_access_chat_room(uuid) from public;
grant execute on function public.can_access_chat_room(uuid) to anon, authenticated, service_role;

drop policy if exists chat_rooms_select on public.chat_rooms;
create policy chat_rooms_select on public.chat_rooms
  for select to authenticated
  using (
    exists (
      select 1 from dormitory_members dm
      where dm.user_id = auth.uid()
        and dm.room_id is not null
        and dm.room_id = chat_rooms.room_id
        and dm.status = 'approved'
    )
    or exists (
      select 1 from dormitories d
      where d.id = chat_rooms.dormitory_id
        and d.created_by = auth.uid()
    )
  );

-- allow insert if member of same room (roommate/main tenant) or dorm admin
drop policy if exists chat_rooms_insert on public.chat_rooms;
create policy chat_rooms_insert on public.chat_rooms
  for insert to authenticated
  with check (
    exists (
      select 1 from dormitory_members dm
      where dm.user_id = auth.uid()
        and dm.status = 'approved'
        and dm.room_id is not null
        and dm.room_id = chat_rooms.room_id
    )
    or exists (
      select 1 from repairs r
      where r.id = chat_rooms.repair_id
        and r.user_id = auth.uid()
    )
    or exists (
      select 1 from dormitories d
      where d.id = chat_rooms.dormitory_id
        and d.created_by = auth.uid()
    )
  );
