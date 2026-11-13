-- ═══════════════════════════════════════════════════════════════
-- แก้ policy บิลของแอดมิน (อ่าน + สร้าง + อัปเดต)
-- Run in: https://app.supabase.com/project/rkzieigonelmksbjpiep/editor/sql
--
-- ปัญหาที่แก้
-- ───────────────────────────────────────────────────────────────
-- policy เดิมเช็คว่าบิลอยู่ในหอของแอดมินด้วย
--     dormitory_id in (select dormitory_id from dormitory_members
--                      where user_id = auth.uid() and status = 'approved')
-- แต่ "แอดมิน" เป็นผู้ *สร้าง* หอพัก (dormitories.created_by)
-- ไม่ได้เป็นสมาชิกใน dormitory_members → subquery ได้แถวว่าง
-- → แอดมินอ่าน/สร้าง/อัปเดตบิลไม่ได้เลย
--   ผลที่เห็น: หน้า "บิล" ของแอดมินไม่มีข้อมูลจริง
--              และปุ่มอนุมัติ/ปฏิเสธกดไม่ได้
--
-- นอกจากนี้ policy "สร้างบิล" เดิมใช้ auth.jwt() ->> 'role' = 'admin'
-- ซึ่ง JWT ของแอปไม่มี claim นี้ → แอดมินบันทึกบิลไม่ได้
-- → เปลี่ยนมาเช็ค created_by = auth.uid() หรืออยู่ในตาราง admins
-- ═══════════════════════════════════════════════════════════════

-- ── อ่านบิลของหอที่ตัวเองสร้าง ─────────────────────────────
drop policy if exists "Admin reads bills in own dormitory" on bills;

create policy "Admin reads bills in own dormitory"
  on bills for select
  using (
    dormitory_id in (
      select id from dormitories where created_by = auth.uid()
    )
  );

-- ── สร้างบิลใหม่ ────────────────────────────────────────────
drop policy if exists "Admin creates bills" on bills;

create policy "Admin creates bills"
  on bills for insert
  with check (
    created_by = auth.uid()
    or exists (select 1 from admins where admins.id = auth.uid())
  );

-- ── อัปเดตสถานะบิล (อนุมัติ/ปฏิเสธ) ────────────────────────
drop policy if exists "Admin updates bills in own dormitory" on bills;

create policy "Admin updates bills in own dormitory"
  on bills for update
  using (
    dormitory_id in (
      select id from dormitories where created_by = auth.uid()
    )
  )
  with check (
    dormitory_id in (
      select id from dormitories where created_by = auth.uid()
    )
  );
