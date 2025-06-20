/*
  # Add Profile Creation Policy

  1. Changes
    - Add RLS policy to allow authenticated users to create their own profile
    
  2. Security
    - Policy ensures users can only create profiles with their own ID
    - Maintains data integrity by linking profiles to auth users
*/

CREATE POLICY "Allow authenticated users to create their own profile"
ON public.profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);