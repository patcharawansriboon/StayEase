-- ═══════════════════════════════════════════════════════════════
-- Fix RLS Policies: Replace JWT role check with admins table check
-- ═══════════════════════════════════════════════════════════════
-- Run in: https://app.supabase.com/project/rkzieigonelmksbjpiep/editor/sql
-- ═══════════════════════════════════════════════════════════════

-- ── 1. Fix dorm_code column (missing) ──
ALTER TABLE dormitories ADD COLUMN IF NOT EXISTS dorm_code text UNIQUE;
ALTER TABLE dormitories ADD COLUMN IF NOT EXISTS dorm_name text;
UPDATE dormitories SET dorm_name = name WHERE dorm_name IS NULL;

-- ── 2. Fix RLS policies to check admins table instead of JWT role ──

-- dormitories
DROP POLICY IF EXISTS "Admin creates dormitories" ON dormitories;
CREATE POLICY "Admin creates dormitories"
  ON dormitories FOR INSERT
  WITH CHECK (exists (select 1 from admins where admins.id = auth.uid()));

DROP POLICY IF EXISTS "Admin updates dormitories" ON dormitories;
CREATE POLICY "Admin updates dormitories"
  ON dormitories FOR UPDATE
  USING (exists (select 1 from admins where admins.id = auth.uid()));

-- bills
DROP POLICY IF EXISTS "Admin reads bills in own dormitory" ON bills;
CREATE POLICY "Admin reads bills in own dormitory"
  ON bills FOR SELECT
  USING (
    -- แอดมินเป็นผู้สร้างหอพัก (dormitories.created_by) ไม่ใช่สมาชิกใน dormitory_members
    -- ถ้าเช็คจาก dormitory_members จะได้แถวว่าง → แอดมินอ่านบิลไม่ได้เลย
    dormitory_id in (
      select id from dormitories where created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admin creates bills" ON bills;
CREATE POLICY "Admin creates bills"
  ON bills FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    or exists (select 1 from admins where admins.id = auth.uid())
  );

-- announcements
DROP POLICY IF EXISTS "Admin creates announcements" ON announcements;
CREATE POLICY "Admin creates announcements"
  ON announcements FOR INSERT
  WITH CHECK (exists (select 1 from admins where admins.id = auth.uid()));

DROP POLICY IF EXISTS "Admin updates announcements" ON announcements;
CREATE POLICY "Admin updates announcements"
  ON announcements FOR UPDATE
  USING (exists (select 1 from admins where admins.id = auth.uid()));

DROP POLICY IF EXISTS "Admin deletes announcements" ON announcements;
CREATE POLICY "Admin deletes announcements"
  ON announcements FOR DELETE
  USING (exists (select 1 from admins where admins.id = auth.uid()));

-- repairs
DROP POLICY IF EXISTS "Admin reads all repairs" ON repairs;
CREATE POLICY "Admin reads all repairs"
  ON repairs FOR SELECT
  USING (exists (select 1 from admins where admins.id = auth.uid()));

-- dormitory_members
DROP POLICY IF EXISTS "Admin sees all member requests" ON dormitory_members;
CREATE POLICY "Admin sees all member requests"
  ON dormitory_members FOR SELECT
  USING (exists (select 1 from admins where admins.id = auth.uid()));

DROP POLICY IF EXISTS "Admin updates member status" ON dormitory_members;
CREATE POLICY "Admin updates member status"
  ON dormitory_members FOR UPDATE
  USING (exists (select 1 from admins where admins.id = auth.uid()))
  WITH CHECK (true);