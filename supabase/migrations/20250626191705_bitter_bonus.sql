/*
  # Add Editor Data History Table

  1. New Tables
    - `editor_data_history` - Stores historical snapshots of editor_data
      - `id` (uuid, primary key)
      - `piece_id` (uuid, foreign key to pieces)
      - `editor_data` (jsonb) - The historical editor data snapshot
      - `version_name` (text) - Optional user-defined version name
      - `created_at` (timestamptz) - When the snapshot was created
      - `created_by` (uuid) - User who created the snapshot

  2. Security
    - Enable RLS on editor_data_history table
    - Add policies for viewing and creating history entries
    - Ensure only organizers and contributors can access history for their pieces
*/

-- Create editor_data_history table
CREATE TABLE editor_data_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  piece_id uuid REFERENCES pieces(id) ON DELETE CASCADE NOT NULL,
  editor_data jsonb NOT NULL,
  version_name text,
  created_at timestamptz DEFAULT now(),
  created_by uuid REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE editor_data_history ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX editor_data_history_piece_id_idx ON editor_data_history(piece_id);
CREATE INDEX editor_data_history_created_at_idx ON editor_data_history(created_at);

-- RLS Policies

-- 1. Organizers can view history for their pieces
CREATE POLICY "Organizers can view history for their pieces"
  ON editor_data_history
  FOR SELECT
  TO authenticated
  USING (
    piece_id IN (
      SELECT p.id
      FROM pieces p
      JOIN organizers o ON p.organizer_id = o.id
      WHERE o.user_id = auth.uid()
    )
  );

-- 2. Contributors can view history for pieces they contribute to
CREATE POLICY "Contributors can view history for pieces they contribute to"
  ON editor_data_history
  FOR SELECT
  TO authenticated
  USING (
    piece_id IN (
      SELECT pa.piece_id
      FROM piece_artists pa
      JOIN artists a ON pa.artist_id = a.id
      WHERE a.user_id = auth.uid()
    )
  );

-- 3. Organizers can create history entries for their pieces
CREATE POLICY "Organizers can create history entries for their pieces"
  ON editor_data_history
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

-- 4. Contributors can create history entries for pieces they contribute to
CREATE POLICY "Contributors can create history entries for pieces they contribute to"
  ON editor_data_history
  FOR INSERT
  TO authenticated
  WITH CHECK (
    piece_id IN (
      SELECT pa.piece_id
      FROM piece_artists pa
      JOIN artists a ON pa.artist_id = a.id
      WHERE a.user_id = auth.uid()
    )
  );