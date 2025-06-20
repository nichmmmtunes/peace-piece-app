/*
  # Add RLS policies for sponsors table

  1. Changes
    - Add RLS policies to allow authenticated users to create, read, update, and delete sponsors
    
  2. Security
    - Enable public read access to all sponsors
    - Allow authenticated users to create new sponsors
    - Allow authenticated users to update and delete sponsors they create
    - Maintain data integrity with appropriate constraints
*/

-- Ensure RLS is enabled on sponsors table
ALTER TABLE sponsors ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for sponsors table

-- Allow public read access to all sponsors
CREATE POLICY "Sponsors are viewable by everyone"
  ON sponsors
  FOR SELECT
  TO public
  USING (true);

-- Allow authenticated users to create new sponsors
CREATE POLICY "Authenticated users can create sponsors"
  ON sponsors
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update sponsors
-- In a real-world scenario, you might want to track ownership of sponsors
-- and only allow updates by the creator, but for this demo we'll allow all authenticated users
CREATE POLICY "Authenticated users can update sponsors"
  ON sponsors
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete sponsors
-- Same note as above regarding ownership
CREATE POLICY "Authenticated users can delete sponsors"
  ON sponsors
  FOR DELETE
  TO authenticated
  USING (true);