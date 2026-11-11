-- =============================================
-- StayEase Supabase Schema & RLS Policies
-- =============================================

-- 1. PROFILES TABLE
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  role text not null default 'tenant',
  avatar_url text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "Users can view own profile"
  on profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id);

create policy "Service role can manage all profiles"
  on profiles for all
  using (true)
  with check (true);

-- 2. DORMITORIES TABLE
create table if not exists dormitories (
  id uuid primary key default gen_random_uuid(),
  dorm_code text not null unique,
  dorm_name text not null,
  address text,
  phone text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

alter table dormitories enable row level security;

create policy "Anyone can read dormitories"
  on dormitories for select
  using (true);

create policy "Admin creates dormitories"
  on dormitories for insert
  with check (auth.jwt() ->> 'role' = 'admin');

create policy "Admin updates dormitories"
  on dormitories for update
  using (auth.jwt() ->> 'role' = 'admin');

-- 3. DORMITORY MEMBERS TABLE
create table if not exists dormitory_members (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  dormitory_id uuid not null references dormitories(id) on delete cascade,
  room_id uuid,
  role text not null default 'tenant',
  -- 'tenant' = ผู้เช่าหลัก, 'roommate' = ผู้เข้าร่วมห้องผ่านรหัสเชิญ
  member_type text not null default 'tenant',
  -- ห้องที่สมาชิกอาศัย (ใช้แสดงรายชื่อสมาชิกในห้องที่ room_members.dart)
  room_id uuid references rooms(id) on delete set null,
  status text not null default 'pending',
  created_at timestamptz default now(),
  unique(user_id, dormitory_id)
);

alter table dormitory_members add column if not exists member_type text not null default 'tenant';
alter table dormitory_members add column if not exists room_id uuid references rooms(id) on delete set null;
alter table invitation_codes add column if not exists room_id uuid references rooms(id) on delete set null;

create index if not exists idx_dormitory_members_room on dormitory_members(room_id);
create index if not exists idx_dormitory_members_user on dormitory_members(user_id);

alter table dormitory_members enable row level security;

create policy "Tenant reads own member record"
  on dormitory_members for select
  using (auth.uid() = user_id);

create policy "Tenant updates own member record (limited)"
  on dormitory_members for update
  using (auth.uid() = user_id)
  with check (
    role = 'tenant' and
    status in ('pending', 'rejected')
  );

create policy "Admin sees all member requests"
  on dormitory_members for select
  using (auth.jwt() ->> 'role' = 'admin');

create policy "Admin updates member status"
  on dormitory_members for update
  using (auth.jwt() ->> 'role' = 'admin')
  with check (true);

-- 4. BILLS TABLE
create table if not exists bills (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references auth.users(id) on delete cascade,
  dormitory_id uuid references dormitories(id) on delete set null,
  room_id uuid,
  month text,
  rent numeric default 0,
  electricity numeric default 0,
  water numeric default 0,
  penalty numeric default 0,
  total numeric default 0,
  due_date text,
  status text not null default 'pending',
  created_at timestamptz default now()
);

alter table bills enable row level security;

create policy "Tenant reads own bills"
  on bills for select
  using (auth.uid() = tenant_id);

create policy "Tenant updates own bills"
  on bills for update
  using (auth.uid() = tenant_id);

create policy "Admin reads bills in own dormitory"
  on bills for select
  using (
    auth.jwt() ->> 'role' = 'admin' and
    dormitory_id in (
      select dormitory_id from dormitory_members
      where user_id = auth.uid() and status = 'approved'
    )
  );

create policy "Admin creates bills"
  on bills for insert
  with check (auth.jwt() ->> 'role' = 'admin');

-- 5. ANNOUNCEMENTS TABLE
create table if not exists announcements (
  id uuid primary key default gen_random_uuid(),
  dormitory_id uuid not null references dormitories(id) on delete cascade,
  title text not null,
  content text,
  image_url text,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

alter table announcements enable row level security;

create policy "Tenant reads announcements from own dormitory"
  on announcements for select
  using (
    auth.uid() in (
      select user_id from dormitory_members
      where dormitory_id = announcements.dormitory_id
      and status = 'approved'
    )
  );

create policy "Admin creates announcements"
  on announcements for insert
  with check (auth.jwt() ->> 'role' = 'admin');

create policy "Admin updates announcements"
  on announcements for update
  using (auth.jwt() ->> 'role' = 'admin');

create policy "Admin deletes announcements"
  on announcements for delete
  using (auth.jwt() ->> 'role' = 'admin');

-- 6. REPAIRS TABLE
create table if not exists repairs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  dormitory_id uuid references dormitories(id) on delete set null,
  room_number text,
  title text,
  description text,
  status text default 'pending',
  created_at timestamptz default now()
);

alter table repairs enable row level security;

create policy "Tenant reads own repairs"
  on repairs for select
  using (auth.uid() = user_id);

create policy "Tenant creates own repairs"
  on repairs for insert
  with check (auth.uid() = user_id);

create policy "Tenant updates own repairs"
  on repairs for update
  using (auth.uid() = user_id);

create policy "Admin reads all repairs"
  on repairs for select
  using (auth.jwt() ->> 'role' = 'admin');

-- 7. ADMIN TABLE (existing)
create table if not exists admins (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  created_at timestamptz default now()
);

alter table admins enable row level security;

create policy "Admin reads own data"
  on admins for select
  using (auth.uid() = id);

-- Set RLS for auth.users (read own)
alter table auth.users enable row level security;

create policy "Users can view own auth data"
  on auth.users for select
  using (auth.uid() = id);

-- 8. ROOMMATE INVITES TABLE
create table if not exists roommate_invites (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  invite_code text not null unique,
  is_verified boolean default false,
  status text not null default 'pending',
  created_at timestamptz default now()
);

alter table roommate_invites enable row level security;

create policy "User reads own roommate invite"
  on roommate_invites for select
  using (auth.uid() = id);

create policy "User updates own roommate invite"
  on roommate_invites for update
  using (auth.uid() = id);

create policy "Users insert own roommate invite"
  on roommate_invites for insert
  with check (auth.uid() = id);

-- แอดมินต้องอ่านชื่อ/เบอร์ Roommate เพื่อแสดงในรายการคำขอ (request.dart)
create policy "Admins read roommate invites"
  on roommate_invites for select
  using (exists (select 1 from admins a where a.id = auth.uid()));

-- แอดมินต้องอนุมัติ/ปฏิเสธสถานะ Roommate ได้ (dormitory_request.dart)
-- ถ้า policy นี้ขาด การอัปเดตจะถูก RLS บล็อกแบบเงียบ ๆ (คืน 204 แต่ไม่อัปเดต)
create policy "Admins update roommate invites"
  on roommate_invites for update
  using (exists (select 1 from admins a where a.id = auth.uid()))
  with check (exists (select 1 from admins a where a.id = auth.uid()));

-- 9. TENANT RENTALS TABLE (ข้อมูลการเช่าของผู้เช่า)
create table if not exists tenant_rentals (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references dormitory_members(id) on delete cascade,
  building text,
  room_number text,
  floor text,
  check_in_date date,
  check_out_date date,
  rent numeric default 0,
  deposit numeric default 0,
  emergency_contact_name text,
  emergency_contact_phone text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table tenant_rentals enable row level security;

create policy "Tenant reads own rental info"
  on tenant_rentals for select
  using (
    auth.uid() in (
      select user_id from dormitory_members
      where id = tenant_rentals.member_id
      and status = 'approved'
    )
  );

create policy "Admin reads rentals in own dormitory"
  on tenant_rentals for select
  using (
    auth.jwt() ->> 'role' = 'admin' and
    exists (
      select 1 from dormitory_members dm
      join dormitories d on dm.dormitory_id = d.id
      where dm.id = tenant_rentals.member_id
      and d.created_by = auth.uid()
    )
  );

create policy "Admin updates rental info"
  on tenant_rentals for update
  using (auth.jwt() ->> 'role' = 'admin')
  with check (true);

create policy "Admin inserts rental info"
  on tenant_rentals for insert
  with check (auth.jwt() ->> 'role' = 'admin');

-- ── Helper function: get_dormitory_tenants ────────────────────────────────
create or replace function get_dormitory_tenants(admin_uid uuid)
returns table (
  member_id uuid,
  name text,
  phone text,
  room_number text,
  role text,
  status text,
  building text,
  floor text,
  check_in_date date,
  check_out_date date,
  rent numeric,
  deposit numeric
)
language sql
as $$
  select
    dm.id                               as member_id,
    p.full_name                         as name,
    p.phone                             as phone,
    tr.room_number                      as room_number,
    dm.role                             as role,
    dm.status                            as status,
    tr.building                          as building,
    tr.floor                             as floor,
    tr.check_in_date                     as check_in_date,
    tr.check_out_date                    as check_out_date,
    tr.rent                              as rent,
    tr.deposit                           as deposit
  from dormitory_members dm
  left join profiles p      on p.id = dm.user_id
  left join tenant_rentals tr on tr.member_id = dm.id
  left join dormitories d   on d.id = dm.dormitory_id
  where d.created_by = admin_uid;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- ROOMMATE INVITATION CODES
-- รหัสเชิญที่ผู้เช่าหลักสร้างในหน้า invitation_code.dart
-- ใช้ผูก Roommate เข้าหอพัก/ห้องเดียวกับผู้ออกรหัส
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists invitation_codes (
  code text primary key,
  created_by uuid not null references auth.users(id) on delete cascade,
  dormitory_id uuid not null references dormitories(id) on delete cascade,
  -- ห้องที่รหัสนี้ผูกไว้ → Roommate ที่ใช้รหัสจะได้ห้องเดียวกับผู้ออกรหัส
  room_id uuid references rooms(id) on delete set null,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

alter table invitation_codes enable row level security;

-- เจ้าของรหัสจัดการรหัสของตัวเองได้ (ลบรหัสเก่า + สร้างใหม่)
create policy "Owner manages own invitation codes"
  on invitation_codes for all
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

-- Roommate ที่กำลังสมัครต้องตรวจสอบรหัสได้ (ยังไม่อนุมัติ จึงยังไม่มีสิทธิ์อ่านแบบเจ้าของ)
-- จำกัดเฉพาะรหัสที่ยังไม่หมดอายุ
create policy "Anyone can read valid invitation code"
  on invitation_codes for select
  using (expires_at is null or expires_at > now());
