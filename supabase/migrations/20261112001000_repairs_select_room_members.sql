-- Allow approved room members (tenant + roommates in same room) to see all repairs of that room
-- so report/chat lists are consistent regardless of who filed the repair.

alter table public.repairs enable row level security;

drop policy if exists repairs_select_room_members on public.repairs;
create policy repairs_select_room_members on public.repairs
  for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.dormitory_members dm
      join public.dormitory_members dm2
        on dm2.room_id = dm.room_id
       and dm2.status = 'approved'
      where dm.user_id = auth.uid()
        and dm.status = 'approved'
        and dm.room_id is not null
        and dm2.user_id = repairs.user_id
    )
    or exists (
      select 1 from public.dormitory_members dm
      where dm.user_id = auth.uid()
        and dm.status = 'approved'
        and dm.room_id is not null
        and dm.room_id = repairs.room_id
    )
  );

-- keep/allow users to insert their own repairs if policy missing (idempotent)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'repairs' and policyname = 'repairs_insert_own'
  ) then
    create policy repairs_insert_own on public.repairs
      for insert to authenticated
      with check (user_id = auth.uid());
  end if;
end $$;

-- keep/allow users/admins to update if app relies on it; do not override existing broad policies
-- (status changes from admin are handled in app logic; existing policies may already exist)
