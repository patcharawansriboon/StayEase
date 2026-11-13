-- Add avatar_url column to tenants table if missing
ALTER TABLE public.tenants 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN public.tenants.avatar_url IS 'Profile picture URL for tenants';
