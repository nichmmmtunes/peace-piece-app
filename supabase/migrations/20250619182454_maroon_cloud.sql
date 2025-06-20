/*
  # Link Artists to Users and Add Artist Profile Fields

  1. Changes
    - Add `user_id` column to `artists` table to link artists to auth.users
    - Add `avatar_url` column for artist profile images
    - Add `artistic_mediums` column as JSONB array to store mediums
    - Add RLS policies for artist management
    - Create index for better query performance

  2. Security
    - Enable RLS on artists table
    - Add policies for viewing, creating, updating, and deleting artist profiles
    - Ensure users can only manage their own artist profiles
*/

-- Add user_id column to artists table
ALTER TABLE artists 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add avatar_url column to artists table
ALTER TABLE artists 
ADD COLUMN IF NOT EXISTS avatar_url text;

-- Add artistic_mediums column to artists table
ALTER TABLE artists 
ADD COLUMN IF NOT EXISTS artistic_mediums jsonb DEFAULT '[]'::jsonb;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS artists_user_id_idx ON artists(user_id);

-- Ensure RLS is enabled on artists table
ALTER TABLE artists ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for artists table

-- Allow public read access to all artists
CREATE POLICY "Artists are viewable by everyone"
  ON artists
  FOR SELECT
  TO public
  USING (true);

-- Allow authenticated users to create their own artist profile
CREATE POLICY "Users can create their own artist profile"
  ON artists
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to update their own artist profile
CREATE POLICY "Users can update their own artist profile"
  ON artists
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Allow authenticated users to delete their own artist profile
CREATE POLICY "Users can delete their own artist profile"
  ON artists
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);