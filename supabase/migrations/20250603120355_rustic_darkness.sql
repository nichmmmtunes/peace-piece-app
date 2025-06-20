/*
  # Fix Profiles Table RLS Policies

  1. Changes
    - Modify RLS policies for the profiles table to properly handle profile creation during signup
    - Ensure authenticated users can create their own profile
    - Maintain existing policies for viewing and updating profiles

  2. Security
    - Enable RLS on profiles table
    - Add policy for profile creation during signup
    - Preserve existing policies for profile updates and viewing
*/

-- First ensure RLS is enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them with correct permissions
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Recreate policies with correct permissions
CREATE POLICY "Public profiles are viewable by everyone" 
ON profiles FOR SELECT 
TO public 
USING (true);

CREATE POLICY "Users can insert their own profile" 
ON profiles FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" 
ON profiles FOR UPDATE 
TO authenticated 
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);