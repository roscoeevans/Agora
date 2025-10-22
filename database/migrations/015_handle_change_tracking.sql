-- Add handle change tracking
-- Allows users to change handle once every 30 days (excluding initial creation)

ALTER TABLE public.users
ADD COLUMN handle_last_changed_at TIMESTAMPTZ;

-- Set initial value to NULL for existing users (allows immediate change)
-- New users will get NULL on creation, then timestamp on first manual change

COMMENT ON COLUMN public.users.handle_last_changed_at IS 'Timestamp of last manual handle change (NULL = never changed since creation, allows immediate change)';

