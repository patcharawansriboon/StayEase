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

drop policy if exists "Users can view own profile" on profiles;
create policy "Users can view own profile"
  on profiles for select
  using (auth.uid() = id);

drop policy if exists "Users can update own profile" on profiles;
create policy "Users can update own profile"
  on profiles for update
  using (auth.uid() = id);

drop policy if exists "Service role can manage all profiles" on profiles;
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

drop policy if exists "Anyone can read dormitories" on dormitories;
create policy "Anyone can read dormitories"
  on dormitories for select
  using (true);

drop policy if exists "Admin creates dormitories" on dormitories;
create policy "Admin creates dormitories"
  on dormitories for insert
  with check (auth.jwt() ->> 'role' = 'admin');

drop policy if exists "Admin updates dormitories" on dormitories;
create policy "Admin updates dormitories"
  on dormitories for update
  using (auth.jwt() ->> 'role' = 'admin');
