-- Add meter readings to bills table
ALTER TABLE bills ADD COLUMN IF NOT EXISTS electric_meter_prev TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS electric_meter_curr TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS water_meter_prev TEXT;
ALTER TABLE bills ADD COLUMN IF NOT EXISTS water_meter_curr TEXT;
