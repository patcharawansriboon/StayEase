-- ให้ anon (ก่อนสมัคร) ตรวจสอบเลขห้องและเอา room_id ได้
-- โดยไม่ต้องเปิดสิทธิ์อ่านตาราง rooms ทั้งหมด
create or replace function public.resolve_room_id(p_dormitory_id uuid, p_room_number text)
returns table (room_id uuid)
language sql
security definer
set search_path = public
stable
as $$
  select r.id as room_id
  from public.rooms r
  where r.dormitory_id = p_dormitory_id
    and r.room_number = p_room_number
  limit 1
$$;

revoke all on function public.resolve_room_id(uuid, text) from public;
grant execute on function public.resolve_room_id(uuid, text) to anon, authenticated, service_role;
