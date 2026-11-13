-- แจกแจงค่าเช่ารายคนในห้อง (ผู้เช่าหลัก + Roommate)
-- SECURITY DEFINER → อ่าน tenant_rentals ข้าม RLS ได้
-- แต่จำกัดขอบเขต: คืนเฉพาะสมาชิกที่อยู่ห้องเดียวกับผู้เรียกใช้
create or replace function public.get_room_rent_breakdown(p_user_id uuid)
returns table (
  user_id uuid,
  full_name text,
  phone text,
  member_type text,
  room_number text,
  rent numeric,
  deposit numeric
)
language sql
security definer
set search_path = public
stable
as $$
  with me as (
    select dm.room_id
    from dormitory_members dm
    where dm.user_id = auth.uid()
      and dm.room_id is not null
      and dm.status = 'approved'
    order by dm.created_at desc
    limit 1
  )
  select
    dm.user_id,
    coalesce(
      t.full_name,
      ri.full_name,
      nullif(au.raw_user_meta_data ->> 'full_name', ''),
      'ไม่ทราบชื่อ'
    ) as full_name,
    coalesce(t.phone, ri.phone, '') as phone,
    dm.member_type,
    r.room_number,
    -- rent/deposit เก็บเป็น text ในตาราง → แปลงเป็น numeric (ตัดจุลภาค/ช่องว่างออกก่อน)
    case when coalesce(replace(replace(tr.rent, ',', ''), ' ', ''), '') ~ '^[0-9.]+$'
         then replace(replace(tr.rent, ',', ''), ' ', '')::numeric
         else 0 end as rent,
    case when coalesce(replace(replace(tr.deposit, ',', ''), ' ', ''), '') ~ '^[0-9.]+$'
         then replace(replace(tr.deposit, ',', ''), ' ', '')::numeric
         else 0 end as deposit
  from dormitory_members dm
  join me            on me.room_id = dm.room_id
  join rooms r       on r.id = dm.room_id
  left join tenants t on t.id = dm.user_id
  left join roommate_invites ri on ri.id = dm.user_id
  left join auth.users au on au.id = dm.user_id
  left join lateral (
    select x.rent, x.deposit
    from tenant_rentals x
    where x.member_id = dm.id or x.member_id = dm.user_id
    order by (x.member_id = dm.id) desc, x.updated_at desc nulls last
    limit 1
  ) tr on true
  where dm.status = 'approved'
    and dm.member_type in ('tenant', 'roommate')
    -- ป้องกันการแอบดูข้อมูลห้องของคนอื่น: ต้องเป็นผู้เรียกจริงเท่านั้น
    and (p_user_id is null or p_user_id = auth.uid())
  order by (dm.member_type = 'tenant') desc,
           coalesce(t.full_name, ri.full_name, '') asc;
$$;

revoke all on function public.get_room_rent_breakdown(uuid) from public;
grant execute on function public.get_room_rent_breakdown(uuid) to anon, authenticated, service_role;
