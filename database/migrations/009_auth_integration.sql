-- Auth Integration Migration
-- Ensures proper RLS policies and indexes for Supabase Auth integration

-- Allow authenticated users to insert their own profile
-- This enables users to create their profile after signing in with Apple
CREATE POLICY "Users can create own profile" 
  ON users 
  FOR INSERT 
  WITH CHECK (auth.uid() = id);

-- Ensure apple_sub is properly indexed for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_apple_sub 
  ON users(apple_sub) 
  WHERE apple_sub IS NOT NULL;

-- Add indexed lookup for phone numbers
CREATE INDEX IF NOT EXISTS idx_users_phone 
  ON users(phone_e164) 
  WHERE phone_e164 IS NOT NULL;

-- Add session management improvements
-- Add created_at if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'sessions' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE sessions ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END $$;

-- Ensure sessions can be queried efficiently by user
CREATE INDEX IF NOT EXISTS idx_sessions_user_id 
  ON sessions(user_id, expires_at DESC);

-- Add policy for users to read their own sessions
CREATE POLICY "Users can view own sessions" 
  ON sessions 
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Add policy for system to manage sessions
CREATE POLICY "System can manage sessions" 
  ON sessions 
  FOR ALL 
  USING (true) 
  WITH CHECK (true);

-- Update RLS policy for devices
-- Allow users to register their own devices
CREATE POLICY "Users can register own devices" 
  ON devices 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

-- Allow users to read their own devices
CREATE POLICY "Users can view own devices" 
  ON devices 
  FOR SELECT 
  USING (auth.uid() = user_id);

-- Add index for device lookup
CREATE INDEX IF NOT EXISTS idx_devices_user_id 
  ON devices(user_id, last_attested_at DESC);

-- Add function to automatically set updated_at on users table
-- This ensures updated_at is always current when user profile changes
CREATE OR REPLACE FUNCTION update_updated_at_users()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ensure trigger exists for users updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_users();

-- Add helper function to check if user has completed onboarding
CREATE OR REPLACE FUNCTION user_has_profile(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users 
    WHERE id = user_uuid 
    AND handle IS NOT NULL 
    AND display_name IS NOT NULL
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment explaining auth flow
COMMENT ON POLICY "Users can create own profile" ON users IS 
  'Allows authenticated users to create their profile after Sign in with Apple. The user_id from Supabase Auth must match the profile id.';

COMMENT ON POLICY "Users can insert their own posts" ON posts IS 
  'Requires user to have completed profile creation before posting.';

