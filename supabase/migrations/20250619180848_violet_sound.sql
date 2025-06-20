/*
  # Add RLS policy for piece creation

  1. Changes
    - Add RLS policy to allow authenticated users to create new pieces
    - Policy checks that the organizer_id belongs to an organizer owned by the user
    
  2. Security
    - Ensures users can only create pieces with organizers they own
    - Maintains existing RLS policies
*/

-- Add RLS policy for piece creation
CREATE POLICY "Users can create pieces with their own organizers"
  ON pieces
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Check if the organizer_id belongs to an organizer owned by the current user
    organizer_id IN (
      SELECT id 
      FROM organizers 
      WHERE user_id = auth.uid()
    )
  );