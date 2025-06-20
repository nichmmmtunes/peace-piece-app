/*
  # Fix piece_artists RLS policies

  1. Security
    - Add RLS policies for piece_artists table to allow organizers to manage collaborators
    - Allow organizers to insert, update, delete, and select piece_artists for their pieces
    - Allow public to view piece_artists (for displaying collaborators)

  2. Changes
    - Add INSERT policy for organizers to add artists to their pieces
    - Add UPDATE policy for organizers to modify artist roles in their pieces  
    - Add DELETE policy for organizers to remove artists from their pieces
    - Add SELECT policy for public viewing of piece collaborators
*/

-- Add RLS policies for piece_artists table
CREATE POLICY "Organizers can add artists to their pieces"
  ON piece_artists
  FOR INSERT
  TO authenticated
  WITH CHECK (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );

CREATE POLICY "Organizers can update artists in their pieces"
  ON piece_artists
  FOR UPDATE
  TO authenticated
  USING (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  )
  WITH CHECK (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );

CREATE POLICY "Organizers can remove artists from their pieces"
  ON piece_artists
  FOR DELETE
  TO authenticated
  USING (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );

CREATE POLICY "Anyone can view piece artists"
  ON piece_artists
  FOR SELECT
  TO public
  USING (true);