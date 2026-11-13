-- ═══════════════════════════════════════════════════════════════
-- อนุญาตให้ลบไฟล์เอกสารแนบของตัวเองได้ (Supabase Storage)
-- Run in: https://app.supabase.com/project/rkzieigonelmksbjpiep/editor/sql
--
-- ทำไมต้องมี
-- ───────────────────────────────────────────────────────────────
-- ปุ่ม "ลบเอกสารแนบ" ในหน้าแก้ไขข้อมูลการเช่า (ผู้เช่า) และ
-- หน้าแก้ไขข้อมูลผู้เช่า (แอดมิน) ลบไฟล์จริงออกจาก Storage
-- แต่ bucket 'dormitory-images' เดิมมี policy แค่ SELECT / INSERT / UPDATE
-- → ไม่มี policy DELETE → ลบไฟล์ไม่ได้ (ได้ 403)
--
-- policy นี้จำกัดขอบเขต:
--   • ลบได้เฉพาะไฟล์ในโฟลเดอร์ documents/
--   • ชื่อไฟล์ต้องขึ้นต้นด้วย uid ของผู้เรียก (ไฟล์ที่ผู้ใช้อัปโหลดเอง)
--   • หรือผู้เรียกเป็นแอดมิน (ตาราง admins) → ลบเอกสารของผู้เช่าได้
-- ═══════════════════════════════════════════════════════════════

drop policy if exists "Authenticated delete own documents" on storage.objects;

create policy "Authenticated delete own documents"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'dormitory-images'
    and split_part(name, '/', 1) = 'documents'
    and (
      split_part(name, '/', 2) like auth.uid()::text || '%'
      or exists (select 1 from public.admins where admins.id = auth.uid())
    )
  );
