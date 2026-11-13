-- ─────────────────────────────────────────────────────────────────────────────
-- Upgrade (Roommate → ผู้เช่าหลัก) ต้องเก็บสถานะ Roommate เดิมไว้
-- เพื่อให้ "ปฏิเสธ" คืนกลับเป็น Roommate ห้องเดิมได้ และ "อนุมัติ"
-- ย้ายออกจากห้องเดิมไปเป็นผู้เช่าหลักห้องใหม่
--
-- แนวทาง: ใช้แถว dormitory_members แถวเดียวของ Roommate เดิม (เพราะ
-- unique(user_id, dormitory_id) ทำให้มี 2 แถวในหอเดียวกันไม่ได้) โดย
-- snapshot ค่าเดิมไว้ก่อนเปลี่ยนเป็นคำขอ upgrade
-- ─────────────────────────────────────────────────────────────────────────────

alter table dormitory_members
  add column if not exists prev_room_id uuid references rooms(id) on delete set null;

alter table dormitory_members
  add column if not exists prev_dormitory_id uuid references dormitories(id) on delete set null;

alter table dormitory_members
  add column if not exists prev_member_type text;
