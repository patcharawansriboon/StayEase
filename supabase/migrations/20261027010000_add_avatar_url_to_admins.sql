-- Add avatar_url column to admins table
ALTER TABLE public.admins 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN public.admins.avatar_url IS 'Profile picture URL for admins';
