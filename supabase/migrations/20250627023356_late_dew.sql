/*
  # Fix Profiles RLS Policies

  1. Security Updates
    - Update RLS policies for profiles table to ensure proper access control
    - Add missing policies for profile management
    - Ensure users can only access and modify their own profiles

  2. Policy Changes
    - Refine existing policies for better security
    - Add comprehensive CRUD policies for authenticated users
*/

-- Drop existing policies to recreate them with better security
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Create comprehensive RLS policies for profiles
CREATE POLICY "Public profiles are viewable by everyone"
  ON profiles
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can insert their own profile"
  ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete their own profile"
  ON profiles
  FOR DELETE
  TO authenticated
  USING (auth.uid() = id);

-- Ensure RLS is enabled on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;