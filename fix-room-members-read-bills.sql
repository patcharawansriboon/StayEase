-- ให้สมาชิกห้องเดียวกัน (ผู้เช่าหลัก + Roommate) "อ่าน" บิลของห้องตัวเองได้
--
-- ปัญหาเดิม: ตาราง bills ให้ผู้เช่าอ่านได้เฉพาะแถวที่ tenant_id = ตัวเอง
--           Roommate จึงมองไม่เห็นบิลที่แอดมินออกให้ผู้เช่าหลัก
--
-- วิธีแก้: เพิ่มนโยบาย SELECT (ทำงานร่วมกับนโยบายเดิมแบบ OR ไม่ไปแทนที่ของเดิม)
--         ใช้ฟังก์ชัน SECURITY DEFINER ตรวจสมาชิกห้อง เพื่อไม่ให้ติด RLS ของ
--         dormitory_members / rooms ซ้อนกัน
--
-- ขอบเขตสิทธิ์: อ่านอย่างเดียว (ไม่เปิด insert/update/delete)
--              อ่านได้เฉพาะบิลที่ห้อง "และหอพัก" ตรงกับห้องที่ตัวเองเป็นสมาชิก
--              (approved) เท่านั้น จึงไม่เห็นบิลห้องอื่นหรือหอพักอื่นที่เลขห้องซ้ำกัน

create or replace function public.is_member_of_bill_room(
  p_room text,
  p_dormitory_id uuid
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from dormitory_members dm
    join rooms r on r.id = dm.room_id
    where dm.user_id = auth.uid()
      and dm.status = 'approved'
      and dm.member_type in ('tenant', 'roommate')
      and r.room_number = p_room
      and r.dormitory_id = p_dormitory_id
  );
$$;

revoke all on function public.is_member_of_bill_room(text, uuid) from public;
grant execute on function public.is_member_of_bill_room(text, uuid)
  to authenticated, service_role;

drop policy if exists "Room members read room bills" on public.bills;
create policy "Room members read room bills"
  on public.bills
  for select
  to authenticated
  using (public.is_member_of_bill_room(room, dormitory_id));
