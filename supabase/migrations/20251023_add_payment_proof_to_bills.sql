-- Add payment proof URL to bills table
ALTER TABLE bills ADD COLUMN IF NOT EXISTS payment_proof_url TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS room_number TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS tenant_name TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS qr_image_url TEXT;

-- Allow admin to update bills in their dormitory
DROP POLICY IF EXISTS "Admin updates bills" ON bills;
CREATE POLICY "Admin updates bills"
  ON bills FOR UPDATE
  USING (
    dormitory_id IN (
      SELECT id FROM dormitories WHERE created_by = auth.uid()
    )
  )
  WITH CHECK (
    dormitory_id IN (
      SELECT id FROM dormitories WHERE created_by = auth.uid()
    )
  );

-- Also allow admin via admins table
DROP POLICY IF EXISTS "Admin updates bills via admins" ON bills;
CREATE POLICY "Admin updates bills via admins"
  ON bills FOR UPDATE
  USING (EXISTS (SELECT 1 FROM admins WHERE admins.id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM admins WHERE admins.id = auth.uid()));
