-- เพิ่มคอลัมน์ email ให้ตาราง tenants / roommate_invites / admins
-- รองรับการสมัคร/ล็อกอินด้วยอีเมลจริง (แทนการแปลงเบอร์เป็นอีเมลปลอม)
alter table tenants          add column if not exists email text;
alter table roommate_invites add column if not exists email text;
alter table admins           add column if not exists email text;
