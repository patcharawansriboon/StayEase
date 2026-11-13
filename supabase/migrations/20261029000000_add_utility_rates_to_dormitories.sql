-- Add electricity and water rates to dormitories
ALTER TABLE public.dormitories
  ADD COLUMN IF NOT EXISTS electricity_rate numeric(10,2) DEFAULT 0 NOT NULL,
  ADD COLUMN IF NOT EXISTS water_rate numeric(10,2) DEFAULT 0 NOT NULL;

COMMENT ON COLUMN public.dormitories.electricity_rate IS 'อัตราค่าไฟฟ้า (บาท/หน่วย)';
COMMENT ON COLUMN public.dormitories.water_rate IS 'อัตราค่าน้ำ (บาท/หน่วย)';
