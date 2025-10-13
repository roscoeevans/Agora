-- Migration 010: Update Handle Constraints
-- Update handle validation to support Instagram/Threads-style handles
-- Changes:
--   - Increase max length from 15 to 30 characters
--   - Allow periods (.) in addition to letters, numbers, underscores
--   - Maintain case-insensitive uniqueness
--   - Keep minimum 3 characters
--   - Prevent consecutive periods

-- Drop the old constraint
ALTER TABLE users 
DROP CONSTRAINT IF EXISTS users_handle_check;

-- Add new constraint with updated rules
-- Pattern: 3-30 characters, letters (a-z, A-Z), numbers (0-9), periods (.), underscores (_)
-- No consecutive periods
ALTER TABLE users
ADD CONSTRAINT users_handle_check 
CHECK (
  handle ~ '^[a-z0-9._]{3,30}$' 
  AND handle !~ '\.\.'  -- No consecutive periods
  AND handle ~ '[a-z]'  -- Must contain at least one letter
);

-- Add comment explaining the constraint
COMMENT ON CONSTRAINT users_handle_check ON users IS 
'Instagram/Threads-style handle validation: 3-30 chars, letters/numbers/periods/underscores, no consecutive periods, must have at least one letter';

-- Note: The handle column remains lowercase-only for consistency in storage
-- The display_handle column stores the user's preferred capitalization
COMMENT ON COLUMN users.handle IS 
'Canonical lowercase handle for lookups and mentions (3-30 chars). Follows Instagram/Threads rules.';

COMMENT ON COLUMN users.display_handle IS 
'User''s preferred capitalization of their handle (e.g., Rocky.Evans vs rocky.evans)';

