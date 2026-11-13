-- ============================================================
-- ระบบแชทงานแจ้งซ่อม: chat_rooms + chat_messages
-- โมเดล: 1 ห้องแชท = 1 งานซ่อม (ผูก repairs.id)
-- ใครเห็น: ผู้เช่าหลัก + Roommate ที่อยู่ "ห้องเดียวกัน" (room_id) + แอดมินของหอ
-- ============================================================

-- ── 0) เพิ่มคอลัมน์ที่ระบบแชทต้องใช้ให้ตาราง repairs ───────────
--     (ตารางเดิมมีแค่ room_number/reporter_name/category/description/status)
alter table public.repairs add column if not exists user_id uuid;
alter table public.repairs add column if not exists room_id uuid;
alter table public.repairs add column if not exists image_url text;

-- ── 1) ตารางห้องแชท (1 แถวต่อ 1 งานซ่อม) ─────────────────────
create table if not exists public.chat_rooms (
  id            uuid primary key default gen_random_uuid(),
  repair_id     uuid not null references public.repairs(id) on delete cascade,
  room_id       uuid references public.rooms(id) on delete set null,
  dormitory_id  uuid references public.dormitories(id) on delete set null,
  created_at    timestamptz not null default now(),
  unique (repair_id)
);

-- ── 2) ตารางข้อความ ──────────────────────────────────────────
-- sender_role: 'tenant' | 'roommate' | 'admin' | 'bot'
-- meta: ใช้เก็บข้อมูลการ์ดสรุปของบอท (ประเภท/รายละเอียด/รูป ฯลฯ) เป็น jsonb
create table if not exists public.chat_messages (
  id            uuid primary key default gen_random_uuid(),
  chat_room_id  uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id     uuid,
  sender_role   text not null default 'tenant',
  text          text,
  image_url     text,
  meta          jsonb,
  created_at    timestamptz not null default now()
);

create index if not exists idx_chat_rooms_repair  on public.chat_rooms (repair_id);
create index if not exists idx_chat_rooms_room     on public.chat_rooms (room_id);
create index if not exists idx_chat_messages_room  on public.chat_messages (chat_room_id, created_at);

-- ── 3) เปิด RLS ──────────────────────────────────────────────
alter table public.chat_rooms    enable row level security;
alter table public.chat_messages enable row level security;

-- ── 4) ฟังก์ชันช่วย: ผู้ใช้ปัจจุบันเข้าถึงห้องแชทนี้ได้ไหม ─────
-- เข้าถึงได้เมื่อ:
--   (ก) เป็นสมาชิก dormitory_members ที่ room_id ตรงกับห้องของงานซ่อม (ผู้เช่าหลัก/Roommate), หรือ
--   (ข) เป็นแอดมินที่สร้างหอ (dormitories.created_by = auth.uid()) ของห้องแชทนั้น
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
        -- (ก) อยู่ห้องเดียวกับงานซ่อม
        exists (
          select 1 from dormitory_members dm
          where dm.user_id = auth.uid()
            and dm.room_id = cr.room_id
            and dm.status = 'approved'
        )
        -- (ข) แอดมินของหอนั้น
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

-- ── 5) Policies: chat_rooms ──────────────────────────────────
-- ดูห้องแชทได้ถ้าเป็นสมาชิกห้อง (เช็ค room_id) หรือเป็นแอดมินของหอ
drop policy if exists chat_rooms_select on public.chat_rooms;
create policy chat_rooms_select on public.chat_rooms
  for select to authenticated
  using (
    exists (
      select 1 from dormitory_members dm
      where dm.user_id = auth.uid()
        and dm.room_id = chat_rooms.room_id
        and dm.status = 'approved'
    )
    or exists (
      select 1 from dormitories d
      where d.id = chat_rooms.dormitory_id
        and d.created_by = auth.uid()
    )
  );

-- สร้างห้องแชทได้ถ้าเป็นผู้เช่าเจ้าของงานซ่อม หรือแอดมินของหอ
drop policy if exists chat_rooms_insert on public.chat_rooms;
create policy chat_rooms_insert on public.chat_rooms
  for insert to authenticated
  with check (
    exists (
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

-- ── 6) Policies: chat_messages ───────────────────────────────
-- อ่านข้อความได้ถ้าเข้าถึงห้องแชทนั้นได้
drop policy if exists chat_messages_select on public.chat_messages;
create policy chat_messages_select on public.chat_messages
  for select to authenticated
  using (public.can_access_chat_room(chat_room_id));

-- ส่งข้อความได้ถ้าเข้าถึงห้องแชทนั้นได้ และ sender_id เป็นตัวเอง
-- (ยกเว้น bot: ให้ส่งได้โดย sender_id เป็น null และ sender_role = 'bot')
drop policy if exists chat_messages_insert on public.chat_messages;
create policy chat_messages_insert on public.chat_messages
  for insert to authenticated
  with check (
    public.can_access_chat_room(chat_room_id)
    and (
      (sender_role = 'bot' and sender_id is null)
      or sender_id = auth.uid()
    )
  );

-- ── 7) เปิด Realtime ให้ chat_messages ───────────────────────
-- เพิ่มตารางเข้า publication supabase_realtime เพื่อให้ client subscribe ได้
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'chat_messages'
  ) then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;
