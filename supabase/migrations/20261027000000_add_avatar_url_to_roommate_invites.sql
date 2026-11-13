-- Add avatar_url column to roommate_invites table
ALTER TABLE public.roommate_invites 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Optional: Add comment
COMMENT ON COLUMN public.roommate_invites.avatar_url IS 'Profile picture URL for roommate invites';
