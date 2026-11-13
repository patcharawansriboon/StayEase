// Supabase Edge Function: reset-password
// ลืมรหัสผ่านแบบ self-service (ตัวเลือก C)
// ตรวจ เบอร์ + ชื่อ-นามสกุล ให้ตรงกับ DB → ตั้งรหัสผ่านใหม่
//
// Deploy:
//   supabase functions deploy reset-password --no-verify-jwt
//
// ต้องตั้ง secret (มีให้โดย default ใน Supabase):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// เบอร์ → email ปลอมที่ระบบใช้ (ต้องตรงกับ AuthService._authEmail)
const authEmail = (phone: string) => `${phone}@stayease.app`;

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { phone, fullName, newPassword } = await req.json();

    // ── validate input ──
    if (!phone || !fullName || !newPassword) {
      return json({ success: false, error: "ข้อมูลไม่ครบ" }, 400);
    }
    if (typeof newPassword !== "string" || newPassword.length < 6) {
      return json(
        { success: false, error: "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร" },
        400,
      );
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const phoneStr = String(phone).trim();
    const nameStr = String(fullName).trim();

    // ── 1) ตรวจว่า เบอร์ + ชื่อ ตรงกับแถวใน DB ไหม (tenants/roommate/admins) ──
    let matched = false;
    for (const table of ["tenants", "roommate_invites", "admins"]) {
      const { data, error } = await admin
        .from(table)
        .select("id, full_name, phone")
        .eq("phone", phoneStr)
        .maybeSingle();
      if (error) continue;
      if (data && String(data.full_name).trim() === nameStr) {
        matched = true;
        break;
      }
    }

    if (!matched) {
      return json(
        { success: false, error: "เบอร์โทรหรือชื่อ-นามสกุลไม่ถูกต้อง" },
        403,
      );
    }

    // ── 2) หา auth user จาก email ปลอม ──
    const email = authEmail(phoneStr);
    // listUsers แล้วหา email ตรง (admin API ไม่มี getByEmail ตรงๆ)
    const { data: list, error: listErr } = await admin.auth.admin.listUsers({
      page: 1,
      perPage: 1000,
    });
    if (listErr) {
      return json({ success: false, error: "ระบบขัดข้อง" }, 500);
    }
    const user = list.users.find((u) => u.email === email);
    if (!user) {
      return json({ success: false, error: "ไม่พบบัญชีผู้ใช้" }, 404);
    }

    // ── 3) ตั้งรหัสผ่านใหม่ ──
    const { error: updErr } = await admin.auth.admin.updateUserById(user.id, {
      password: String(newPassword),
    });
    if (updErr) {
      return json({ success: false, error: "ตั้งรหัสผ่านใหม่ไม่สำเร็จ" }, 500);
    }

    return json({ success: true });
  } catch (_e) {
    return json({ success: false, error: "ข้อมูลไม่ถูกต้อง" }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
