/*
  # Fix profiles table RLS policies

  1. Changes
    - Update RLS policies for the profiles table to allow new users to create their profile
    - Keep existing policies for viewing and updating profiles

  2. Security
    - Maintain row-level security
    - Allow authenticated users to insert their own profile
    - Keep existing policies for viewing and updating
*/

-- First, drop the existing insert policy if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'profiles' 
    AND policyname = 'Users can insert their own profile'
  ) THEN
    DROP POLICY "Users can insert their own profile" ON profiles;
  END IF;
END $$;

-- Create new insert policy that allows profile creation during signup
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);