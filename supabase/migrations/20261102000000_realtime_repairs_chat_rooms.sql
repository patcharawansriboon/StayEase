-- เปิด Realtime ให้ตาราง repairs และ chat_rooms
-- (จุดแดงแจ้งซ่อม, การ์ดงานซ่อมบน dashboard และหน้า home ผู้เช่า ต้องใช้)
-- idempotent: ข้ามถ้าตารางอยู่ใน publication แล้ว
do $$
declare
  t text;
begin
  foreach t in array array['repairs', 'chat_rooms'] loop
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = t
    ) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;
