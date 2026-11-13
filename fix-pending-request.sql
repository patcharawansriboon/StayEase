-- ═══════════════════════════════════════════════════════════════
--  สถานะจริงของปัญหา "คำขอเข้าหอพัก (ผู้เช่าหลัก)" ไม่โผล่ในหน้า request.dart
--  โปรเจกต์: rkzieigonelmksbjpiep   ตรวจเมื่อ 27 ก.ย. 2026
--  สถานะ: ตรวจครบแล้ว + แก้ policy ที่จำเป็นแล้ว (รายการที่ทำไประบุไว้ด้านล่าง)
-- ═══════════════════════════════════════════════════════════════
--
-- ✔ ตรวจแล้ว: FK dormitory_members.dormitory_id → dormitories.id มีอยู่
--   (embed dormitories(dorm_code) ใช้ได้)
-- ✔ ตรวจแล้ว: คอลัมน์จริงของ dormitory_members =
--   id, user_id, dormitory_id, status, created_at   (ไม่มี role / room_id)
--   → โค้ด Dart แก้ไม่ให้ส่ง role/room_id แล้ว ทั้ง auth_service.dart
--     และ tenant_auth_service.dart
-- ✔ ตรวจแล้ว: policy "Tenant requests membership" (user_id = auth.uid())
--   ให้ผู้เช่า insert คำขอได้จริง
-- ✔ ตรวจแล้ว: query ฝั่ง admin ใน request.dart ทำงานได้จริง
--   (ทดสอบด้วย session จำลอง: dormitories → dormitory_members(pending) → คืนแถว)
-- ✔ แก้แล้ว: เพิ่ม policy "Admins read tenants" บนตาราง tenants
--   (เดิม admin อ่านข้อมูลผู้เช่าไม่ได้ → ชื่อในกล่องขึ้น Unknown)
-- ✔ แก้แล้ว: dormitory_request.dart กรองเฉพาะหอของ admin ที่ล็อกอินอยู่
--   (เดิม select dormitory_members ทั้งตารางโดยไม่กรอง → ไม่มีอะไรขึ้น)
-- ✔ แก้แล้ว: ดึงชื่อ-เบอร์ผู้เช่าเป็นชุดเดียว (inFilter) แทนวน loop ทีละคน
-- ✔ ทดสอบครบทุกขั้นแล้วด้วย session จำลอง 27 ก.ย. 2026 — ทุก query คืนข้อมูลถูกต้อง
-- ✔ ล้างแล้ว: user/แถวทดสอบที่สร้างระหว่างตรวจสอบ
--
-- ⚠ สาเหตุที่กล่องไม่โผล่ตอนทดสอบจริง: ตอนกดสมัครผู้เช่า
--   signUpTenant จะ signIn เป็นผู้เช่า (จำเป็นกับ RLS) → session ของ admin หายไป
--   พอกลับมาเปิดหน้า request.dart จึง query ด้วย uid ของผู้เช่า
--   → ไม่มีหอพักที่ created_by = uid นั้น → ไม่มีกล่อง
--   แก้แล้วใน request.dart: ตรวจ admins ก่อน ถ้าไม่ใช่ผู้ดูแลจะขึ้นข้อความชัดเจน
--   → วิธีทดสอบ: ใช้ 2 เครื่อง (หรือ 1 เครื่องแต่ล้าง session) ฝั่ง admin ต้องล็อกอินค้างไว้
-- ═══════════════════════════════════════════════════════════════


-- ── ส่วนที่ 1: ตรวจสถานะปัจจุบัน (read-only) ─────────────────────────────

-- 1.1 คำขอที่รออยู่
select dm.id, dm.user_id, dm.status, dm.created_at, d.dorm_code,
       t.full_name
from public.dormitory_members dm
left join public.dormitories d on d.id = dm.dormitory_id
left join public.tenants t on t.id = dm.user_id
order by dm.created_at desc nulls last;

-- 1.2 หอพัก + เจ้าของ
select id, dorm_code, dorm_name, created_by, created_at
from public.dormitories
order by created_at desc nulls last;

-- 1.3 ผู้ดูแลหอพัก
select id, full_name, phone from public.admins;

-- 1.4 policy ของ dormitory_members / tenants
select tablename, policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename in ('dormitory_members', 'tenants')
order by tablename, cmd;


-- ── ส่วนที่ 2: บัญชีทดสอบ (ล้างให้แล้ว 27 ก.ย. 2026) ─────────────────────
--  เคยมี ~46 บัญชีทดสอบใน auth.users ที่ไม่มีแถวใน admins / tenants /
--  dormitory_members เลย (user ค้างจากรอบที่ signUp สำเร็จแต่ขั้นถัดไปล้ม)
--  ลบออกหมดแล้ว เหลือเฉพาะบัญชีที่มีข้อมูลจริงผูกอยู่ (ดูข้อ 1.5)
--  ถ้าจะตรวจซ้ำ:
select u.id, u.email, u.created_at
from auth.users u
where u.email like '%@stayease.app'
order by u.created_at desc;

--  คำสั่งที่ใช้ลบ (เก็บไว้อ้างอิง อย่ารันซ้ำถ้าไม่ต้องการ):
-- delete from auth.users u
-- where u.email like '%@stayease.app'
--   and not exists (select 1 from public.admins a where a.id = u.id)
--   and not exists (select 1 from public.tenants t where t.id = u.id)
--   and not exists (select 1 from public.dormitory_members m where m.user_id = u.id);


-- ── ส่วนที่ 3: ถ้าอยากปิดช่องโหว่ RLS ─────────────────────────────────
--  ตอนนี้ tenants/admins เปิดให้ anon key (public) เขียนได้ทั้ง insert/update
--  ควรจำกัดให้เขียนเฉพาะแถวของตัวเอง:
-- drop policy if exists "Tenants insert" on public.tenants;
-- create policy "Tenants insert" on public.tenants for insert
--   with check (auth.uid() = id);
-- drop policy if exists "Tenants update own" on public.tenants;
-- create policy "Tenants update own" on public.tenants for update
--   using (auth.uid() = id) with check (auth.uid() = id);
--
-- drop policy if exists "Admins insert" on public.admins;
-- create policy "Admins insert" on public.admins for insert
--   with check (auth.uid() = id);
-- drop policy if exists "Admins update own" on public.admins;
-- create policy "Admins update own" on public.admins for update
--   using (auth.uid() = id) with check (auth.uid() = id);
