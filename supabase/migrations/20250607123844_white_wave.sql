/*
  # Add user-organizer relationship

  1. Changes
    - Add `user_id` column to `organizers` table
    - Add foreign key constraint to link organizers to users
    - Add RLS policies for organizer management
    - Update existing organizers to have proper user relationships (if any exist)

  2. Security
    - Enable RLS on organizers table
    - Add policies for organizer CRUD operations
    - Ensure only organizer owners can edit their organizer profiles
*/

-- Add user_id column to organizers table
ALTER TABLE organizers 
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add index for better performance
CREATE INDEX IF NOT EXISTS organizers_user_id_idx ON organizers(user_id);

-- Enable RLS on organizers table (if not already enabled)
ALTER TABLE organizers ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for organizers
CREATE POLICY "Users can view all organizers"
  ON organizers
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Users can create organizers for themselves"
  ON organizers
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own organizers"
  ON organizers
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own organizers"
  ON organizers
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);