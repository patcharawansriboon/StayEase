-- ─────────────────────────────────────────────────
-- Run this in Supabase SQL Editor
-- URL: https://app.supabase.com/project/rkzieigonelmksbjpiep/editor/sql
-- Click "Run" to execute
-- ─────────────────────────────────────────────────

-- 1. เพิ่มคอลัมน์ dorm_code (ที่หายไป)
ALTER TABLE dormitories ADD COLUMN IF NOT EXISTS dorm_code text UNIQUE;

-- 2. เพิ่มคอลัมน์ dorm_name (เพื่อให้ตรงกับโค้ด)
ALTER TABLE dormitories ADD COLUMN IF NOT EXISTS dorm_name text;

-- 3. คัดลอกข้อมูลจาก name → dorm_name
UPDATE dormitories SET dorm_name = name WHERE dorm_name IS NULL;
