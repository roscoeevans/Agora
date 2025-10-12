-- Migration: Add display_handle column to users table
-- Date: 2025-10-12
-- Description: Support custom capitalization for user handles (like Twitter)

-- Add display_handle column
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_handle TEXT;

-- For existing users, copy their handle as the display_handle
UPDATE users SET display_handle = handle WHERE display_handle IS NULL;

-- Make display_handle NOT NULL after backfilling
ALTER TABLE users ALTER COLUMN display_handle SET NOT NULL;

-- Add comment for clarity
COMMENT ON COLUMN users.display_handle IS 'User''s preferred capitalization of their handle (e.g., "RockyEvans" vs "rockyevans")';
COMMENT ON COLUMN users.handle IS 'Canonical lowercase handle for uniqueness check (e.g., "rockyevans")';

