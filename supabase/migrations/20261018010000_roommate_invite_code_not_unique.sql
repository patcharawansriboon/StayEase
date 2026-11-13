-- ─────────────────────────────────────────────────────────────────────────────
-- รหัสเชิญ (invite_code) 1 รหัส ต้องใช้ได้หลายคน (หลาย Roommate ในห้องเดียวกัน)
-- เดิมคอลัมน์นี้เป็น UNIQUE → คนที่ 2 ที่ใช้รหัสเดียวกันจะชน
-- constraint "roommate_invites_invite_code_key" (SQLSTATE 23505)
--
-- การควบคุมจำนวนคนต่อห้องย้ายไปใช้ rooms.max_tenants + การนับสมาชิก
-- approved แทน (ดู RoomMembersService.canJoinRoom)
-- ─────────────────────────────────────────────────────────────────────────────

-- ลบ unique constraint ออก (ชื่อ default ที่ Postgres ตั้งให้ตอนประกาศ unique)
alter table roommate_invites
  drop constraint if exists roommate_invites_invite_code_key;

-- เผื่อบางสภาพแวดล้อม unique ถูกสร้างเป็น index แยก
drop index if exists roommate_invites_invite_code_key;
