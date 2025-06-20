/*
  # Fix Profile RLS Policies

  1. Changes
    - Remove duplicate INSERT policies
    - Ensure proper RLS policy for profile creation
    - Clean up policy names for clarity

  2. Security
    - Maintain RLS enabled
    - Single clear INSERT policy for authenticated users
    - Maintain existing SELECT and UPDATE policies
*/

-- Drop duplicate policies
DROP POLICY IF EXISTS "Allow authenticated users to create their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;

-- Create single, clear INSERT policy
CREATE POLICY "Users can create their own profile"
ON profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);